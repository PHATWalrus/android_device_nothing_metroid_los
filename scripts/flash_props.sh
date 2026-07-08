#!/bin/bash
exec > /tmp/flash_props.log 2>&1
FB=/home/logix/nothing_restore/platform-tools/fastboot
ADB=/home/logix/nothing_restore/platform-tools/adb
OUT=~/dev/metroid/lineage/out/target/product/metroid
MK=~/dev/metroid/lineage/device/nothing/metroid-kernel
S=000483574000895
D=~/dev/metroid/dumps/props_$(date +%H%M); mkdir -p "$D"
say(){ echo "[$(date +%H:%M:%S)] $*"; }
st(){ timeout 4 $ADB -s $S get-state </dev/null 2>/dev/null||true; }
sh(){ timeout 15 $ADB -s $S shell "$1" </dev/null 2>/dev/null; }

say "PHASE A: wait FASTBOOT"
for i in $(seq 1 300); do timeout 4 $FB devices 2>/dev/null|grep -qi fastboot && { say "fb @ $((i*5))s"; break; }; sleep 5; done
timeout 4 $FB devices 2>/dev/null|grep -qi fastboot || { echo "DONE NOFB"; exit 1; }
say "PHASE B: flash (keep /data)"
timeout 15 $FB set_active a 2>&1|tail -1
timeout 15 $FB erase misc 2>&1|tail -1
timeout 40 $FB flash init_boot "$MK/init_boot.img" 2>&1|tail -1
timeout 300 $FB flash super "$OUT/super_dlkmfix.img" 2>&1|tail -1
timeout 20 $FB flash vbmeta "$OUT/vbmeta.img" 2>&1|tail -1
timeout 20 $FB flash vbmeta_vendor "$OUT/vbmeta_vendor.img" 2>&1|tail -1
say "PHASE C: reboot; wait early-adb"
timeout 12 $FB reboot 2>&1|tail -1
UP=""
for i in $(seq 1 72); do s=$(st); [ "$s" = device ] && { UP=1; say "ADB @ $((i*5))s"; break; }; sleep 5; done
[ -z "$UP" ] && { echo "DONE NOADB"; exit 1; }
say "-- confirm props active --"
sh "getprop ro.hw_timeout_multiplier; getprop ro.keystore.boot_level_key.strategy; getprop odsign.verification.success"

say "PHASE D: watch for boot_completed (up to ~11 min; watchdog now 240s)"
DONE=""
for k in $(seq 1 22); do
  bc=$(sh "getprop sys.boot_completed"); sc=$(sh "getprop sys.system_server.start_count"); ba=$(sh "getprop init.svc.bootanim")
  say "  t=$((k*30))s boot_completed=[$bc] start_count=[$sc] bootanim=[$ba]"
  [ "$bc" = "1" ] && { DONE=1; say "!!!!!!!! BOOT_COMPLETED=1 — LAUNCHER REACHED !!!!!!!!"; break; }
  sleep 30
done
say "PHASE E: final state"
sh "getprop odsign.verification.success; ls /data/misc/apexdata/com.android.art/dalvik-cache/arm64/boot.art 2>&1"
sh "dumpsys activity activities 2>/dev/null | grep -iE 'ResumedActivity|topResumed' | head -3"
if [ -n "$DONE" ]; then
  say "-- WIN: capture launcher state --"
  sh "getprop sys.boot_completed; getprop init.svc.bootanim; getprop service.bootanim.exit; dumpsys window 2>/dev/null | grep -iE 'mCurrentFocus|mFocusedApp' | head"
else
  say "-- still not booted: last watchdog kill + main-thread block reason --"
  sh "logcat -d 2>/dev/null | grep -aE 'WATCHDOG KILLING|Blocked in handler|Watchdog' | tail -6"
fi
echo "DONE_PROPS ${DONE:-timeout} $D"
