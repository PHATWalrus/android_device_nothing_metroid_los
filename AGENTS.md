# AGENTS.md — READ THIS FIRST (metroid / Nothing Phone 3 / LineageOS 23)

**STATUS: THE DEVICE BOOTS.** LineageOS 23 reaches `sys.boot_completed=1`, the
real launcher (QuickstepLauncher), with **touch working**. This is a hard-won
known-good state. Git tag: **`known-good-boot-20260708`** (this repo).

> If you break the boot, `git checkout known-good-boot-20260708` here, restore
> the vendor tree, rebuild, reflash. See "RESTORE" below.

---

## ⛔ DO NOT DO THESE — they each break the boot (learned the hard way)

1. **Do NOT declare unserved HALs in VINTF.** `PRODUCT_ENFORCE_VINTF_MANIFEST := true`
   is on. If you add RIL / camera / NFC / secure_element / etc. to
   `DEVICE_MANIFEST_FILE` (e.g. via `configs/hidl/manifest_qti_hals.xml`) but those
   HALs don't actually run, **system_server blocks forever waiting for them → boot
   fails / reboots to recovery.** Keep `DEVICE_MANIFEST_FILE` MINIMAL:
   ```
   DEVICE_MANIFEST_FILE := device/nothing/metroid/configs/hidl/manifest.xml \
       hardware/qcom-caf/sm8750/audio/primary-hal/hal/core/manifest_audiocoreservices_qti.xml
   ```
   Only add a HAL to VINTF once its service is actually serving.

2. **Do NOT touch `rootdir/etc/init.target.rc`** except with extreme care. The
   INSTALLED init.target.rc must be the **232-line** version (contains the
   `OPUS_NTLOG_KEEP` marker, does **NOT** contain any `OPUS-USB-BRINGUP` block).
   - The `OPUS-USB-BRINGUP` block writes `a600000.dwc3/mode peripheral` directly —
     this **stomps early-adb's dwc3 dance** and you lose adb during boot.
   - A bloated init.target.rc also pulled in `critical` services that fatal ~78s →
     `init_fatal_reboot_target=recovery` → recovery loop.
   - **Landmine:** there are DUP install rules for init.target.rc (device rootdir
     AND vendor proprietary) and the build **staging goes stale**. If you change it,
     force-clean: `rm $OUT/vendor/etc/init/hw/init.target.rc` and the matching
     `out/soong/.intermediates/**/init.target.rc`, then rebuild vendorimage.

3. **USB Gadget HAL and early-adb are integrated in a hybrid config.**
   The QTI USB gadget HAL (`vendor.usbgadget-hal`) is enabled to allow dynamic
   USB composition switching (MTP, PTP, MIDI, tethering) via the LineageOS UI.
   To avoid conflicts and retain early boot observability, `init.qcom.usb.rc`
   sets up a hybrid configuration: it initializes and mounts all configfs
   functions (MTP, PTP, adb, etc.) early under `on fs` and triggers static
   early-adb at boot, before handing over to the dynamic USB gadget HAL
   (triggered by `sys.usb.configfs=2` in late boot).

4. **Do NOT revert the two `frameworks/base` patches** (in `patches/frameworks_base/`).
   They are required to reach boot_completed:
   - SoundTrigger `ExternalCaptureStateTracker` LOG_ALWAYS_FATAL → non-fatal.
   - `UsbGadgetAidl.isServicePresent` isDeclared → checkService (non-blocking).

5. **Do NOT change `ro.hw_timeout_multiplier=4`** (in `device.mk`
   `PRODUCT_SYSTEM_PROPERTIES`). It must be in **/system/build.prop** (not vendor) —
   it gives the 240s Watchdog needed to survive the slow imageless first boot.

---

## RESTORE (if boot breaks)
```
cd device/nothing/metroid && git checkout known-good-boot-20260708
# vendor tree: ensure init.qcom.usb.rc (adb-only), init.target.rc (nt_kmsg),
#   gadget HAL disabled are intact (see patches/vendor_nothing_metroid/)
cd ~/dev/metroid && ./build_los23.sh systemimage && ./build_los23.sh vendorimage
bash build_dlkmfix.sh && bash flash_props.sh    # then adb reboot bootloader to trigger the flash
```

