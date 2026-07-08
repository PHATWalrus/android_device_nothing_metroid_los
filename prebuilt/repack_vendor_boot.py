#!/usr/bin/env python3
import os
import subprocess
import sys

LINEAGE_ROOT = "/home/logix/dev/metroid/lineage"
VENDOR_BOOT_PATH = os.path.join(LINEAGE_ROOT, "device/nothing/metroid-kernel/vendor_boot.img")
UNPACK_DIR = "/tmp/vendor_boot_tree_unpacked"
EXTRACT_DIR = "/tmp/vendor_ramdisk_extracted"
MKBOOTIMG = os.path.join(LINEAGE_ROOT, "out/host/linux-x86/bin/mkbootimg")
UNPACK_BOOTIMG = os.path.join(LINEAGE_ROOT, "out/host/linux-x86/bin/unpack_bootimg")

def run_cmd(args, cwd=None):
    print("+ " + " ".join(args))
    res = subprocess.run(args, capture_output=True, text=True, cwd=cwd)
    if res.returncode != 0:
        print(f"Error: {res.stderr}")
        sys.exit(res.returncode)
    return res.stdout

def main():
    # 1. Clean and create directories
    os.makedirs(UNPACK_DIR, exist_ok=True)
    subprocess.run(f"rm -rf {EXTRACT_DIR} && mkdir -p {EXTRACT_DIR}", shell=True)

    # 2. Unpack vendor_boot.img
    print("=== [1/5] Unpacking vendor_boot.img ===")
    run_cmd([UNPACK_BOOTIMG, "--boot_img", VENDOR_BOOT_PATH, "--out", UNPACK_DIR])

    # 3. Decompress and extract ramdisk
    print("=== [2/5] Extracting vendor ramdisk ===")
    ramdisk_archive = os.path.join(UNPACK_DIR, "vendor_ramdisk00")
    # Extract cpio archive
    subprocess.run(f"lz4 -d {ramdisk_archive} -c | cpio -idm --no-absolute-filenames", shell=True, cwd=EXTRACT_DIR)

    # 4. Modify modules.load
    print("=== [3/5] Modifying modules.load ===")
    modules_load_path = os.path.join(EXTRACT_DIR, "lib/modules/modules.load")
    with open(modules_load_path, "r") as f:
        modules = f.read().splitlines()

    regulators = [
        "wl28681-regulator.ko",
        "qti-fixed-regulator.ko",
        "qcom-amoled-regulator.ko"
    ]

    # Verify if already added
    if any(r in modules for r in regulators):
        print("Regulator modules already present in modules.load.")
    else:
        # Insert them before msm_drm.ko
        try:
            idx = modules.index("msm_drm.ko")
            for r in reversed(regulators):
                modules.insert(idx, r)
            print("Successfully added regulator modules before msm_drm.ko.")
        except ValueError:
            # If msm_drm.ko not found, append to end
            modules.extend(regulators)
            print("msm_drm.ko not found. Appended regulators to the end of modules.load.")

        with open(modules_load_path, "w") as f:
            f.write("\n".join(modules) + "\n")

    # 5. Repack ramdisk
    print("=== [4/5] Repacking vendor ramdisk ===")
    new_ramdisk_archive = os.path.join(UNPACK_DIR, "vendor_ramdisk00_patched")
    # Find all files, pack using cpio, and compress with lz4 in legacy/compressed format
    subprocess.run(f"find . | cpio -o -H newc | lz4 -c -l > {new_ramdisk_archive}", shell=True, cwd=EXTRACT_DIR)

    # 6. Rebuild vendor_boot.img
    print("=== [5/5] Rebuilding vendor_boot.img ===")
    new_vendor_boot = os.path.join(LINEAGE_ROOT, "device/nothing/metroid-kernel/vendor_boot_patched.img")
    
    cmd = [
        MKBOOTIMG,
        "--header_version", "4",
        "--vendor_boot", new_vendor_boot,
        "--vendor_ramdisk", new_ramdisk_archive,
        "--vendor_cmdline", "video=vfb:640x400,bpp=32,memsize=3072000 qcom_geni_serial.con_enabled=0 nosoftlockup console=ttynull qcom_geni_serial.con_enabled=0 log_buf_len=1M ignore_loglevel printk.devkmsg=on androidboot.selinux=permissive bootconfig",
        "--dtb", os.path.join(UNPACK_DIR, "dtb"),
        "--vendor_bootconfig", os.path.join(UNPACK_DIR, "bootconfig"),
        "--pagesize", "4096",
        "--base", "0x00000000",
        "--kernel_offset", "0x00008000",
        "--ramdisk_offset", "0x01000000",
        "--tags_offset", "0x00000100",
        "--dtb_offset", "0x01f00000"
    ]
    
    run_cmd(cmd)
    
    # Sign the newly created vendor_boot image with avbtool
    print("=== [6/5] Signing vendor_boot.img with avbtool ===")
    avbtool = os.path.join(LINEAGE_ROOT, "out/host/linux-x86/bin/avbtool")
    avb_key = os.path.join(LINEAGE_ROOT, "external/avb/test/data/testkey_rsa2048.pem")
    avb_cmd = [
        avbtool, "add_hash_footer",
        "--image", new_vendor_boot,
        "--partition_name", "vendor_boot",
        "--partition_size", "100663296"
    ]
    run_cmd(avb_cmd)
    
    # Overwrite the original prebuilt vendor_boot
    backup_path = VENDOR_BOOT_PATH + ".bak"
    if not os.path.exists(backup_path):
        os.rename(VENDOR_BOOT_PATH, backup_path)
    os.rename(new_vendor_boot, VENDOR_BOOT_PATH)
    print("Successfully updated prebuilt vendor_boot.img in device tree!")

if __name__ == "__main__":
    main()

