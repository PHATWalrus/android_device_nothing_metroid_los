DEVICE_PATH := device/nothing/metroid

# Bring-up: dexpreopt off (restores 07-05 23:40 known-good EROFS bring-up config)
WITH_DEXPREOPT := false

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    system_ext \
    boot \
    init_boot \
    vendor_boot \
    system \
    vendor \
    vendor_dlkm \
    system_dlkm \
    odm \
    recovery \
    product \
    pvmfw \
    dtbo \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo300
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a75

# Bootloader
TARGET_NO_BOOTLOADER := true
BOARD_VENDOR := nothing
TARGET_SOC := sun
TARGET_BOOTLOADER_BOARD_NAME := $(TARGET_SOC)
TARGET_BOARD_PLATFORM := $(TARGET_SOC)
QCOM_BOARD_PLATFORMS := $(TARGET_SOC)
TARGET_BOARD_PLATFORM_GPU := Adreno-825

# Display
TARGET_SCREEN_DENSITY := 460
TARGET_SCREEN_HEIGHT := 1260
TARGET_SCREEN_WIDTH := 2800
TARGET_USES_VULKAN := true

# Board
BOARD_USES_QCOM_HARDWARE := true
BOARD_NO_RADIOIMAGE := true

# Allow prebuilt ELF .so blobs shipped via PRODUCT_COPY_FILES
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# BUILD_BROKEN_DUP_RULES: still needed, but ONLY because of an AOSP-side duplicate.
#
# Turning it off on 2026-07-29 surfaced six real duplicate-install bugs in this tree, all now
# fixed (see below). After those, the only remaining collision is inside AOSP itself —
# system_ext/etc/aconfig/flag.info, defined by both build/make/core/Makefile:146 and
# build/make/core/packaging/flags.mk:169 — which is not ours to fix, so the flag goes back on.
#
# Real bugs it had been hiding, all fixed:
#   1. stock fstab.default blob shadowed the device-tree copy -> vold saw no fileencryption and
#      FBE silently fell back to plaintext (ro.crypto.state=unsupported)
#   2. stock fstab.emmc blob, same pattern
#   3. our hand-made android.hardware.drm-service.clearkey.xml duplicated AOSP's own fragment
#   4. our mapper.qti.xml duplicated the one from hardware/qcom-caf/.../gralloc (this one had
#      already been "dropped" in a comment on 07-10 but the module was never actually removed)
#   5. our vendor.qti.qspa-service.xml duplicated core-utils-vendor's
#   6. libprotobuf-cpp-{full,lite}-21.12 and libclang_rt.ubsan_standalone shipped as blobs while
#      the platform builds the same sonames from source
#
# Periodically re-test by commenting this out and running a build; anything new it catches is a
# genuine bug, not noise. Duplicate destinations are how the sepolicy clobber (07-25) and the FBE
# failure (07-29) both hid in plain sight.
BUILD_BROKEN_DUP_RULES := true

# Allow missing required modules (e.g. prebuilt_libqcomfm_jni:64 required by FM2)
BUILD_BROKEN_MISSING_REQUIRED_MODULES := true

# Custom OEM Android IDs (vendor_qtr, vendor_qcc, etc.) referenced by vendor init scripts
TARGET_FS_CONFIG_GEN := device/nothing/metroid/config.fs

