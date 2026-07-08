#!/system/bin/sh
# ntcap v8: robust firmware mounts + ALWAYS-LATEST dmesg slot (reboot-robust) + early adb/probe at n=4
# v8 changes vs v7:
#   - write the freshest kernel log to a dedicated rawdump slot (1152+n%4) at the TOP of every
#     iteration, BEFORE the slow logcat section, so a mid-iteration ~15s reboot still leaves the
#     pre-reboot dmesg on disk (the main ring snapshot only lands at iteration END and is lost on
#     an interrupt). Harvest with: dd ... skip=256 count=48  (covers slots 1024..1215).
#   - move USB->adb flip and the vintf mapper probe from n=25 to n=4 so both happen before the reboot.
#   - lighter per-iteration timeouts so the ring cadence is faster.
BD=/dev/block/by-name/rawdump
BUF=/dev/ntcap_buf
ME=/dev/ntcap_mnterr
n=0
mnt() { # $1 fstype $2 opts $3 partbase $4 target
  grep -q " $4 " /proc/mounts && return 0
  for d in /dev/block/bootdevice/by-name /dev/block/by-name; do
    for s in _a ''; do
      [ -e "$d/$3$s" ] || continue
      mount -t "$1" -o "$2" "$d/$3$s" "$4" >>$ME 2>&1 && { echo "NTCAP mounted $4 from $d/$3$s" > /dev/kmsg; return 0; }
    done
  done
  return 1
}
while true; do
  n=$((n+1))
  UP=$(cat /proc/uptime 2>/dev/null)
  echo "NTCAP i=$n up=$UP" > /dev/kmsg 2>/dev/null
  # v8: always-latest kernel log to a dedicated rotating slot (1152..1155), reboot-robust
  { echo "NTCAP-DMESG iter=$n up=$UP"; timeout 2 dmesg 2>/dev/null | grep -v 'audit(' | tail -c 220000; } | dd of="$BD" bs=262144 seek=$((1152+(n%4))) conv=notrunc 2>/dev/null
  if [ "$n" -ge 2 ]; then
    mnt vfat ro,shortname=lower,uid=1000,gid=1000,dmask=227,fmask=337 modem /vendor/firmware_mnt
    mnt ext4 ro,nosuid,nodev dsp /vendor/dsp
    mnt vfat ro,shortname=lower,uid=1002,gid=3002,dmask=227,fmask=337 bluetooth /vendor/bt_firmware
    mnt ext4 noatime,nosuid,nodev persist /mnt/vendor/persist
  fi
  if [ "$n" = 4 ]; then
    setprop persist.sys.usb.config adb
    setprop sys.usb.config none
    sleep 1
    setprop sys.usb.config adb
  fi
  {
    echo "NTCAPRAW iter=$n up=$UP"
    getprop | grep -vE 'ro\.boottime|svc_debug'
    echo "== mounts =="; grep -E "firmware|dsp|persist" /proc/mounts
    echo "== probe =="
    if [ "$n" -ge 4 ]; then
      timeout 4 /system/bin/vintf dm > /dev/ntcap_vm 2>&1
      echo "vm-bytes: $(wc -c < /dev/ntcap_vm)"
      grep -B1 -A4 "mapper" /dev/ntcap_vm | head -14
      grep -cE "<hal" /dev/ntcap_vm
    fi
    echo probe-end
    echo "== mnterr =="; tail -c 2000 $ME 2>/dev/null
    echo "== dmesg tail =="; timeout 3 dmesg 2>/dev/null | grep -v 'audit(' | tail -c 70000
    echo "== logcat crash =="; timeout 3 /system/bin/logcat -d -b crash 2>/dev/null | tail -c 50000
    echo "== logcat tail =="; timeout 4 /system/bin/logcat -d -b main,system 2>/dev/null | grep -v 'audit(' | tail -c 88000
    echo "NTCAPRAW END iter=$n"
    echo ""
  } | head -c 262143 > "$BUF" 2>/dev/null
  if [ "$n" -le 64 ]; then
    dd if="$BUF" of="$BD" bs=262144 seek=$((1024+n-1)) conv=notrunc 2>/dev/null
  fi
  dd if="$BUF" of="$BD" bs=262144 seek=$((1088+(n%64))) conv=notrunc 2>/dev/null
  sleep 1
done