## BUILD / FLASH
- Product-config changes need `./build_los23.sh {systemimage|superimage}` (kati regen), NOT bare ninja.
- Framework `.java/.cpp` → `systemimage`. init rc / VINTF / PRODUCT_PACKAGES → **`superimage`**
  (it pulls vendorimage → INTERNAL_VENDORIMAGE_FILES, so the new module actually gets built).
  NEVER `vnod`/`snod`/`*-nodeps` after a PRODUCT_PACKAGES change — they repack without building it,
  which is how `audiohalservice.qti` silently vanished from vendor.img (2026-07-24).
- Dropping a module from PRODUCT_PACKAGES does NOT remove it from the staging dir on an incremental
  build — `rm` the stale file out of `out/.../vendor/...` yourself or it still ships.
- Before every flash run `python3 ~/dev/metroid/audit_init_rc_services.py` (shipped init services
  whose binary isn't installed) and `python3 ~/dev/metroid/diff_vendor_images.py`.
- Repack super + coherent vbmeta_vendor: `bash build_dlkmfix.sh`.
- Flash: `bash flash_props.sh` (flashes super+vbmeta+vbmeta_vendor+init_boot; watches boot_completed).
- Bounce Android/recovery → fastboot with `adb reboot bootloader` (no button-holds).
- LANDMINES: slot **a** only; `fastboot set_active a` + `fastboot erase misc` before every flash;
  NEVER `--flags 3` on the ROOT vbmeta; vendor must be ext4; vendor_boot page_size 0x1000;
  `fastboot boot` hangs.

## OBSERVABILITY (use it — do not guess)
Early-adb gives `adb` ~30s into boot, before failures. `adb logcat -b all`, `dmesg`,
tombstones (F DEBUG in logcat), `getprop sys.system_server.start_count` (climbing =
crash loop). Classify: Watchdog kill vs native SIGABRT vs Java FATAL are 3 different bugs.

## HOW IT BOOTS (full write-up: BRINGUP_GUIDE.md)
Module-set (339 .ko into empty vendor_dlkm) → sepolicy wired → early-adb →
hw_timeout_multiplier=4 → audio core HAL packaged → 2 framework patches.

## POST-BOOT TODO (work on these WITHOUT breaking boot; verify each with a reflash)
- **Audio**: no ALSA sound card (`/proc/asound/cards` empty). ADSP audio-DSP path down:
  `vendor.adsprpcd` crash-loops exit 114 / `fastrpc_wait_for_secure_device: Poll timeout`.
  Fix ADSP/fastRPC → sound card registers → PAL/AGM/ACDB → real audio.
- **Faster boot**: currently imageless (odsign/keystore BootLevel key fails). Either fix the
  keystore boot-level key, or dexpreopt the boot image into /system
  (`WITH_DEXPREOPT := true` + `PRODUCT_USES_DEFAULT_ART_CONFIG` + `DEX_PREOPT_WITH_UPDATABLE_BCP`).
- **RIL + camera**: `CANNOT LINK` on `android.hardware.radio-V3-ndk.so` /
  `android.frameworks.cameraservice.common-V1-ndk.so` (libs present in /vendor/lib64 →
  linker-namespace / `ld.config.txt` issue). NOTE: fix the LINKING, and only THEN declare
  the HAL in VINTF (see landmine #1).
- **NFC / SE / fingerprint**: HALs down; not boot-blocking.

## GIT / PUSH
- Device tree remote: `logix727/android_device_nothing_metroid` (public). Push HEAD + the tag.
- Vendor tree (`android_vendor_nothing_metroid`) holds **proprietary blobs** — do NOT push to a
  public repo (DMCA). The important vendor *config* (early-adb, nt_kmsg, gadget-disabled) is
  captured as patches in `patches/vendor_nothing_metroid/`.
- A push SSH key exists on the build server: `~/.ssh/id_ed25519_gh` (add its .pub to GitHub).
