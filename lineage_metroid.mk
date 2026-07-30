# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Inherit from metroid device
$(call inherit-product, device/nothing/metroid/device.mk)

# Sign with our own release keys, not AOSP's public testkey (anyone can forge updates for that).
$(call inherit-product-if-exists, vendor/lineage-priv/keys/keys.mk)

PRODUCT_NAME := lineage_metroid
PRODUCT_DEVICE := metroid
PRODUCT_MANUFACTURER := Nothing
PRODUCT_BRAND := Nothing
PRODUCT_MODEL := Phone (3)

PRODUCT_GMS_CLIENTID_BASE := android-nothing
PRODUCT_SHIPPING_API_LEVEL := 36
