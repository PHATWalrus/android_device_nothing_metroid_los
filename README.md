# LineageOS 23 device tree — Nothing Phone (3) `metroid`

Unofficial, **work-in-progress bring-up** of LineageOS 23 (Android 16) for the
Nothing Phone (3) — codename `metroid`, Qualcomm **SM8735**.

**Status: ALPHA — it BOOTS** to the Setup Wizard (`sys.boot_completed=1`), but
**audio, cellular (RIL), camera and NFC do not work yet.** See
[`BRINGUP_GUIDE.md`](BRINGUP_GUIDE.md) for the full technical story and
[Known issues](#known-issues).

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
- **Audio** — no ALSA sound card (ADSP audio-DSP path down).
- **RIL / Camera** — HAL `CANNOT LINK` (linker-namespace / `ld.config.txt`).
- **NFC / SE**, **fingerprint** — HAL down.
- **Slow first boot (~7 min)** — runtime is imageless (odsign/boot-level key);
  fixable with `WITH_DEXPREOPT`.

## Credits
LineageOS, Qualcomm CAF, reference trees **onyx** (Xiaomi 15 / SM8750) and
**pong** (Nothing Phone 2), and Nothing for the kernel source.

*Unofficial. No warranty. You are responsible for your device.*
