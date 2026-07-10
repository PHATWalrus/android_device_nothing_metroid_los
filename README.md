# LineageOS 23 device tree — Nothing Phone (3) `metroid`

Unofficial port of LineageOS 23 (Android 16) for the Nothing Phone (3) —
codename `metroid`, Qualcomm **SM8735**.

**Status: BETA** — boots to a usable daily-driver UI with most major subsystems
working. **Camera is not working yet** (HAL linker-namespace issue — see
[Known issues](#known-issues)). See [`BRINGUP_GUIDE.md`](BRINGUP_GUIDE.md) for
the full technical story.

## What works
| Feature | Status |
|---------|--------|
| Boot to LineageOS UI | ✅ Working |
| Display + touch | ✅ Working |
| Wi-Fi (2.4 GHz + 5 GHz) | ✅ Working |
| Audio (speaker, earpiece, mic) | ✅ Working |
| Cellular / RIL (calls, SMS, data) | ✅ Working |
| Bluetooth | ✅ Working |
| GNSS / GPS | ✅ Working |
| NFC | ✅ Working |
| Sensors (accel, gyro, proximity…) | ✅ Working |
| adb / USB debugging | ✅ Working |
| Storage / /data | ✅ Working |
| Camera | ❌ Not working (HAL link failure) |
| Fingerprint (in-display) | ❌ Not working (HAL crash-loop) |

## What this repo is
The **device tree** (`device/nothing/metroid`) plus the **framework patches**,
build/flash **scripts**, and the **bring-up guide**. It does **not** contain
proprietary vendor blobs (extract those from your own device) or the kernel /
prebuilt boot chain.

## Building
1. Set up a LineageOS 23 source tree.
2. Add a local manifest (see [`manifest/metroid.xml`](manifest/metroid.xml)) that
   pulls this device tree (and your kernel/prebuilt repo).
3. Extract proprietary blobs from a running stock device:
   `./device/nothing/metroid/extract-files.sh` (blobs are **not** redistributed).
4. **Apply the framework patches** (required to reach boot):
   ```bash
   cd frameworks/base
   git am /path/to/device/nothing/metroid/patches/*.patch
   ```
   - `0001-soundtrigger-...` — SoundTrigger tolerates audio policy being down
   - `0002-usb-gadget-hal-...` — UsbService doesn't block `finishBooting` on a disabled gadget HAL
5. Build:
   ```bash
   source build/envsetup.sh
   lunch lineage_metroid-bp2a-userdebug
   m
   ```

## Flashing landmines (read before flashing)
- **Slot A only.** `fastboot set_active a` + `fastboot erase misc` before every flash.
- **Never** disable verity/verification on the **root** vbmeta.
- vendor must be **ext4**; vendor_boot page_size **0x1000**; make `vbmeta_vendor`
  coherently from the images.
- `fastboot boot` hangs — always flash + reboot.

## Known issues
- **Camera** — camera HAL `CANNOT LINK` (`android.frameworks.cameraservice.common-V1-ndk.so`);
  linker-namespace / `ld.config.txt` problem. **This is the primary outstanding issue.**
- **Fingerprint** — HAL crash-loops; in-display fingerprint not working.
- **Slow first boot (~5-7 min)** — runtime is imageless (odsign/boot-level key);
  fixable with `WITH_DEXPREOPT`; subsequent boots are normal speed.
- Minor cosmetic HAL noise: `memtrack`, `lights`, `power.stats` log
  registration failures — not user-visible.

## Credits
LineageOS, Qualcomm CAF, reference trees **onyx** (Xiaomi 15 / SM8750) and
**pong** (Nothing Phone 2), and Nothing for the kernel source.

*Unofficial. No warranty. You are responsible for your device.*
