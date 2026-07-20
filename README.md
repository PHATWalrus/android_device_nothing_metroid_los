# LineageOS for Nothing Phone (3)

Device codename: `metroid`
Platform: Qualcomm `sun` / SM8735
Kernel: 6.6 GKI
Target: LineageOS 23.2 / Android 16

The original device, vendor, and kernel baseline boots. The current branch contains additional build-system and checkout cleanup and must be rebuilt and device-tested before its runtime status is updated.

## Source layout

- `device/nothing/metroid`: device configuration
- `vendor/nothing/metroid`: generated proprietary vendor tree
- `kernel/nothing/sm8735`: Nothing 6.6 kernel source
- `device/nothing/metroid-kernel`: locally staged stock `dtbo`, `init_boot`, and `vendor_boot` images

The fallback manifest is in `manifest/metroid.xml`. Current Lineage roomservice cannot represent the custom GitHub organization for normal project dependencies, so the local manifest must be installed before the first sync.

## Proprietary files

Extract from the matching Nothing OS firmware dump:

```bash
./extract-files.py /path/to/metroid
```

The list is generated from Nothing OS 4.1.A024. Do not substitute blobs from another device or firmware release without checking ELF dependencies and VINTF versions.

## Build

```bash
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR=/mnt/ccache
ccache -M 50G -F 0

source build/envsetup.sh
breakfast metroid
mka bacon
```

The stock boot-chain artifacts are currently staged outside this repository. A clean checkout must recreate `device/nothing/metroid-kernel` before building.

## Validation status

- Known baseline: boots to Android UI
- Current static tree: not built
- Recovery, VINTF, encryption, radio, Wi-Fi, Bluetooth, audio, camera, sensors, fingerprint, NFC, GNSS, charging, SELinux, and OTA: require validation on the current build