# Kernel
BOARD_BOOT_HEADER_VERSION := 4
BOARD_RAMDISK_USE_LZ4 := true
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_TAGS_OFFSET := 0x00000100
BOARD_DTB_OFFSET := 0x01f00000
# androidboot.init_fatal_reboot_target=recovery: REMOVED 2026-07-29. It was a bring-up aid (an init
# FATAL booted recovery, which has adb, instead of dropping to fastboot). It caused THREE recovery
# bootloops before being identified: in recovery mode a fatal init error reboots to recovery, which
# fails again, forever. It does this to ANY recovery image — a known-good OrangeFox build looped
# identically, which is what finally isolated it. Init's default target is "bootloader", so without
# this flag a failing recovery lands in fastboot on its own: recoverable AND diagnosable.
# Do not re-add it. Use a per-boot `fastboot boot` override if a bring-up aid is ever needed again.
#
# selinux: androidboot.selinux=permissive was removed from BOTH this line and BOARD_BOOTCONFIG on
# 2026-07-28. It was set in two places, so removing only one had no effect.
#
# The first three tokens are NOT optional and were missing until 2026-07-28. For boot header v4
# this string becomes the *vendor_boot* cmdline, but vendor_boot used to be a prebuilt, so this
# variable only ever fed boot.img and nobody noticed it did not match. The stock/known-good
# vendor_boot cmdline carries:
#     video=vfb:640x400,bpp=32,memsize=3072000   framebuffer geometry
#     qcom_geni_serial.con_enabled=0             this board has no usable UART
#     console=ttynull                            with ignore_loglevel + printk.devkmsg=on and no
#                                                console, boot stalls before init
# Building vendor_boot from source without them hangs on the Nothing logo.
BOARD_KERNEL_CMDLINE := video=vfb:640x400,bpp=32,memsize=3072000 qcom_geni_serial.con_enabled=0 console=ttynull bootopt=64S3,32N2,64N2 erofs.reserved_pages=64 nosoftlockup log_buf_len=1M ignore_loglevel printk.devkmsg=on androidboot.load_modules_parallel=false
BOARD_KERNEL_IMAGE_NAME := Image

# Bootconfig
#
# load_modules_parallel: the stock bootconfig says true, but the vendor_boot image that is known
# to boot on this device overrides it to false on its kernel cmdline. With 341 ramdisk modules,
# matching the known-good value is not worth gambling on.
# NOTE: no comments inside the list below — this is a plain Make variable, so anything in it is
# concatenated verbatim into the image's bootconfig.
BOARD_BOOTCONFIG := \
    androidboot.hardware=qcom \
    androidboot.memcg=1 \
    androidboot.usbcontroller=a600000.dwc3 \
    androidboot.load_modules_parallel=false \
    androidboot.hypervisor.protected_vm.supported=true \
    androidboot.vendor.qspa=true \
    androidboot.serialconsole=0 \
    androidboot.selinux=enforcing

# Kernel
#
# The GKI Image is a genuine Google prebuilt (6.6.102-android15-8, ab14350911), which the charter
# permits for GKI devices. EVERYTHING else — 311 of the 313 vendor_dlkm modules, the whole
# vendor_boot ramdisk module set, dtb.img and dtbo.img — is generated from the Nothing GPL kernel
# source by kernel/stage_kernel_artifacts.sh into kernel/out/ (gitignored). See kernel/gki/README.md
# for why the GKI modules stay prebuilt, and kernel/prebuilt-modules/README.md for the 2 ST NFC
# modules Nothing has not published. Source tree is upstream/kernel_nothingoss_b16 (NOT
# kernel_nothingoss — that one is 6.6.57 and its modules are rejected at first stage).
#
# kernel/out/ must exist before a build: run kernel/stage_kernel_artifacts.sh first.
TARGET_KERNEL_VERSION := 6.6
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/kernel/gki/Image
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/kernel/out/dtb.img
TARGET_PREBUILT_KERNEL_HEADERS := $(DEVICE_PATH)/prebuilt/kernel-headers.tar.gz
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/kernel/out/dtbo.img

