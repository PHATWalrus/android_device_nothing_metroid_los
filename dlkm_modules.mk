# METROID: populate vendor_dlkm + system_dlkm with the stock prebuilt kernel-module
# set (verbatim: .ko plus modules.load/dep/alias/softdep/blocklist) so a clean
# `bacon`/`m` build produces BOOTABLE dlkm partitions.
#
# Background: these partitions are first-stage-mounted by the stock fstab. LineageOS
# builds them EMPTY (no BOARD_VENDOR_KERNEL_MODULES wiring), which dropped the whole
# vendor module set -- including the secure-side modules (tz_log_dlkm, spss_utils,
# qce50_dlkm, cdsprm, ...) -- and caused a hard secure/hypervisor reset ~7-9s into
# boot (kernel + system_server come up fine, then the device resets with no panic).
# The 07-20 "working" super was produced by a post-build hack (scripts/build_dlkmfix.sh)
# that repacked super with populated dlkm; this wires the same content into the build
# so the OTA/zip is self-contained and boots.
#
# Verbatim PRODUCT_COPY_FILES (no BOARD_VENDOR_KERNEL_MODULES) is intentional: it
# avoids the build's depmod re-processing so the exact stock module set + load order
# is preserved. /vendor/lib/modules already symlinks to /vendor_dlkm/lib/modules.

# 2026-07-28: this used to point at device/nothing/metroid-kernel — 309 MB of loose binaries
# checked in beside the device tree, not a git repo, not reproducible. It now points at the
# output of kernel/stage_kernel_artifacts.sh, which builds 306 of the 313 modules from the
# Nothing GPL kernel source. Run that script before building; kernel/out/ is gitignored.
METROID_KERNEL_DIR := $(LOCAL_PATH)/kernel/out

PRODUCT_COPY_FILES += \
    $(foreach f,$(wildcard $(METROID_KERNEL_DIR)/vendor_dlkm/*),\
        $(f):$(TARGET_COPY_OUT_VENDOR_DLKM)/lib/modules/$(notdir $(f)))

PRODUCT_COPY_FILES += \
    $(foreach f,$(wildcard $(METROID_KERNEL_DIR)/system_dlkm/*),\
        $(f):$(TARGET_COPY_OUT_SYSTEM_DLKM)/lib/modules/$(notdir $(f)))
