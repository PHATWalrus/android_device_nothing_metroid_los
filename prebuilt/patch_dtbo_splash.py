#!/usr/bin/env python3
import os
import subprocess
import sys
import re

LINEAGE_ROOT = "/home/logix/dev/metroid/lineage"
DTBO_PATH = os.path.join(LINEAGE_ROOT, "device/nothing/metroid-kernel/dtbo.img")
EXTRACT_DIR = "/tmp/dtbo_extracted"
MKDTBOIMG = os.path.join(LINEAGE_ROOT, "system/libufdt/utils/src/mkdtboimg.py")
DTC = os.path.join(LINEAGE_ROOT, "prebuilts/kernel-build-tools/linux-x86/bin/dtc")

def run_cmd(args):
    print("+ " + " ".join(args))
    res = subprocess.run(args, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Error: {res.stderr}")
        sys.exit(res.returncode)
    return res.stdout

def main():
    if not os.path.exists(EXTRACT_DIR):
        os.makedirs(EXTRACT_DIR)

    # 1. Dump dtbo.img to extract files
    print("=== [1/5] Extracting DTBO ===")
    run_cmd(["python3", MKDTBOIMG, "dump", DTBO_PATH, "-b", os.path.join(EXTRACT_DIR, "dtbo")])

    # 2. Decompile, patch, and recompile each DTBO file
    print("=== [2/5] Decompiling and Patching ===")
    dtbo_files = sorted(
        [f for f in os.listdir(EXTRACT_DIR) if f.startswith("dtbo.") and not f.endswith(".dts") and not f.endswith(".patched")],
        key=lambda x: int(x.split(".")[1])
    )

    modified_count = 0

    for f in dtbo_files:
        idx = f.split(".")[1]
        dtb_path = os.path.join(EXTRACT_DIR, f)
        dts_path = os.path.join(EXTRACT_DIR, f"{f}.dts")
        patched_dtb_path = os.path.join(EXTRACT_DIR, f"{f}.patched")

        # Decompile to DTS
        subprocess.run([DTC, "-I", "dtb", "-O", "dts", dtb_path, "-o", dts_path], capture_output=True)

        if not os.path.exists(dts_path):
            # If decompile failed, just copy original
            subprocess.run(["cp", dtb_path, patched_dtb_path])
            continue

        with open(dts_path, "r") as file_in:
            dts_content = file_in.read()

        # Look for continuous splash properties and splash_region node block
        matched = False
        new_content = dts_content
        # 1. Match and remove/comment out splash_region node block
        splash_node_pattern = r"(\s*splash_region\s*\{[^}]*label\s*=\s*\"cont_splash_region\";[^}]*\};)"
        if re.search(splash_node_pattern, new_content):
            new_content = re.sub(splash_node_pattern, r"\n\t\t\t/* \1 (patched out) */", new_content)
            matched = True


        if matched:
            print(f"  Patching dtbo.{idx} (continuous splash property found)")
            modified_count += 1
            with open(dts_path, "w") as file_out:
                file_out.write(new_content)
            # Recompile DTS to patched DTB
            run_cmd([DTC, "-I", "dts", "-O", "dtb", dts_path, "-o", patched_dtb_path])
        else:
            # Just copy original to patched name
            subprocess.run(["cp", dtb_path, patched_dtb_path])

    print(f"=== [3/5] Modified {modified_count} out of {len(dtbo_files)} files ===")

    # 3. Create new patched dtbo.img
    print("=== [4/5] Creating patched dtbo.img ===")
    patched_image_path = os.path.join(LINEAGE_ROOT, "device/nothing/metroid-kernel/dtbo_patched.img")
    create_args = ["python3", MKDTBOIMG, "create", patched_image_path, "--page_size=4096", "--version=0"]
    for f in dtbo_files:
        create_args.append(os.path.join(EXTRACT_DIR, f"{f}.patched"))
    
    run_cmd(create_args)
    print("Patched DTBO created at device/nothing/metroid-kernel/dtbo_patched.img")

    # Sign the newly created dtbo image with avbtool
    print("=== [4.5/5] Signing dtbo_patched.img with avbtool ===")
    avbtool = os.path.join(LINEAGE_ROOT, "out/host/linux-x86/bin/avbtool")
    avb_key = os.path.join(LINEAGE_ROOT, "external/avb/test/data/testkey_rsa2048.pem")
    avb_cmd = [
        avbtool, "add_hash_footer",
        "--image", patched_image_path,
        "--partition_name", "dtbo",
        "--partition_size", "50331648"
    ]
    run_cmd(avb_cmd)

    # 4. Overwrite original prebuilt (keep a backup just in case)
    print("=== [5/5] Overwriting original dtbo.img ===")
    backup_path = os.path.join(LINEAGE_ROOT, "device/nothing/metroid-kernel/dtbo.img.bak")
    if not os.path.exists(backup_path):
        run_cmd(["cp", DTBO_PATH, backup_path])
    run_cmd(["cp", patched_image_path, DTBO_PATH])
    print("Successfully updated device/nothing/metroid-kernel/dtbo.img")

if __name__ == "__main__":
    main()