# vendor_boot and init_boot are BUILT, not pinned. The prebuilt pins that used to live here
# (metroid-kernel/{vendor_boot,init_boot}.img) meant the ramdisk module set could never change
# without hand-repacking an image.
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(wildcard $(DEVICE_PATH)/kernel/out/vendor_ramdisk/*.ko)
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(shell cat $(DEVICE_PATH)/modules.load.vendor_boot 2>/dev/null)
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(shell cat $(DEVICE_PATH)/modules.load.recovery 2>/dev/null)

BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_INIT_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)

# Partitions
BOARD_FLASH_BLOCK_SIZE := 262144 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_PVMFWIMAGE_PARTITION_SIZE := 1048576
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_DTBOIMG_PARTITION_SIZE := 50331648
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
BOARD_SUPER_PARTITION_SIZE := 9126805504 # TODO: Fix hardcoded value
BOARD_SUPER_PARTITION_GROUPS := qualcomm_dynamic_partitions
BOARD_QUALCOMM_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system_ext \
    system \
    vendor \
    vendor_dlkm \
    system_dlkm \
    odm \
    product
BOARD_QUALCOMM_DYNAMIC_PARTITIONS_SIZE := 9122611200 # TODO: Fix hardcoded value

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4

# vendor.img is built FROM SOURCE -- no BOARD_PREBUILT_VENDORIMAGE pin (2026-07-24).
#
# The pin used to live here with a comment blaming an "NDK31->NDK36 AIDL ABI skew" in the
# android.hardware.*-V{N}-ndk.so libs. That diagnosis was WRONG; do not resurrect it:
#   - The from-source -ndk.so libs export a strict SUPERSET of the prebuilt ones. The only
#     absent symbol is __cfi_check (cross-DSO CFI is off here), which is not a load failure.
#   - Intersecting the UND symbols of 10 proprietary consumer HALs against the from-source
#     libs gave ZERO unresolved symbols in every case. The size delta is .text codegen.
#   - aidl_api frozen versions all match; nothing builds as an unfrozen V{N+1}.
#   - The "only the -ndk.so libs differ" diff was bogus: it silently skipped /vendor/bin
#     (permission denied without sudo).
# The actual regression was /vendor/bin/hw/audiohalservice.qti going missing because
# `PRODUCT_PACKAGES += audiohalservice.qti` got commented out in device.mk, while its .rc and
# the audio.core VINTF fragment still shipped -> audioserver dies -> system_server crash loop
# The pin masked the source-build dependency chain because the
# pinned image was a Jul 8 build made while that line was still live.

TARGET_COPY_OUT_SYSTEM := system
TARGET_COPY_OUT_VENDOR := vendor

# Separate logical partitions (the OEM fstab mounts these at first-stage; do NOT flatten)
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_ODM := odm

BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs

# vendor_dlkm/system_dlkm: stock fstab first-stage-mounts these. They MUST be
# populated with the stock kernel-module set (see dlkm_modules.mk) -- shipping them
# empty drops the secure-side modules and hard-resets ~7-9s into boot.
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
BOARD_USES_VENDOR_DLKMIMAGE := true
BOARD_USES_SYSTEM_DLKMIMAGE := true
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := ext4

# Platform
TARGET_BOARD_PLATFORM := sun

# Properties
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Recovery
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
# NOTE: TARGET_RECOVERY_FSTAB is set once, below, to recovery.fstab. It used to be set
# here as well (to rootdir/etc/fstab.qcom) and silently overridden — last assignment wins.
TARGET_RECOVERY_QCOM_RTC_FIX := true
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true
# BOARD_HAS_NO_SELECT_BUTTON removed 2026-07-30: dead TWRP-era variable (zero references in
# build/, bootable/, vendor/lineage/ or system/core/), and it made the recovery key handling look
# configured when nothing read it. This device DOES have a select button — POWER, on pmic_pwrkey.
# The real reason recovery keys did not work was minui's MAX_DEVICES cap; see minui/events.cpp.
BOARD_SUPPRESS_SECURE_ERASE := true
RECOVERY_SDCARD_ON_DATA := true
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Recovery kernel modules: NONE — deliberately (2026-07-30).
#
# Every recovery that has ever booted on this device ships ZERO modules in the recovery ramdisk:
# stock, OrangeFox R11.3 (its 29 modules load from its own scripts, not first-stage), and our own
# June-era LOS recovery (extracted_20260620, booted with working UI/keys). Our broken builds were
# the only ones shipping first-stage modules (earlier 341, then 29 "curated" incl. qcom_q6v5_pas
# remoteproc and touch drivers). In recovery mode the recovery ramdisk's modules.dep also
# OVERWRITES the vendor_boot ramdisk's during ramdisk merge, corrupting first-stage module
# resolution. First-stage modules come from the vendor_boot ramdisk alone, as on stock.
# Do NOT re-add BOARD_RECOVERY_KERNEL_MODULES.


# Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_ALGORITHM := SHA256_RSA4096
BOARD_AVB_KEY_PATH := vendor/lineage-priv/keys/avb.pem
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true

BOARD_AVB_BOOT_KEY_PATH := vendor/lineage-priv/keys/avb.pem
BOARD_AVB_BOOT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_BOOT_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION := 3

BOARD_AVB_RECOVERY_KEY_PATH := vendor/lineage-priv/keys/avb.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

BOARD_AVB_VBMETA_SYSTEM := system system_ext product
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := vendor/lineage-priv/keys/avb.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

# The device has a real vbmeta_vendor partition and first-stage init verifies vendor/odm/
# vendor_dlkm/system_dlkm against it. Without this, the build emits no vbmeta_vendor.img, the
# on-device one keeps describing whatever vendor was flashed last, and ANY from-source vendor
# fails dm-verity in first_stage_mount -> init fatal -> reboot to bootloader ~15s in (looks
# exactly like a "from-source vendor crash-loop"; cost several sessions to find, 2026-07-24).
# This replaces the out-of-tree scripts/build_dlkmfix.sh, which hand-rolled the same vbmeta with
# `avbtool make_vbmeta_image --include_descriptors_from_image`.
BOARD_AVB_VBMETA_VENDOR := vendor vendor_dlkm system_dlkm odm
BOARD_AVB_VBMETA_VENDOR_KEY_PATH := vendor/lineage-priv/keys/avb.pem
BOARD_AVB_VBMETA_VENDOR_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX_LOCATION := 4

BOARD_AVB_VENDOR_DLKM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_VENDOR_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_SYSTEM_DLKM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256

# Hack: prevent anti rollback
#PLATFORM_SECURITY_PATCH := 2099-12-31
#VENDOR_SECURITY_PATCH := 2099-12-31
#PLATFORM_VERSION := 12
BOARD_USES_QCOM_FBE_DECRYPTION := true
BOARD_USES_METADATA_PARTITION := true

TARGET_USES_MKE2FS := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab

# Tools

# log
TARGET_USES_LOGD := true

# vendor_boot

# Statusbar icons flags

# Treble
PRODUCT_ENFORCE_VINTF_MANIFEST := true
PRODUCT_FULL_TREBLE := true

# VINTF
# manifest_audiocoreservices_qti.xml removed 2026-07-29: the audio core HAL package installs its
# own fragment (manifest_audiocorehal_default.xml), so listing it here declared
# android.hardware.audio.core IConfig/IModule twice and checkvintf rejected the whole device
# manifest ("Conflicting FqInstance"). Only `bacon` runs checkvintf — plain image builds do not —
# which is why this only surfaced when packaging the release zip.
DEVICE_MANIFEST_FILE := device/nothing/metroid/configs/hidl/manifest.xml

# Vendor board config (generated by setup-makefiles.sh)
-include vendor/nothing/metroid/BoardConfigVendor.mk
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += device/nothing/metroid/configs/hidl/compatibility_matrix.device.xml

# --- SEPolicy wiring (Opus 2026-07-07: fixes keymint/keystore2 InitFatalReboot @21s) ---
# QTI HAL service binaries (keymint/boot/fingerprint) were unlabeled ("rootfs") -> init
# refuses to exec them EVEN IN PERMISSIVE -> keystore2 crash-loop -> InitFatalReboot.
# platform=sun -> sm8750 QTI sepolicy labels keymint-service-qti vendor_hal_keymint_qti_exec.
include device/qcom/sepolicy_vndr/SEPolicy.mk
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/public
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/private

# --- 64-bit media stack (Opus 2026-07-10): 32-bit mediaserver/drmserver cannot exec
# on this 64-only device (zygote64) -> init 'Exec format error' loop -> Aperture blocks on
# media.resource_manager -> black camera preview. Flip both to 64-bit via soong_config.
TARGET_DYNAMIC_64_32_MEDIASERVER := true
TARGET_DYNAMIC_64_32_DRMSERVER := true
