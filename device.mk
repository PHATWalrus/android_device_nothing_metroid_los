LOCAL_PATH := device/nothing/metroid

# Keep the kernel monorepo out of Soong module discovery; it is built separately.
PRODUCT_SOURCE_ROOT_DIRS += -kernel/nothing/sm8735

# A/B
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

PRODUCT_BUILD_FASTBOOT_PACKAGE := true

# Generic ramdisk
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)

BOARD_SHIPPING_API_LEVEL := 202404

# Temporary boot diagnostics used by the known-good baseline.
PRODUCT_PRODUCT_PROPERTIES += \
    init.svc_debug.no_fatal.boot-hal-1-2=true

PRODUCT_PROPERTY_OVERRIDES += \
    ro.adb.secure=0

# Zygote reads these values from the system partition during early boot.
PRODUCT_SYSTEM_PROPERTIES += \
    dalvik.vm.heapstartsize=16m \
    dalvik.vm.heapgrowthlimit=256m \
    dalvik.vm.heapsize=512m \
    dalvik.vm.heaptargetutilization=0.5 \
    dalvik.vm.heapminfree=8m \
    dalvik.vm.heapmaxfree=32m

# Boot control
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=erofs \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script
# Fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot-service.example_recovery \
    fastbootd

# Health
PRODUCT_PACKAGES += \
    android.hardware.health-service.qti \
    android.hardware.health-service.qti_recovery

# Partitions
PRODUCT_BUILD_PVMFW_IMAGE := true
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_BUILD_VENDOR_BOOT_IMAGE := false

# Android Virtualization Framework
$(call inherit-product, packages/modules/Virtualization/build/apex/product_packages.mk)

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Recovery init scripts
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/init.recovery.aosp.rc:recovery/root/init.recovery.aosp.rc \
    $(LOCAL_PATH)/rootdir/etc/init.recovery.qcom.rc:recovery/root/init.recovery.qcom.rc \
    vendor/nothing/metroid/proprietary/vendor/firmware/focaltech_ts_fw_boe.bin:recovery/root/vendor/firmware/focaltech_ts_fw_boe.bin

PRODUCT_PACKAGES += \
    qts_ko_recovery \
    focaltech_tp_ko_recovery

PRODUCT_SYSTEM_EXT_PROPERTIES += \
    ro.minui.blacklist_input_devices=aw9380x_0_ch11

# HAL source namespaces
PRODUCT_SOONG_NAMESPACES += \
    hardware/qcom-caf/sm8750/display \
    hardware/qcom-caf/thermal

PRODUCT_PACKAGES += \
    android.hardware.thermal-service.qti \
    android.hardware.usb-service.qti \
    android.hardware.usb.gadget-service.qti \
    vndservicemanager

# The stock Wi-Fi service requires the vendor hostapd interface and libxml2.
PRODUCT_PACKAGES += \
    android.hardware.wifi.hostapd-V2-ndk \
    firmware_WCNSS_qcom_cfg.ini_symlink \
    firmware_wlan_mac.bin_symlink \
    firmware_wlanmdsp.otaupdate_symlink \
    libxml2.vendor \
    wpa_cli \
    wpa_supplicant

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/android.hardware.wifi-service.metroid.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/android.hardware.wifi-service.metroid.rc \
    $(LOCAL_PATH)/rootdir/etc/zz.init.metroid.vibrator.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/zz.init.metroid.vibrator.rc

# Display
PRODUCT_PACKAGES += \
    android.hardware.graphics.composer3-V3-ndk.vendor \
    android.hardware.graphics.mapper@4.0-impl-qti-display \
    vendor.qti.hardware.display.aiqe-V2-ndk.vendor \
    vendor.qti.hardware.display.allocator-service \
    vendor.qti.hardware.display.composer-service \
    vendor.qti.hardware.display.composer3-V1-ndk.vendor \
    vendor.qti.hardware.display.config-V12-ndk.vendor \
    vendor.qti.hardware.display.demura-service \
    vendor.qti.hardware.display.snapalloc-impl

# Boot control and proprietary interface dependencies
PRODUCT_PACKAGES += \
    android.frameworks.cameraservice.common-V1-ndk \
    android.hardware.bluetooth.finder-V1-ndk \
    android.hardware.boot-service.qti \
    android.hardware.boot-service.qti.recovery \
    android.hardware.health-V1-ndk \
    android.hardware.radio-V2-ndk \
    android.hardware.radio.data-V2-ndk \
    android.hardware.radio.network-V2-ndk \
    android.hardware.radio.sim-V3-ndk \
    android.hardware.radio@1.2.vendor \
    android.hardware.radio@1.3.vendor \
    android.hardware.radio@1.4.vendor \
    android.hardware.sensors@2.1.vendor \
    android.media.audio.common.types-V2-cpp \
    libcodec2_aidl \
    libcodec2_vndk \
    libkeymaster_messages \
    librmnetctl \
    rmnetcli

# Frozen VNDK required by the stock vendor interface.
PRODUCT_PACKAGES += \
    com.android.vndk.v34

# Proprietary vendor blobs
$(call inherit-product-if-exists, vendor/nothing/metroid/metroid-vendor.mk)

PRODUCT_PACKAGES += \
    GlyphNotification \
    Leveler \
    Magicball \
    NothingToy \
    NtThirdParty

# Vendor fstab
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.qcom:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.qcom

# Audio policy configurations
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    $(LOCAL_PATH)/configs/audio/audio_module_config_primary.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_module_config_primary.xml \
    vendor/nothing/metroid/proprietary/vendor/etc/audio/sku_tuna/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    vendor/nothing/metroid/proprietary/vendor/etc/audio/sku_tuna/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    vendor/nothing/metroid/proprietary/vendor/etc/audio/sku_tuna/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml
# VINTF fragments
PRODUCT_PACKAGES += \
    audio_effects.metroid.xml \
    audio_qti_services.metroid.xml \
    camera_provider.metroid.xml \
    com.nothing.camera.postproc-impl.xml \
    hal_batch1.metroid.xml \
    hal_batch2.metroid.xml \
    hal_batch3.metroid.xml \
    vendor.noth.hardware.camera-service.xml \
    vendor.qti.camera.aon-impl.xml \
    vendor.qti.camera.offlinecamera-impl.xml \
    wifi-service.metroid.xml

PRODUCT_PACKAGES += \
    android.hardware.radio.config.metroid4.xml \
    android.hardware.radio.data.metroid4.xml \
    android.hardware.radio.messaging.metroid4.xml \
    android.hardware.radio.modem.metroid4.xml \
    android.hardware.radio.network.metroid4.xml \
    android.hardware.radio.sim.metroid4.xml \
    android.hardware.radio.voice.metroid4.xml

# Compile policy from CIL at boot because the stock init image ignores ODM precompiled policy.
PRODUCT_PRECOMPILED_SEPOLICY := false

# The first boot uses imageless ART and the TEE rejects EARLY_BOOT_ONLY keys.
PRODUCT_SYSTEM_PROPERTIES += \
    ro.hw_timeout_multiplier=4 \
    ro.keystore.boot_level_key.strategy=TRUSTED_ENVIRONMENT:MAX_USES_PER_BOOT

# Audio
PRODUCT_PACKAGES += \
    audiohalservice.qti

DEVICE_PACKAGE_OVERLAYS += device/nothing/metroid/overlay
# The stock Morpho EIS library faults on this userspace; use the QTI GME path.
PRODUCT_VENDOR_PROPERTIES += \
    persist.vendor.morpho.eis.force_gmenode=1
