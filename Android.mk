LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := qts_ko_recovery
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_STEM := qts.ko
LOCAL_MODULE_PATH := $(TARGET_RECOVERY_ROOT_OUT)/vendor/lib/modules
LOCAL_SRC_FILES := ../../../vendor/nothing/metroid/proprietary/vendor_dlkm/lib/modules/qts.ko
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := focaltech_tp_ko_recovery
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_STEM := focaltech_tp.ko
LOCAL_MODULE_PATH := $(TARGET_RECOVERY_ROOT_OUT)/vendor/lib/modules
LOCAL_SRC_FILES := ../../../vendor/nothing/metroid/proprietary/vendor_dlkm/lib/modules/focaltech_tp.ko
include $(BUILD_PREBUILT)
