DEVICE_PATH := device/nothing/metroid

# Required by the current imageless first-boot path.
WITH_DEXPREOPT := false

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    init_boot \
    odm \
    product \
    pvmfw \
    recovery \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    vendor \
    vendor_boot \
    vendor_dlkm

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo300

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

# Custom Android IDs and capabilities used by vendor services.
TARGET_FS_CONFIG_GEN := $(DEVICE_PATH)/configs/config.fs

# Kernel
BOARD_BOOT_HEADER_VERSION := 4
BOARD_INIT_BOOT_HEADER_VERSION := 4
BOARD_RAMDISK_USE_LZ4 := true
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_TAGS_OFFSET := 0x00000100
BOARD_DTB_OFFSET := 0x01f00000
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 erofs.reserved_pages=64 nosoftlockup log_buf_len=1M ignore_loglevel printk.devkmsg=on androidboot.init_fatal_reboot_target=recovery androidboot.selinux=permissive
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_USES_GENERIC_KERNEL_IMAGE := true

# Bootconfig
BOARD_BOOTCONFIG := \
    androidboot.hardware=qcom \
    androidboot.memcg=1 \
    androidboot.usbcontroller=a600000.dwc3 \
    androidboot.load_modules_parallel=true \
    androidboot.hypervisor.protected_vm.supported=true \
    androidboot.vendor.qspa=true \
    androidboot.serialconsole=0 \
    androidboot.selinux=permissive

# Kernel - prebuilt
TARGET_KERNEL_VERSION := 6.6
TARGET_KERNEL_SOURCE := kernel/nothing/sm8735
TARGET_KERNEL_CONFIG := gki_defconfig vendor/sun_perf.config vendor/Metroid.config
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
TARGET_PREBUILT_DTB := $(DEVICE_PATH)/prebuilt/dtb.img
TARGET_PREBUILT_KERNEL_HEADERS := $(DEVICE_PATH)/prebuilt/kernel-headers.tar.gz
BOARD_PREBUILT_BOOTIMAGE := device/nothing/metroid-kernel/boot.img
BOARD_PREBUILT_DTBOIMAGE := device/nothing/metroid-kernel/dtbo.img
BOARD_PREBUILT_INIT_BOOT_IMAGE := device/nothing/metroid-kernel/init_boot.img
BOARD_PREBUILT_VENDOR_BOOTIMAGE := device/nothing/metroid-kernel/vendor_boot.img

BOARD_MKBOOTIMG_ARGS += --dtb $(TARGET_PREBUILT_DTB)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_MKBOOTIMG_INIT_ARGS += --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)

# Partitions
BOARD_FLASH_BLOCK_SIZE := 262144 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_DTBOIMG_PARTITION_SIZE := 50331648
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
BOARD_PVMFWIMAGE_PARTITION_SIZE := 1048576
BOARD_SUPER_PARTITION_SIZE := 9126805504
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system_ext \
    system \
    vendor \
    vendor_dlkm \
    system_dlkm \
    odm \
    product
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 9122611200

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs

TARGET_COPY_OUT_SYSTEM := system
TARGET_COPY_OUT_VENDOR := vendor

# Separate logical partitions mounted during first stage.
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_ODM := odm

BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs

# Stock prebuilt modules are installed from the extracted DLKM trees.
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
BOARD_USES_VENDOR_DLKMIMAGE := true
BOARD_USES_SYSTEM_DLKMIMAGE := true
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs

METROID_VENDOR_DLKM_MODULE_DIR := vendor/nothing/metroid/proprietary/vendor_dlkm/lib/modules
METROID_SYSTEM_DLKM_MODULE_DIR := vendor/nothing/metroid/proprietary/system_dlkm/lib/modules

BOARD_VENDOR_KERNEL_MODULES := $(wildcard $(METROID_VENDOR_DLKM_MODULE_DIR)/*.ko)
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(METROID_VENDOR_DLKM_MODULE_DIR)/modules.load))
BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(METROID_VENDOR_DLKM_MODULE_DIR)/modules.blocklist
BOARD_DO_NOT_STRIP_VENDOR_MODULES := true

BOARD_SYSTEM_KERNEL_MODULES := $(wildcard $(METROID_SYSTEM_DLKM_MODULE_DIR)/*.ko)

# Properties
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Security
BOOT_SECURITY_PATCH := 2025-09-05
VENDOR_SECURITY_PATCH := 2026-04-05

# Recovery
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_AVB_ALGORITHM := SHA256_RSA4096
BOARD_AVB_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true

BOARD_AVB_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_BOOT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_BOOT_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION := 3

BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

BOARD_AVB_VBMETA_SYSTEM := system system_ext product pvmfw
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

BOARD_AVB_VBMETA_VENDOR := odm system_dlkm vendor vendor_dlkm
BOARD_AVB_VBMETA_VENDOR_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_VENDOR_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX_LOCATION := 4

BOARD_AVB_VENDOR_DLKM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_VENDOR_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_SYSTEM_DLKM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256

BOARD_USES_METADATA_PARTITION := true

# Treble
PRODUCT_ENFORCE_VINTF_MANIFEST := true
PRODUCT_FULL_TREBLE := true

# VINTF
DEVICE_MANIFEST_FILE := device/nothing/metroid/configs/hidl/manifest.xml hardware/qcom-caf/sm8750/audio/primary-hal/hal/core/manifest_audiocoreservices_qti.xml

# Vendor board config (generated by setup-makefiles.sh)
-include vendor/nothing/metroid/BoardConfigVendor.mk
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += device/nothing/metroid/configs/hidl/compatibility_matrix.device.xml

# SEPolicy
include device/qcom/sepolicy_vndr/SEPolicy.mk
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
