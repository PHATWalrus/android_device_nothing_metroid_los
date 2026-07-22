#!/usr/bin/env python3

import argparse
import hashlib
import shutil
import struct
import subprocess
import tempfile
from pathlib import Path


CPIO_HEADER_SIZE = 110
CPIO_MAGIC = b"070701"
CPIO_TRAILER = b"TRAILER!!!"
METROID_VENDOR_BOOT_PARTITION_SIZE = 100663296
REGULATOR_MODULES = (
    "qti-fixed-regulator.ko",
    "wl28681-regulator.ko",
    "qcom-amoled-regulator.ko",
)
MODULES_LOAD = b"lib/modules/modules.load"


def run(command: list[str]) -> None:
    print("+", " ".join(command))
    subprocess.run(command, check=True)


def run_to_file(command: list[str], output: Path) -> None:
    print("+", " ".join(command), ">", output)
    with output.open("wb") as output_file:
        subprocess.run(command, check=True, stdout=output_file)


def align4(value: int) -> int:
    return (value + 3) & ~3


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as input_file:
        for chunk in iter(lambda: input_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_vendor_boot_header(image: Path) -> tuple[int, int, int, int, int, int, str]:
    header = image.read_bytes()[:2128]
    if len(header) < 2128 or header[:8] != b"VNDRBOOT":
        raise ValueError(f"{image} is not a vendor_boot image")

    header_version, page_size, kernel_addr, ramdisk_addr, ramdisk_size = struct.unpack_from(
        "<IIIII", header, 8
    )
    tags_addr = struct.unpack_from("<I", header, 2076)[0]
    dtb_addr = struct.unpack_from("<Q", header, 2104)[0]
    command_line = header[28:2076].split(b"\0", 1)[0].decode("ascii")

    if header_version != 4:
        raise ValueError(f"expected vendor_boot header v4, found v{header_version}")
    if page_size != 4096:
        raise ValueError(f"expected a 4096-byte page size, found {page_size}")
    if not command_line:
        raise ValueError("vendor command line is empty")

    return page_size, kernel_addr, ramdisk_addr, tags_addr, dtb_addr, ramdisk_size, command_line


def parse_newc(archive: bytes) -> tuple[list[tuple[bytes, list[int], bytes]], bytes]:
    records: list[tuple[bytes, list[int], bytes]] = []
    offset = 0

    while True:
        if offset + CPIO_HEADER_SIZE > len(archive):
            raise ValueError("truncated newc header")

        header = archive[offset : offset + CPIO_HEADER_SIZE]
        offset += CPIO_HEADER_SIZE
        if header[:6] != CPIO_MAGIC:
            raise ValueError("unsupported cpio format")

        fields = [int(header[index : index + 8], 16) for index in range(6, CPIO_HEADER_SIZE, 8)]
        file_size = fields[6]
        name_size = fields[11]
        if name_size == 0 or offset + name_size > len(archive):
            raise ValueError("invalid newc name size")

        raw_name = archive[offset : offset + name_size]
        offset = align4(offset + name_size)
        if raw_name[-1:] != b"\0":
            raise ValueError("newc name is not null-terminated")
        name = raw_name[:-1]

        if offset + file_size > len(archive):
            raise ValueError("truncated newc file data")
        data = archive[offset : offset + file_size]
        offset = align4(offset + file_size)

        records.append((name, fields, data))
        if name == CPIO_TRAILER:
            return records, archive[offset:]


def build_newc(records: list[tuple[bytes, list[int], bytes]], trailer: bytes) -> bytes:
    archive = bytearray()

    for name, fields, data in records:
        record_fields = list(fields)
        record_fields[6] = len(data)
        record_fields[11] = len(name) + 1
        header = CPIO_MAGIC + b"".join(f"{field:08x}".encode() for field in record_fields)
        archive.extend(header)
        archive.extend(name)
        archive.append(0)
        archive.extend(b"\0" * (align4(len(archive)) - len(archive)))
        archive.extend(data)
        archive.extend(b"\0" * (align4(len(archive)) - len(archive)))

    archive.extend(trailer)
    return bytes(archive)


def patch_modules_load(archive: bytes) -> tuple[bytes, bool]:
    records, trailer = parse_newc(archive)
    matches = [index for index, (name, _, _) in enumerate(records) if name == MODULES_LOAD]
    if len(matches) != 1:
        raise ValueError("expected exactly one lib/modules/modules.load entry")

    index = matches[0]
    name, fields, data = records[index]
    try:
        lines = data.decode("ascii").splitlines()
    except UnicodeDecodeError as error:
        raise ValueError("modules.load is not ASCII") from error

    present = [module in lines for module in REGULATOR_MODULES]
    if any(present) and not all(present):
        raise ValueError("modules.load contains only part of the regulator set")

    changed = not all(present)
    if changed:
        insertion_index = lines.index("msm_drm.ko") if "msm_drm.ko" in lines else len(lines)
        lines[insertion_index:insertion_index] = REGULATOR_MODULES
        data = ("\n".join(lines) + "\n").encode("ascii")
        records[index] = (name, fields, data)

    return build_newc(records, trailer), changed


def assert_ramdisks_match(original: bytes, rebuilt: bytes) -> None:
    original_records, original_tail = parse_newc(original)
    rebuilt_records, rebuilt_tail = parse_newc(rebuilt)
    if original_tail != rebuilt_tail:
        raise ValueError("cpio trailer padding changed")
    if len(original_records) != len(rebuilt_records):
        raise ValueError("cpio entry count changed")

    for old, new in zip(original_records, rebuilt_records):
        old_name, old_fields, old_data = old
        new_name, new_fields, new_data = new
        if old_name != new_name:
            raise ValueError("cpio entry order changed")
        if old_name == MODULES_LOAD:
            continue
        if old_fields != new_fields or old_data != new_data:
            raise ValueError(f"unexpected change to {old_name.decode()}")

    modules_record = next(record for record in rebuilt_records if record[0] == MODULES_LOAD)
    modules = modules_record[2].decode("ascii").splitlines()
    if any(modules.count(module) != 1 for module in REGULATOR_MODULES):
        raise ValueError("regulator modules are not present exactly once")


def default_tool_paths(top: Path) -> tuple[Path, Path, Path, Path]:
    return (
        top / "out/host/linux-x86/bin/avbtool",
        top / "prebuilts/kernel-build-tools/linux-x86/bin/lz4",
        top / "system/tools/mkbootimg/mkbootimg.py",
        top / "system/tools/mkbootimg/unpack_bootimg.py",
    )


def parse_arguments() -> argparse.Namespace:
    top = Path(__file__).resolve().parents[4]
    avbtool, lz4, mkbootimg, unpack_bootimg = default_tool_paths(top)
    parser = argparse.ArgumentParser(description="Normalize and patch the Metroid vendor_boot image")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--avbtool", type=Path, default=avbtool)
    parser.add_argument("--lz4", type=Path, default=lz4)
    parser.add_argument("--mkbootimg", type=Path, default=mkbootimg)
    parser.add_argument("--unpack-bootimg", type=Path, default=unpack_bootimg)
    return parser.parse_args()


def main() -> None:
    args = parse_arguments()
    input_image = args.input.resolve()
    output_image = args.output.resolve()

    for tool in (args.avbtool, args.lz4, args.mkbootimg, args.unpack_bootimg):
        if not tool.is_file():
            raise FileNotFoundError(tool)
    if not input_image.is_file() or input_image.is_symlink():
        raise ValueError(f"input must be a regular file: {input_image}")
    if output_image.is_symlink():
        raise ValueError(f"output must not be a symlink: {output_image}")

    with tempfile.TemporaryDirectory(prefix="metroid-vendor-boot-") as temporary_directory:
        temporary = Path(temporary_directory)
        normalized = temporary / "vendor_boot.raw.img"
        shutil.copyfile(input_image, normalized)

        footer_info = subprocess.run(
            [str(args.avbtool), "info_image", "--image", str(normalized)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if footer_info.returncode == 0:
            run([str(args.avbtool), "erase_footer", "--image", str(normalized)])

        (
            page_size,
            kernel_addr,
            ramdisk_addr,
            tags_addr,
            dtb_addr,
            ramdisk_size,
            command_line,
        ) = read_vendor_boot_header(normalized)
        unpacked = temporary / "unpacked"
        run(["python3", str(args.unpack_bootimg), "--boot_img", str(normalized), "--out", str(unpacked)])

        vendor_ramdisk = unpacked / "vendor_ramdisk00"
        dtb = unpacked / "dtb"
        bootconfig = unpacked / "bootconfig"
        if not all(path.is_file() for path in (vendor_ramdisk, dtb, bootconfig)):
            raise ValueError("vendor_boot is missing a platform ramdisk, DTB, or bootconfig")
        if vendor_ramdisk.stat().st_size != ramdisk_size:
            raise ValueError("vendor ramdisk size does not match the header")

        original_cpio = temporary / "vendor_ramdisk.original.cpio"
        rebuilt_cpio = temporary / "vendor_ramdisk.rebuilt.cpio"
        rebuilt_ramdisk = temporary / "vendor_ramdisk.rebuilt.lz4"
        run_to_file([str(args.lz4), "-d", "-c", str(vendor_ramdisk)], original_cpio)
        patched_cpio, changed = patch_modules_load(original_cpio.read_bytes())
        rebuilt_cpio.write_bytes(patched_cpio)
        assert_ramdisks_match(original_cpio.read_bytes(), patched_cpio)
        run([str(args.lz4), "-l", "-z", "-12", "-f", str(rebuilt_cpio), str(rebuilt_ramdisk)])

        rebuilt_image = temporary / "vendor_boot.rebuilt.img"
        run(
            [
                "python3",
                str(args.mkbootimg),
                "--header_version",
                "4",
                "--vendor_boot",
                str(rebuilt_image),
                "--vendor_cmdline",
                command_line,
                "--pagesize",
                str(page_size),
                "--base",
                "0x0",
                "--kernel_offset",
                hex(kernel_addr),
                "--ramdisk_offset",
                hex(ramdisk_addr),
                "--tags_offset",
                hex(tags_addr),
                "--dtb_offset",
                hex(dtb_addr),
                "--dtb",
                str(dtb),
                "--vendor_bootconfig",
                str(bootconfig),
                "--ramdisk_type",
                "platform",
                "--ramdisk_name",
                "",
                "--vendor_ramdisk_fragment",
                str(rebuilt_ramdisk),
            ]
        )

        rebuilt_unpacked = temporary / "rebuilt-unpacked"
        run(["python3", str(args.unpack_bootimg), "--boot_img", str(rebuilt_image), "--out", str(rebuilt_unpacked)])
        rebuilt_header = read_vendor_boot_header(rebuilt_image)
        if rebuilt_header != (
            page_size,
            kernel_addr,
            ramdisk_addr,
            tags_addr,
            dtb_addr,
            rebuilt_ramdisk.stat().st_size,
            command_line,
        ):
            raise ValueError("rebuilt vendor_boot header differs from the expected values")
        if dtb.read_bytes() != (rebuilt_unpacked / "dtb").read_bytes():
            raise ValueError("DTB changed while rebuilding vendor_boot")
        if bootconfig.read_bytes() != (rebuilt_unpacked / "bootconfig").read_bytes():
            raise ValueError("vendor bootconfig changed while rebuilding vendor_boot")

        rebuilt_after_unpack = temporary / "vendor_ramdisk.rebuilt.after-unpack.cpio"
        run_to_file(
            [str(args.lz4), "-d", "-c", str(rebuilt_unpacked / "vendor_ramdisk00")],
            rebuilt_after_unpack,
        )
        assert_ramdisks_match(original_cpio.read_bytes(), rebuilt_after_unpack.read_bytes())

        if rebuilt_image.stat().st_size >= METROID_VENDOR_BOOT_PARTITION_SIZE:
            raise ValueError("rebuilt vendor_boot cannot fit its partition with an AVB footer")

        avb_preflight = temporary / "vendor_boot.avb-preflight.img"
        shutil.copyfile(rebuilt_image, avb_preflight)
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
        shutil.copyfile(rebuilt_image, staged_output)
        shutil.move(staged_output, output_image)

    action = "inserted regulator modules" if changed else "preserved existing regulator modules"
    print(f"{action}; wrote {output_image} ({output_image.stat().st_size} bytes, sha256={sha256(output_image)})")


if __name__ == "__main__":
    main()
