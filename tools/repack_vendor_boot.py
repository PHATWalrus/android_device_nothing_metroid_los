#!/usr/bin/env python3

import argparse
import hashlib
import shutil
import struct
import subprocess
import tempfile
from pathlib import Path


METROID_VENDOR_BOOT_PARTITION_SIZE = 100663296


def run(command: list[str]) -> None:
    print("+", " ".join(command))
    subprocess.run(command, check=True)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as input_file:
        for chunk in iter(lambda: input_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_vendor_boot_header(image: Path) -> tuple[int, int, int]:
    header = image.read_bytes()[:2128]
    if len(header) < 2128 or header[:8] != b"VNDRBOOT":
        raise ValueError(f"{image} is not a vendor_boot image")

    header_version, page_size = struct.unpack_from("<II", header, 8)
    ramdisk_size = struct.unpack_from("<I", header, 24)[0]

    if header_version != 4:
        raise ValueError(f"expected vendor_boot header v4, found v{header_version}")
    if page_size != 4096:
        raise ValueError(f"expected a 4096-byte page size, found {page_size}")
    if ramdisk_size == 0:
        raise ValueError("vendor_boot does not contain a vendor ramdisk")

    return header_version, page_size, ramdisk_size


def default_tool_paths(top: Path) -> tuple[Path, Path]:
    return (
        top / "out/host/linux-x86/bin/avbtool",
        top / "system/tools/mkbootimg/unpack_bootimg.py",
    )


def parse_arguments() -> argparse.Namespace:
    top = Path(__file__).resolve().parents[4]
    avbtool, unpack_bootimg = default_tool_paths(top)
    parser = argparse.ArgumentParser(description="Normalize the Metroid vendor_boot image")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--avbtool", type=Path, default=avbtool)
    parser.add_argument("--unpack-bootimg", type=Path, default=unpack_bootimg)
    return parser.parse_args()


def main() -> None:
    args = parse_arguments()
    input_image = args.input.resolve()
    output_image = args.output.resolve()

    for tool in (args.avbtool, args.unpack_bootimg):
        if not tool.is_file():
            raise FileNotFoundError(tool)
    if not input_image.is_file() or input_image.is_symlink():
        raise ValueError(f"input must be a regular file: {input_image}")
    if output_image.is_symlink():
        raise ValueError(f"output must not be a symlink: {output_image}")
    if input_image == output_image:
        raise ValueError("input and output must be different files")

    with tempfile.TemporaryDirectory(prefix="metroid-vendor-boot-") as temporary_directory:
        temporary = Path(temporary_directory)
        normalized = temporary / "vendor_boot.img"
        shutil.copyfile(input_image, normalized)

        footer_info = subprocess.run(
            [str(args.avbtool), "info_image", "--image", str(normalized)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if footer_info.returncode == 0:
            run([str(args.avbtool), "erase_footer", "--image", str(normalized)])

        _, _, ramdisk_size = read_vendor_boot_header(normalized)
        unpacked = temporary / "unpacked"
        run(
            [
                "python3",
                str(args.unpack_bootimg),
                "--boot_img",
                str(normalized),
                "--out",
                str(unpacked),
            ]
        )

        vendor_ramdisk = unpacked / "vendor_ramdisk00"
        dtb = unpacked / "dtb"
        bootconfig = unpacked / "bootconfig"
        if not all(path.is_file() for path in (vendor_ramdisk, dtb, bootconfig)):
            raise ValueError("vendor_boot is missing its platform ramdisk, DTB, or bootconfig")
        if vendor_ramdisk.stat().st_size != ramdisk_size:
            raise ValueError("vendor ramdisk size does not match the header")
        if normalized.stat().st_size >= METROID_VENDOR_BOOT_PARTITION_SIZE:
            raise ValueError("vendor_boot cannot fit its partition with an AVB footer")

        avb_preflight = temporary / "vendor_boot.avb.img"
        shutil.copyfile(normalized, avb_preflight)
        run(
            [
                str(args.avbtool),
                "add_hash_footer",
                "--image",
                str(avb_preflight),
                "--partition_name",
                "vendor_boot",
                "--partition_size",
                str(METROID_VENDOR_BOOT_PARTITION_SIZE),
                "--prop",
                "com.android.build.vendor_boot.fingerprint:metroid-preflight",
            ]
        )
        run([str(args.avbtool), "info_image", "--image", str(avb_preflight)])

        output_image.parent.mkdir(parents=True, exist_ok=True)
        staged_output = temporary / "vendor_boot.output.img"
        shutil.copyfile(normalized, staged_output)
        shutil.move(staged_output, output_image)

    print(
        f"wrote {output_image} "
        f"({output_image.stat().st_size} bytes, sha256={sha256(output_image)})"
    )


if __name__ == "__main__":
    main()
