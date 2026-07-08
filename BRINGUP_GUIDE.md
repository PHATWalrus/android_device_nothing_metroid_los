# Bringing up LineageOS 23 on the Nothing Phone (3) — a from-crash-loop-to-boot bring-up log

**Device:** Nothing Phone (3) — codename **`metroid`** (Tuna QRD, Qualcomm **SM8735**)
**Target:** LineageOS 23 (Android 16 / ART)
**Result:** Full userspace boot — `sys.boot_completed=1`, LineageOS Setup Wizard on screen.

This is a **bring-up log / guide**: not a polished "flash this ZIP" tutorial, but the actual ordered set of fixes that took the port from *bootloops forever* to *boots to the setup wizard*, plus the **method** that found each one. If you are porting LOS to another SM8735 / recent-Snapdragon device, the *method* matters more than the specific fixes.

> ⚠️ This is a WIP bring-up. Audio, RIL (cellular), camera and NFC are **not** working yet (see [Known issues](#known-issues)). This document is about reaching first boot.

---

## TL;DR — the fix stack that reached first boot

In the order they had to be climbed:

| # | Problem | Fix |
|---|---------|-----|
| 1 | Display panic — `vendor_dlkm` shipped **empty** (0 `.ko`) | Package the full stock kernel-module set (~339 `.ko`) into `vendor_dlkm`/`system_dlkm` with the stock load order |
| 2 | keymint/keystore couldn't start (SELinux + missing libs) | Wire QCOM sepolicy into the build; `PRODUCT_PRECOMPILED_SEPOLICY := false`; add missing HAL libs |
| 3 | **Blind** — no adb, `nt_kmsg` stops at system_server | **Early-adb**: a minimal adb-only configfs USB gadget in init, bypassing the (broken) QTI gadget HAL |
| 4 | system_server killed by the framework Watchdog at 60 s | `ro.hw_timeout_multiplier=4` in **/system/build.prop** → 240 s Watchdog (survives the slow *imageless* first boot) |
| 5 | audioserver `SIGSEGV`, cascading to a system_server crash-loop | Package the audio core HAL (`audiohalservice.qti`) + its VINTF fragment |
| 6 | SoundTrigger `LOG_ALWAYS_FATAL` killed system_server when audio policy was down | **Framework patch**: make `ExternalCaptureStateTracker::connect()` non-fatal |
| 7 | `finishBooting()` blocked forever on the disabled USB gadget HAL | **Framework patch**: `UsbGadgetAidl.isServicePresent()` → non-blocking `checkService` |

---

## 0. The single most important idea: get observability FIRST

Every hour spent building a fix blind is wasted. The turning point in this bring-up was **early-adb** (fix #3). Before it we were reading a Nothing-specific kernel ring buffer (`nt_kmsg`) that helpfully *stops recording when system_server starts* — i.e. it goes dark exactly where the bug is. After early-adb we had live `logcat`, `dmesg`, `/proc`, tombstones and Java stacks, and every subsequent fix took one iteration instead of ten.

**If you take one thing from this guide: make `adb` come up during boot, before the thing that's failing, and do it independently of the vendor USB stack.** See [§3](#3-early-adb--the-observability-backbone).

---

## 1. Prerequisites & sources

- A LineageOS 23 build environment (Linux, ~200 GB free, the usual `repo`/`soong` toolchain).
- A **local manifest** that pulls:
  - **device tree**: `device/nothing/metroid` (this repo)
  - **kernel / prebuilts**: `device/nothing/metroid-kernel` (prebuilt `boot`/`init_boot`/`vendor_boot`/`dtbo` + the DLKM module images — see fix #1)
  - **QCOM common**: `device/qcom/sepolicy_vndr` (branch matching your platform, e.g. `lineage-23.x-caf-sm8750`), `hardware/qcom-caf/sm8750/*`
  - **proprietary blobs**: extract from a running stock image with `extract-files.sh` (these are **not** redistributable — do not commit them)
- Reference trees that were invaluable: **onyx** (Xiaomi 15, SM8750 "sun" — packaging/AVB/USB/fstab conventions) and **pong** (Nothing Phone 2 — same-vendor Glyph/keymint/nt_kmsg patterns).

### `lunch` target
```
lunch lineage_metroid-bp2a-userdebug
```
`userdebug` matters — you want `ro.debuggable=1` and adb-root-ish behaviour during bring-up.

---

## 2. Fix #1 — the empty `vendor_dlkm` (display / DSP)

**Symptom:** hard reset ~2.6 s into boot; nothing on screen.

**Cause:** the LOS build produced `vendor_dlkm.img` and `system_dlkm.img` with **zero** kernel modules (no `BOARD_VENDOR_KERNEL_MODULES`), so the display DRM chain, the remoteproc/DSP stack (smp2p/q6v5_pas/glink), and dozens of others never loaded. The panel (`rm692j0` BOE, wired on the *tuna* SDE-display chain) never bound.

**Fix:** ship the **full stock module set** (~339 `.ko`) in `vendor_dlkm`/`system_dlkm` with the **stock `modules.load` order** (display second-stage, `msm_drm` last). On this device the module images live as prebuilts under `device/nothing/metroid-kernel/`.

Reference to match on-device: recovery `lsmod` ≈ 346, `remoteproc/*/state` = `running`, panel lights up, no `framedone`/`switch_te:0` panic.

---

## 3. Early-adb — the observability backbone

**Symptom:** no `adb` in Android (`udc a600000.dwc3: failed to start g1: -19/-77` — the QTI gadget HAL never binds the UDC), and the Nothing `nt_kmsg` driver stops recording once `sys.system_server.start_count=1`.

**Fix:** stop relying on the vendor USB stack. Replace `/vendor/etc/hw/init.qcom.usb.rc` with a **minimal, adb-only configfs gadget** set up directly in init, and **disable** the QTI gadget HAL so it can't fight it. The recipe is modeled on the device's own *recovery* USB init (which works), and the load-bearing detail is the **dwc3 mode dance**:

```rc
# init.qcom.usb.rc — minimal adb-only gadget (bring-up)
on early-init
    setprop sys.usb.configfs 0

on fs
    mount configfs none /config
    mkdir /config/usb_gadget/g1 0770 shell shell
    write /config/usb_gadget/g1/bcdUSB 0x0200
    write /config/usb_gadget/g1/idVendor 0x18D1
    write /config/usb_gadget/g1/idProduct 0x4EE7
    mkdir /config/usb_gadget/g1/strings/0x409 0770 shell shell
    write /config/usb_gadget/g1/strings/0x409/serialnumber ${ro.serialno}
    write /config/usb_gadget/g1/strings/0x409/manufacturer ${ro.product.manufacturer}
    write /config/usb_gadget/g1/strings/0x409/product ${ro.product.model}
    mkdir /config/usb_gadget/g1/functions/ffs.adb
    mkdir /config/usb_gadget/g1/configs/b.1 0770
    mkdir /config/usb_gadget/g1/configs/b.1/strings/0x409 0770
    write /config/usb_gadget/g1/configs/b.1/MaxPower 500
    mkdir /dev/usb-ffs 0775 shell system
    mkdir /dev/usb-ffs/adb 0770 shell system
    mount functionfs adb /dev/usb-ffs/adb uid=2000,gid=1000,rmode=0770,fmode=0660,no_disconnect=1
    setprop sys.usb.configfs 1

# THE LOAD-BEARING PART: cycle the dwc3 through idle -> peripheral and wait for the UDC
on property:ro.boot.usbcontroller=*
    setprop sys.usb.controller ${ro.boot.usbcontroller}
    wait /sys/bus/platform/devices/${ro.boot.usb.dwc3_msm:-a600000.ssusb}/mode
    write /sys/bus/platform/devices/${ro.boot.usb.dwc3_msm:-a600000.ssusb}/mode idle
    wait /sys/class/udc/${ro.boot.usbcontroller} 0
    write /sys/bus/platform/devices/${ro.boot.usb.dwc3_msm:-a600000.ssusb}/mode peripheral
    wait /sys/class/udc/${ro.boot.usbcontroller} 1

on boot
    setprop sys.usb.config adb

on property:sys.usb.config=adb && property:sys.usb.configfs=1
    start adbd

# bind the UDC ONLY after adbd has opened ffs (sys.usb.ffs.ready=1)
on property:sys.usb.ffs.ready=1 && property:sys.usb.config=adb && property:sys.usb.configfs=1
    write /config/usb_gadget/g1/configs/b.1/strings/0x409/configuration "adb"
    symlink /config/usb_gadget/g1/functions/ffs.adb /config/usb_gadget/g1/configs/b.1/f1
    write /config/usb_gadget/g1/UDC ${sys.usb.controller}
    setprop sys.usb.state adb
```

Disable the QTI gadget HAL (add `disabled` to the service in `android.hardware.usb.gadget-service.qti.rc`).

**Two things my first attempt got wrong** (learn from them):
1. It wrote `mode peripheral` directly, without the `idle → wait udc 0 → peripheral → wait udc 1` sequence. That's why it failed `-19/-77`.
2. It wrote the UDC before `adbd` had opened the functionfs endpoints (`sys.usb.ffs.ready=1`).

**Result:** `adb` comes up ~30 s into boot, before the failures. From here on, everything is `adb logcat -b all`, `dmesg`, tombstones and `debuggerd -j`.

> ⚠️ This *is* a self-inflicted wound later — see fix #7. Disabling the gadget HAL blocks `finishBooting()`. Both are needed.

---

## 4. Fix #4 — the framework Watchdog vs the imageless first boot

**Symptom (after early-adb):** system_server reaches ~phase 480, then `*** WATCHDOG KILLING SYSTEM PROCESS: Blocked in handler on main thread for 65s` → restart → forever (`sys.system_server.start_count` climbs).

**Root cause chain:**
- `odsign` fails at boot: `keystore2 super_key.rs:717 Boot stage key absent / LOCKED` (the KeyMint **boot-level key** can't be created — `Status(-8)`, the TEE rejects the `EARLY_BOOT_ONLY` param).
- → the ART **on-device boot image (`boot.art`) is never generated** → the whole runtime runs **imageless** (5–10× slower).
- → system_server's startup exceeds the **60 s** framework Watchdog → killed → restart loop.

**Fix (survive the slow boot):**
```make
# device.mk — MUST be PRODUCT_SYSTEM_PROPERTIES (/system/build.prop), NOT vendor.prop.
# /vendor/build.prop is read AFTER zygote preloads android.os.Build on this device,
# so Build.HW_TIMEOUT_MULTIPLIER never sees a vendor-hosted value.
PRODUCT_SYSTEM_PROPERTIES += \
    ro.hw_timeout_multiplier=4 \
    ro.keystore.boot_level_key.strategy=TRUSTED_ENVIRONMENT:MAX_USES_PER_BOOT
```
`ro.hw_timeout_multiplier=4` scales the Watchdog (and ANR, etc.) to 240 s — enough for the imageless boot to get through.

> This does not *fix* the imageless slowness; it makes it survivable. The proper fix is either the keystore boot-level key, or **dexpreopting the boot image into `/system`** (`WITH_DEXPREOPT := true` + `PRODUCT_USES_DEFAULT_ART_CONFIG` + `DEX_PREOPT_WITH_UPDATABLE_BCP`), which removes the odsign dependency entirely. That's future work.

**Why /system and not /vendor:** the same device tree already documents this trap for `dalvik.vm.heapsize`. Anything read during zygote class-preload must be in `/system/build.prop`.

---

## 5. Fix #5 — the audio core HAL was built but never installed

**Symptom:** with the Watchdog survivable, the *real* killer appeared — a native `SIGABRT` in a system_server thread, plus `audioserver` `SIGSEGV` in `AudioFlinger::onFirstRef()` every 5 s.

**Cause:** `servicemanager: Could not find android.hardware.audio.core.IModule/default in the VINTF manifest`, and `init: Cannot find '/vendor/bin/hw/audiohalservice.qti'`. The audio HAL binary was **built** by soong (`hardware/qcom-caf/sm8750/audio/primary-hal/...`) but **not installed** — it wasn't in `PRODUCT_PACKAGES`. No HAL → audioserver gets a null device factory → null-deref.

**Fix:**
```make
# device.mk
PRODUCT_PACKAGES += audiohalservice.qti      # soong pulls the PAL/AGM lib stack automatically
```
```make
# BoardConfig.mk — merge the audio.core VINTF fragment so IModule/default is declared
DEVICE_MANIFEST_FILE := device/nothing/metroid/configs/hidl/manifest.xml \
    hardware/qcom-caf/sm8750/audio/primary-hal/hal/core/manifest_audiocoreservices_qti.xml
```
(The HAL `.bp` doesn't declare `vintf_fragments`, so the manifest must be merged via `DEVICE_MANIFEST_FILE`.)

> This makes the HAL *present* but it still crashes at runtime because **there's no ALSA sound card** (the ADSP audio-DSP path isn't up — see [Known issues](#known-issues)). That's fine for *booting*; fixes #6/#7 make the OS tolerate audio being down.

---

## 6. Fix #6 — SoundTrigger must not be fatal when audio is down

**Symptom:** system_server dies in `Thread-8` with `Abort message: 'Assertion failed: status != NO_ERROR'`. Java stack:
```
LOG_ALWAYS_FATAL  (libandroid_servers, connect())
 ← com.android.server.soundtrigger_middleware.ExternalCaptureStateTracker.run
```
`ExternalCaptureStateTracker` registers a capture-state listener with the audio policy service. When audioserver is crash-looping, the registration fails and the JNI `connect()` calls `LOG_ALWAYS_FATAL_IF(status != NO_ERROR)` — taking down system_server.

**Fix (framework patch — `frameworks/base`):**
```diff
--- a/services/core/jni/com_android_server_soundtrigger_middleware_ExternalCaptureStateTracker.cpp
+++ b/services/core/jni/com_android_server_soundtrigger_middleware_ExternalCaptureStateTracker.cpp
@@ void connect(JNIEnv* env, jobject obj) {
     status_t status =
         AudioSystem::registerSoundTriggerCaptureStateListener(listener);
-    LOG_ALWAYS_FATAL_IF(status != NO_ERROR);
+    (void) status; // bring-up: tolerate audio policy/HAL down so system_server boots
 }
```
The Java `run()` loop simply parks on its reconnect semaphore afterward — no busy-loop.

**Result:** system_server becomes **stable** (`start_count=1`), reaches `FallbackHome` and `OnBootPhase_1000`.

---

## 7. Fix #7 — the disabled gadget HAL blocks `finishBooting()`

**Symptom:** `boot_completed` never flips. Watchdog stack:
```
Blocked in handler on display thread for 245s
  CompletableFuture.join
  UsbService$Lifecycle.onBootPhase(UsbService.java:140)
  ActivityManagerService.finishBooting(:5219)
```
`UsbService` → `UsbDeviceManager.systemReady()` → `UsbGadgetHalInstance.getInstance()` → `UsbGadgetAidl.connectToProxy()` → **`ServiceManager.waitForService(IUsbGadget)` blocks forever**, because the gadget HAL is **declared in VINTF but disabled** (fix #3). `isServicePresent()` returns `isDeclared()` = true, so it tries — and hangs.

`UsbDeviceManager` already tolerates a **null** HAL (it falls back to a legacy handler), so the fix is to make presence-detection **non-blocking**:

**Fix (framework patch — `frameworks/base`):**
```diff
--- a/services/usb/java/com/android/server/usb/hal/gadget/UsbGadgetAidl.java
+++ b/services/usb/java/com/android/server/usb/hal/gadget/UsbGadgetAidl.java
@@ static boolean isServicePresent(IndentingPrintWriter pw) {
         try {
-            return ServiceManager.isDeclared(USB_GADGET_AIDL_SERVICE);
+            return ServiceManager.checkService(USB_GADGET_AIDL_SERVICE) != null; // bring-up: avoid finishBooting block on disabled gadget HAL
```
`checkService` returns null immediately when the service isn't running → `getInstance()` returns null → legacy handler → `finishBooting()` returns → **`boot_completed=1`**.

> If/when you re-enable a working gadget HAL, this patch is a no-op (the service is running, so `checkService != null`).

**Result:** 🎉 `sys.boot_completed=1`, `topResumedActivity=org.lineageos.setupwizard/.WelcomeActivity`.

---

## 8. Build & flash flow

Product-config changes (`PRODUCT_*`, `BoardConfig`) require a **kati regen**, not a bare `ninja`:
```bash
source build/envsetup.sh
lunch lineage_metroid-bp2a-userdebug
# rebuild only what changed:
m systemimage      # for /system/build.prop + framework .java/.cpp patches
m vendorimage      # for /vendor init rc's, VINTF, PRODUCT_PACKAGES
```

Then repack `super` + a **coherent** `vbmeta_vendor` (the tree does not build `vbmeta_vendor` for a modified vendor) and flash. See the `scripts/` in this repo (`build_dlkmfix.sh`, `flash_props.sh`).

### Flashing landmines (device-specific — read before flashing)
- **Slot `a` only** — slot `b` is unbootable on this unit. `fastboot set_active a` + `fastboot erase misc` before every flash (BCB/retry-count can brick a slot).
- **Never** `--disable-verity` / `--flags 3` on the **root** `vbmeta`.
- **vendor must be ext4** with the milestone boot chain; system/product/system_ext EROFS is fine.
- **vendor_boot page_size = 0x1000** (stock-based); a LOS-built `0x800` vendor_boot bricks.
- Modifying vendor breaks AVB unless `vbmeta_vendor` is **hand-made coherently** from the images.
- `fastboot boot` hangs — always flash + reboot.
- You can bounce Android/recovery → fastboot with `adb reboot bootloader` (no button-holds).

---

## 9. The debugging method (reusable)

1. **Early-adb first.** Nothing else matters until you can `adb logcat` during the failure.
2. **Classify the death**: `logcat -b crash`, `getprop sys.system_server.start_count` (climbing = loop). Watchdog kill vs native `SIGABRT` vs Java `FATAL EXCEPTION` are three different bugs.
3. **Read the stack the tool gives you** — the Watchdog dumps the blocked thread's stack straight to logcat; native crashes dump a `F DEBUG` tombstone to logcat. You rarely need root or `/data/tombstones`.
4. **Follow the cascade to the root** — e.g. system_server SIGABRT → SoundTrigger → audio policy → audioserver → audio HAL → no sound card. Fix the *lowest* thing you can, and gate the framework against the rest.
5. **When stuck, research** the exact error string (AOSP source, gerrit, other device trees) instead of trial-and-error.

---

## Known issues

Booting ≠ working. Still broken (all **non**-boot-blocking):

- **Audio** — no ALSA sound card (`/proc/asound/cards` empty). Audio kernel modules load, but the card never registers because the ADSP audio-DSP path isn't serving (`vendor.adsprpcd` crash-loops `exit 114`, `fastrpc_wait_for_secure_device: Poll timeout`). This is the big one.
- **Slow boot (~7 min)** — runtime is imageless (see fix #4). Fix via keystore boot-level key or `WITH_DEXPREOPT`.
- **Cellular (RIL) & camera** — `CANNOT LINK` on `android.hardware.radio-V3-ndk.so` / `android.frameworks.cameraservice.common-V1-ndk.so` (libs present in `/vendor/lib64` → a **linker-namespace / ld.config.txt** problem).
- **NFC / Secure Element** — persistent apps ANR ("failed to complete startup"); HAL down.
- **memtrack / lights / power.stats / identity / fingerprint** HALs abort `Check failed status=-3` (register failures) — noise, not fatal.

## Credits

- LineageOS team & QCOM CAF sources.
- Reference device trees: **onyx** (Xiaomi 15 / SM8750), **pong** (Nothing Phone 2), and the SM8735 ODM trees.
- Nothing for publishing the kernel source (it has the `rm692j0` panel + tuna display chain).

*This document describes an in-progress, unofficial bring-up. No warranty. You are responsible for your device.*
