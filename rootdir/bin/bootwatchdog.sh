#!/vendor/bin/sh
# BRING-UP ONLY. Force the device into fastboot if a boot never completes.
#
# Why not `setprop sys.powerctl` / `reboot`: both go through init. In the stalls we actually hit,
# init is itself blocked (e.g. waiting on vold, which waits on keystore), so it never processes the
# reboot request -- that is why earlier versions never fired. This bypasses init completely:
#   1. write "boot-recovery" into the BCB command field of /dev/block/by-name/misc
#      (struct bootloader_message: char command[32] at offset 0). VERIFIED on this device:
#      "bootonce-bootloader" is IGNORED by this bootloader and boots Android anyway;
#      "boot-recovery" reliably lands in LineageOS recovery (which has adb) in ~50s.
#   2. trigger an immediate kernel-level reboot via sysrq, which needs no userspace cooperation
# A healthy boot is ~200-310s, so 420s is the smallest safe timeout.
i=0
while [ $i -lt 84 ]; do
    [ "$(getprop sys.boot_completed)" = "1" ] && exit 0
    sleep 5
    i=$((i+1))
done

echo "bootwatchdog: boot did not complete in 420s -> forcing recovery (adb reachable there)" > /dev/kmsg

# 1. arm the bootloader control block (32-byte command field, zero-padded)
MISC=/dev/block/by-name/misc
if [ -e "$MISC" ]; then
    dd if=/dev/zero of=$MISC bs=32 count=1 conv=notrunc 2>/dev/null
    printf 'boot-recovery\0' | dd of=$MISC bs=32 count=1 conv=notrunc,sync 2>/dev/null
    sync
fi

# 2. kernel-level reboot -- does not depend on init being responsive
echo 1 > /proc/sys/kernel/sysrq 2>/dev/null
sync
echo b > /proc/sysrq-trigger 2>/dev/null

# 3. last-resort fallbacks if sysrq is unavailable
setprop sys.powerctl reboot,bootloader 2>/dev/null
sleep 15
reboot bootloader 2>/dev/null
