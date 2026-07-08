#!/bin/bash
exec > /tmp/capture_adb.log 2>&1
FB=/home/logix/nothing_restore/platform-tools/fastboot
ADB=/home/logix/nothing_restore/platform-tools/adb
OUT=~/dev/metroid/lineage/out/target/product/metroid
MK=~/dev/metroid/lineage/device/nothing/metroid-kernel
S=000483574000895
D=~/dev/metroid/dumps/adb_$(date +%H%M); mkdir -p "$D"
say(){ echo "[$(date +%H:%M:%S)] $*"; }
st(){ timeout 4 $ADB -s $S get-state </dev/null 2>/dev/null||true; }

say "PHASE A: waiting up to 25min for FASTBOOT (button-hold to fastboot)..."
for i in $(seq 1 300); do timeout 4 $FB devices 2>/dev/null|grep -qi fastboot && { say "fastboot @ $((i*5))s"; break; }; sleep 5; done
timeout 4 $FB devices 2>/dev/null|grep -qi fastboot || { say NO_FB; echo "CAP_DONE NOFB"; exit 1; }

say "PHASE B: flash super + vbmeta_vendor (+ stock init_boot)"
timeout 15 $FB set_active a 2>&1|tail -1
timeout 15 $FB erase misc 2>&1|tail -1
timeout 40 $FB flash init_boot "$MK/init_boot.img" 2>&1|tail -1
timeout 300 $FB flash super "$OUT/super_dlkmfix.img" 2>&1|tail -1
timeout 20 $FB flash vbmeta "$OUT/vbmeta.img" 2>&1|tail -1
timeout 20 $FB flash vbmeta_vendor "$OUT/vbmeta_vendor.img" 2>&1|tail -1

say "PHASE C: reboot; waiting for EARLY-ADB to come up during boot (~5min)..."
timeout 12 $FB reboot 2>&1|tail -1
UP=""
for i in $(seq 1 60); do
  s=$(st); echo "[t=$((i*5))s] state=${s:-none}"
  [ "$s" = device ] && { UP=1; say "!!! ADB DEVICE @ $((i*5))s !!!"; break; }
  [ "$s" = recovery ] && { say "came up as recovery?!"; break; }
  sleep 5
done
[ -z "$UP" ] && { say "EARLY-ADB FAILED (no adb in 300s)"; echo "CAP_DONE NOADB"; exit 1; }

say "PHASE D: LIVE DIAGNOSIS"
timeout 12 $ADB -s $S root </dev/null 2>&1 | tail -1; sleep 4
for i in $(seq 1 12); do [ "$(st)" = device ] && break; sleep 3; done
say "-- boot stage --"
timeout 10 $ADB -s $S shell "getprop sys.boot_completed; getprop dev.bootcomplete; getprop init.svc.zygote; getprop init.svc.surfaceflinger; getprop sys.init_log_level; getprop ro.boottime.init" </dev/null 2>/dev/null | tee "$D/bootstage.txt"
say "-- processes of interest --"
timeout 10 $ADB -s $S shell "ps -A -o PID,USER,NAME 2>/dev/null | grep -iE 'system_server|zygote|surfaceflinger|bootanim|servicemanager|vold|keystore'" </dev/null 2>/dev/null | tee "$D/ps.txt"
SSPID=$(timeout 10 $ADB -s $S shell "pgrep -f -n system_server" </dev/null 2>/dev/null | tr -d '\r ' | head -1)
say "system_server pid=$SSPID"
say "-- dmesg --"; timeout 15 $ADB -s $S exec-out "dmesg" </dev/null 2>/dev/null > "$D/dmesg.txt"
say "-- logcat -b all -d --"; timeout 40 $ADB -s $S exec-out "logcat -b all -d -v threadtime" </dev/null 2>/dev/null > "$D/logcat.txt"
echo "logcat lines: $(wc -l < "$D/logcat.txt" 2>/dev/null)"
if [ -n "$SSPID" ]; then
  say "-- system_server wchan / state --"
  timeout 10 $ADB -s $S shell "echo wchan=\$(cat /proc/$SSPID/wchan); echo state=\$(cut -d' ' -f3 /proc/$SSPID/stat)" </dev/null 2>/dev/null
  say "-- JAVA thread dump (debuggerd -j) --"
  timeout 40 $ADB -s $S exec-out "debuggerd -j $SSPID" </dev/null 2>/dev/null > "$D/ss_java.txt"
  echo "java dump lines: $(wc -l < "$D/ss_java.txt" 2>/dev/null)"
fi

say "PHASE E: analysis"
echo "===== BOOT STAGE ====="; cat "$D/bootstage.txt"
echo "===== logcat TAIL 50 ====="; tail -50 "$D/logcat.txt"
echo "===== logcat: wait/timeout/ANR/fatal/keystore/vold/PackageManager ====="
grep -iE "waiting|timed? ?out|not responding|ANR |FATAL|exception|unable to|failed to|retry|keystore|vold|mount|PackageManager|SystemServer|Watchdog|boot animation|BootAnim" "$D/logcat.txt" 2>/dev/null | tail -60
echo "===== system_server JAVA main thread ====="
awk '/\"main\"/{p=1} p{print} /^$/{if(p)c++} c>1{exit}' "$D/ss_java.txt" 2>/dev/null | head -45
echo "===== blocked/waiting java threads ====="
grep -iE "Blocked|Waiting|native=|nativePollOnce|Binder:|held by|waiting to lock|waiting on" "$D/ss_java.txt" 2>/dev/null | head -40
echo "CAP_DONE OK $D"
