# LineageOS 23 device tree — Nothing Phone (3) `metroid`

Unofficial early build of LineageOS 23 (Android 16) for the Nothing Phone (3) —
codename `metroid`, Qualcomm **SM8735**.

**Status: alpha / active bring-up.** A release-key full Virtual A/B OTA was
built and offline-verified on 2026-07-31. Its recovery sideload transferred
successfully, but post-install target-slot boot and hardware acceptance are not
yet recorded. Do not describe that binary as device-tested until this gate is
closed. See [`BRINGUP_GUIDE.md`](BRINGUP_GUIDE.md) for the technical history.

## Current release gate

| Gate | State |
|---|---|
| Full LineageOS `bacon` build and VINTF check | PASS |
| Payload images match target-files | PASS |
| Complete release-key AVB graph, root flags `0` | PASS |
| Matching Lineage Recovery sideload transfer | PASS |
| Post-install target-slot boot | PENDING |
| Automated hardware sweep and second reboot | PENDING |
| Public tester release | BLOCKED |

The previous clean-install baseline reached the LineageOS UI with display,
touch, ADB, Enforcing SELinux, file-based encryption, and a stable
`system_server`. That baseline reproduced audio/Bluetooth, camera, NFC, and
fingerprint defects. The current source adds the first three corresponding
build fixes; on-device acceptance is still required.

## What this repo is
The **device tree** (`device/nothing/metroid`), required framework/recovery
patches, recovery-installer source, prebuilt kernel/DTB/module artifacts used by
the current port, and the bring-up guide. It does **not** contain proprietary
vendor blobs, release private keys, modem firmware, or bootloader firmware.

## Building
1. Set up a LineageOS 23 source tree.
2. Copy [`manifest/metroid.xml`](manifest/metroid.xml) into
  `.repo/local_manifests/`, then sync.
3. Extract proprietary blobs from your own B4.1 stock dump:
  `./device/nothing/metroid/extract-files.py /path/to/stock/dump`.
4. Apply the required source patches:
   ```bash
  git -C frameworks/base am \
    ../../device/nothing/metroid/patches/frameworks_base/*.patch
  git -C bootable/recovery am \
    ../../device/nothing/metroid/patches/bootable_recovery/*.patch
   ```
5. Build:
   ```bash
   source build/envsetup.sh
   lunch lineage_metroid-bp2a-userdebug
  m bacon
   ```

See [`patches/README.md`](patches/README.md) for the exact source revisions.

## Flashing landmines (read before flashing)
- Use [`INSTALL.md`](INSTALL.md) and the matched recovery bootstrap bundle. Do
  not manually force the full OTA target slot; Update Engine selects it.
- **Never** disable verity/verification on the **root** vbmeta.
- vendor must be **ext4**; vendor_boot page_size **0x1000**; make `vbmeta_vendor`
  coherently from the images.
- `fastboot boot` hangs — always flash + reboot.

## Known issues
- The exact 2026-07-31 candidate still needs post-install boot and hardware
  acceptance. Current hardware claims intentionally remain unpublished.
- The prior clean baseline failed audio/Bluetooth, camera, NFC, and fingerprint.
  The current source packages the audio vendor extension, declares the served
  Nothing camera interface in VINTF, and satisfies the clean-start NFC gate.
- Fingerprint remains an open acceptance item.
- **Slow first boot (~5-7 min)** — runtime is imageless (odsign/boot-level key);
  fixable with `WITH_DEXPREOPT`; subsequent boots are normal speed.
- Minor cosmetic HAL noise: `memtrack`, `lights`, `power.stats` log
  registration failures — not user-visible.

## Credits
LineageOS, Qualcomm CAF, reference trees **onyx** (Xiaomi 15 / SM8750) and
**pong** (Nothing Phone 2), and Nothing for the kernel source.

*Unofficial. No warranty. You are responsible for your device.*
