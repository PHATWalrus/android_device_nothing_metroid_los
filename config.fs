[AID_VENDOR_QTI_DIAG]
value:2901

[AID_VENDOR_QDSS]
value:2902

[AID_VENDOR_RFS]
value:2903

[AID_VENDOR_RFS_SHARED]
value:2904

[AID_VENDOR_ADPL_ODL]
value:2905

[AID_VENDOR_QRTR]
value:2906

[AID_VENDOR_THERMAL]
value:2907

[AID_VENDOR_FASTRPC]
value:2908

[AID_VENDOR_QTR]
value:2909

[AID_VENDOR_NXP_STRONGBOX]
value:2910

[AID_VENDOR_NXP_WEAVER]
value:2911

[AID_VENDOR_SSGTZD]
value:2912

[AID_VENDOR_THALES_STRONGBOX]
value:2913

[AID_VENDOR_QCC]
value:2914

[AID_VENDOR_NXP_AUTHSECRET]
value:2915

[AID_VENDOR_THALES_WEAVER]
value:2916

[AID_VENDOR_THALES_AUTHSECRET]
value:2917

# Mountpoint directories for rootdir/etc/fstab.qcom.
# These are EMPTY dirs. build_image drives the image from fs_config, so an empty directory with no
# fs_config entry is dropped -- the mount then fails silently, /vendor/firmware_mnt stays empty, the
# adsp/cdsp/mss/wpss remoteprocs never find their .mdt firmware and never boot, and the device comes
# up with NO wifi interface, 1 sensor and no baseband. The reference vendor image ships all three as
# real directories. Declaring them here makes the image contain them.
[vendor/firmware_mnt]
mode: 0755
user: AID_ROOT
group: AID_ROOT
caps: 0

[vendor/dsp]
mode: 0755
user: AID_ROOT
group: AID_ROOT
caps: 0

[vendor/bt_firmware]
mode: 0755
user: AID_ROOT
group: AID_ROOT
caps: 0
