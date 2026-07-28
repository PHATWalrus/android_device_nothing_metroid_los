# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from metroid device.
$(call inherit-product, device/nothing/metroid/device.mk)

# Bring-up only: trust every USB ADB host for every build variant.
# Remove before producing release builds.
WITH_ADB_INSECURE := true

# Inherit Lineage configuration.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

SOONG_CONFIG_qtidisplay += stock_composer
SOONG_CONFIG_qtidisplay_stock_composer := true

SOONG_CONFIG_NAMESPACES += metroid
SOONG_CONFIG_metroid += use_stock_peripheral_state_utils use_stock_vibrator
SOONG_CONFIG_metroid_use_stock_peripheral_state_utils := true
SOONG_CONFIG_metroid_use_stock_vibrator := true

PRODUCT_NAME := lineage_metroid
PRODUCT_DEVICE := metroid
PRODUCT_MANUFACTURER := Nothing
PRODUCT_BRAND := Nothing
PRODUCT_MODEL := Phone (3)

PRODUCT_GMS_CLIENTID_BASE := android-nothing
PRODUCT_SHIPPING_API_LEVEL := 35

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="qssi_64-user 16 BQ2A.250721.001-BP2A.250605.031.A3 2606241457 release-keys" \
    BuildFingerprint=Nothing/Metroid/Metroid:15/AQ3A.250728.001/2606241457:user/release-keys \
    DeviceName=Metroid \
    DeviceProduct=Metroid \
    SystemDevice=Metroid \
    SystemName=Metroid
