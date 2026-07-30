#!/usr/bin/env bash
# Stage the source-built kernel artifacts the platform build consumes.
#
# WHAT THIS REPLACES
# ------------------
# device/nothing/metroid-kernel/ used to be 309 MB of loose binaries checked in next to the
# device tree: 313 .ko, dtbo.img, vendor_boot.img, init_boot.img. None of it was reproducible.
# This script regenerates all of it from the Nothing GPL kernel source instead.
#
# Coverage as of 2026-07-28: 306 of the 313 shipped vendor_dlkm modules build from source.
# The other 7 have no published source — see prebuilt-modules/README.md.
#
# The GKI Image itself stays a prebuilt: it is a genuine Google GKI
# (6.6.102-android15-8-gab8eb70a71b8-ab14350911-4k, kleaf@build-host), which the LineageOS
# charter explicitly permits for GKI devices ("GKI devices MAY use ... a prebuilt GKI image
# from Google, but MUST build all feasible modules from source"). Shipping our own 6.6.142
# build instead would gain nothing and risks diverging from the firmware the device shipped with.
#
# Usage:
#   stage_kernel_artifacts.sh [kernelws-dir] [out-dir]
# Defaults:
#   kernelws = <this repo>/../../../../kernelws
#   out      = <device>/kernel/out          (gitignored; regenerate, do not commit)
#
# Prerequisite — build the kernel first (~15 min cold, seconds warm):
#   cd kernelws
#   build/kernel/kleaf/bazel.sh build --noenable_bzlmod --keep_going \
#       --//vendor/qcom/opensource/camera-kernel:project_name=sun \
#       --target_pattern_file=<...>/vendor_mod_targets.txt
#
# The camera project_name flag is not optional: without it camera.ko fails to compile with
# "redefinition of 'qcom_scm_camera_qos'", because CONFIG_SPECTRA_SECURE_CAMNOC_REG_UPDATE is
# only set for the sun project and cam_compat.h redefines a struct the kernel already provides.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DEVICE="$(dirname "$HERE")"
KWS="${1:-$(cd "$DEVICE/../../../.." && pwd)/kernelws}"
OUT="${2:-$HERE/out}"

STRIP="$KWS/prebuilts/clang/host/linux-x86/clang-r510928/bin/llvm-strip"
# The module set to reproduce, and the curated load-order/blocklist files that go with it. Both
# are checked in: they come from the shipped image and are the contract first-stage init expects,
# not a wish list. Keeping them as text here is what let device/nothing/metroid-kernel go away.
VENDOR_DLKM_LIST="$HERE/modules.vendor_dlkm"
VENDOR_DLKM_META="$HERE/vendor_dlkm-meta"
# Names that live in system_dlkm — modules.dep must point at /system/lib/modules for these.
SYSTEM_DLKM_LIST="$OUT/system_dlkm_names.txt"

# Source not published by Nothing — carried as pinned prebuilts. See prebuilt-modules/README.md.
# Only the two ST NFC drivers, as of 2026-07-28. This list was five entries longer until the build
# was pointed at the correct kernel tree: aw882xx_dlkm, nothing_performance, nothing_rdump,
# rpmb_state and spmi-pmic-err-debug are all present in upstream/kernel_nothingoss_b16 and now
# build from source.
UNPUBLISHED="stm_nfc_i2c stm_st54se_gpio"

[[ -x "$STRIP" ]] || { echo "!! llvm-strip not found at $STRIP" >&2; exit 1; }
[[ -d "$KWS/bazel-bin" ]] || { echo "!! no bazel-bin in $KWS — build the kernel first" >&2; exit 1; }

echo ":: staging into $OUT"
rm -rf "$OUT"
mkdir -p "$OUT/vendor_dlkm" "$OUT/system_dlkm"

# Index every .ko the kernel build produced. Skip unstripped/ and bazel runfiles trees, which
# hold duplicates of the same modules and would make "first match wins" nondeterministic.
declare -A KO
while IFS= read -r f; do
    n="$(basename "$f")"
    [[ -n "${KO[$n]:-}" ]] || KO["$n"]="$f"
done < <(find "$KWS/bazel-bin/vendor" \
              "$KWS/bazel-bin/msm-kernel/sun_perf" \
              "$KWS/bazel-bin/common/kernel_aarch64" \
              -name '*.ko' -not -path '*/unstripped/*' -not -path '*runfiles*' 2>/dev/null)
echo ":: kernel build produced ${#KO[@]} distinct modules"

# One stripped copy of everything, plus the pinned prebuilts. vendor_dlkm and the vendor_boot
# ramdisk are both drawn from here by hardlink, and depmod runs over this superset so the
# dependency closure is computed against every module that exists — not just the ones already
# selected. (Doing the closure over vendor_dlkm alone reports ~117 false "missing": the
# msm-kernel in-tree modules — pinctrl, clk, ufs, iommu, gunyah — live only in the ramdisk.)
mkdir -p "$OUT/all"
for n in "${!KO[@]}"; do
    "$STRIP" --strip-debug "${KO[$n]}" -o "$OUT/all/$n"
done
for base in $UNPUBLISHED; do
    cp -a "$HERE/prebuilt-modules/$base.ko" "$OUT/all/$base.ko"
done

stage_set() {  # <module name list> <dest dir> <label>
    local list="$1" dst="$2" label="$3"
    local built=0 pinned=0 missing=0
    local n base
    while read -r n; do
        [[ -n "$n" ]] || continue
        base="${n%.ko}"
        if [[ " $UNPUBLISHED " == *" $base "* ]]; then
            cp -a "$HERE/prebuilt-modules/$n" "$dst/$n"
            pinned=$((pinned + 1))
        elif [[ -n "${KO[$n]:-}" ]]; then
            # --strip-debug, not --strip-all: .modinfo and __versions must survive or the
            # module loses its vermagic/CRCs and the kernel refuses to load it.
            "$STRIP" --strip-debug "${KO[$n]}" -o "$dst/$n"
            built=$((built + 1))
        else
            echo "   !! no source-built module for $n"
            missing=$((missing + 1))
        fi
    done < "$list"
    echo ":: $label: $built from source, $pinned pinned prebuilt, $missing missing"
    [[ $missing -eq 0 ]] || return 1
}

stage_set "$VENDOR_DLKM_LIST" "$OUT/vendor_dlkm" "vendor_dlkm"

# system_dlkm is NOT built here: those modules belong to the GKI release, and we ship Google's
# prebuilt GKI Image. Our own //common:kernel_aarch64 is android15-6.6 HEAD with a different
# gki_defconfig (no CONFIG_TLS, so no tls.ko this device loads) — pairing our GKI modules with
# Google's vmlinux would be strictly worse than shipping the matched set. See gki/README.md.
cp -a "$HERE/gki/system_dlkm/." "$OUT/system_dlkm/"
ls "$OUT/system_dlkm"/*.ko | xargs -n1 basename > "$SYSTEM_DLKM_LIST"
echo ":: system_dlkm: $(wc -l < "$SYSTEM_DLKM_LIST") pinned Google GKI modules"

# modules.load / blocklist are curated boot-order lists, not build output — carry them over.
# modules.dep/alias/softdep ARE derived, and must be regenerated: a source-built module can
# have a different dependency set than the stock one, and a stale modules.dep silently breaks
# module load ordering at first stage.
for f in modules.load modules.load.recovery modules.blocklist; do
    [[ -f "$VENDOR_DLKM_META/$f" ]] && cp -a "$VENDOR_DLKM_META/$f" "$OUT/vendor_dlkm/$f"
done

regen_depmod() {  # <dir>
    local dir="$1" tmp
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/lib/modules/0.0"
    cp "$dir"/*.ko "$tmp/lib/modules/0.0/"
    depmod -b "$tmp" -a 0.0 2>/dev/null || true
    local n
    for n in modules.dep modules.alias modules.softdep; do
        [[ -s "$tmp/lib/modules/0.0/$n" ]] || continue
        if [[ "$n" == "modules.dep" ]]; then
            # modules.dep must carry ABSOLUTE on-device paths, and modules that live in
            # system_dlkm must point at /system/lib/modules — exactly as the stock file does:
            #   /vendor/lib/modules/qca_cld3_wcn7750.ko: ... /vendor/lib/modules/cfg80211.ko \
            #       /system/lib/modules/rfkill.ko ...
            #
            # This used to rewrite every path to a bare filename ("the device expects flat
            # names"), which was simply wrong and cost a day: modprobe could not resolve
            # rfkill (it is in system_dlkm, not vendor_dlkm), so cfg80211 never loaded, so
            # qca_cld3_wcn7750 never loaded, so the Wi-Fi HAL failed with "Failed to load WiFi
            # driver" and wlan0 never appeared. The same broke bluetooth's btpower/btfm.
            python3 - "$tmp/lib/modules/0.0/$n" "$SYSTEM_DLKM_LIST" > "$dir/$n" <<'PYEOF'
import os, re, sys
depfile, sysdlkm_list = sys.argv[1], sys.argv[2]
sysmods = set()
if os.path.exists(sysdlkm_list):
    sysmods = {l.strip() for l in open(sysdlkm_list) if l.strip()}
def fix(tok):
    base = os.path.basename(tok)
    root = "/system/lib/modules" if base in sysmods else "/vendor/lib/modules"
    return f"{root}/{base}"
for line in open(depfile):
    line = line.rstrip("\n")
    if ":" not in line:
        continue
    mod, deps = line.split(":", 1)
    out = fix(mod) + ":"
    d = [fix(x) for x in deps.split()]
    if d:
        out += " " + " ".join(d)
    print(out)
PYEOF
        else
            cp -a "$tmp/lib/modules/0.0/$n" "$dir/$n"
        fi
    done
    rm -rf "$tmp"
}

echo ":: regenerating modules.dep/alias/softdep"
regen_depmod "$OUT/vendor_dlkm"

# ---------------------------------------------------------------------------
# vendor_boot ramdisk module set
#
# The platform build packs BOARD_VENDOR_RAMDISK_KERNEL_MODULES into vendor_boot and runs its own
# depmod, so it needs the *dependency closure* of the two load lists, not just the listed modules.
# The shipped ramdisk carries 339 modules for 334 listed ones — the extra five (cfg80211, mac80211,
# hdcp_qseecom_dlkm, smmu_proxy_dlkm, tz_log_dlkm) are pulled in only as dependencies. Computing
# the closure here rather than hardcoding it means the set stays correct if a load list changes.
echo ":: computing vendor_boot ramdisk module set"
mkdir -p "$OUT/vendor_ramdisk" "$OUT/all_meta"
regen_depmod "$OUT/all"
cp -a "$OUT/all/modules.dep" "$OUT/all_meta/modules.dep"
python3 - "$OUT" "$DEVICE" <<'PY'
import os, sys
out, device = sys.argv[1], sys.argv[2]

deps = {}
for line in open(os.path.join(out, "all", "modules.dep")):
    if ":" not in line:
        continue
    mod, rest = line.split(":", 1)
    deps[os.path.basename(mod.strip())] = [os.path.basename(d) for d in rest.split()]

want, seen = [], set()
def add(m):
    if m in seen:
        return
    seen.add(m)
    for d in deps.get(m, []):
        add(d)
    want.append(m)

# Present in the shipped ramdisk but not reachable from either load list, so the closure alone
# would drop them: the Wi-Fi stack (nothing in vendor_boot's list depends on it — qca_cld3 loads
# later, from vendor_dlkm) and the TZ log module. Included to match the shipped ramdisk exactly.
for extra in ("cfg80211.ko", "mac80211.ko", "tz_log_dlkm.ko"):
    add(extra)

for name in ("modules.load.vendor_boot", "modules.load.recovery"):
    p = os.path.join(device, name)
    if os.path.exists(p):
        for line in open(p):
            line = line.strip()
            if line:
                add(line)

missing = [m for m in want if not os.path.exists(os.path.join(out, "all", m))]
for m in want:
    src = os.path.join(out, "all", m)
    if os.path.exists(src):
        dst = os.path.join(out, "vendor_ramdisk", m)
        if not os.path.exists(dst):
            os.link(src, dst)
print(f":: vendor_ramdisk: {len(want) - len(missing)} modules"
      + (f", {len(missing)} MISSING: {missing}" if missing else ""))
PY


# Device tree: base tuna.dtb with the SoC-level subsystem overlays merged in, plus dtbo.img
# holding one fully-merged overlay per board variant. See build_tuna_dtb.sh for why.
echo ":: building device tree"
# mkdtimg is not on PATH outside an envsetup'd shell; libufdt's mkdtboimg.py is the same tool.
export MKDTIMG="${MKDTIMG:-$DEVICE/../../../system/libufdt/utils/src/mkdtboimg.py}"
"$HERE/build_tuna_dtb.sh" "$KWS/msm-kernel" "$KWS/bazel-bin/msm-kernel/sun_perf" "$OUT/dt"
# dtb.img is three DTBs concatenated, in this order — the bootloader picks by compatible:
#   1. the merged base tuna.dtb (SoC-level subsystem overlays folded in)
#   2. tuna7.dtb   } sibling board variants, straight from Kleaf, not merged
#   3. tunap.dtb   }
# Verified 2026-07-28: this reproduces the previously-working prebuilt dtb.img.src byte for byte
# (573282 + 385447 + 385327 = 1344056). Shipping only the merged tuna.dtb would drop the other
# two variants that the shipped image carries.
cat "$OUT/dt/tuna.dtb" \
    "$KWS/bazel-bin/msm-kernel/sun_perf/tuna7.dtb" \
    "$KWS/bazel-bin/msm-kernel/sun_perf/tunap.dtb" > "$OUT/dtb.img"
cp -a "$OUT/dt/dtbo.img" "$OUT/dtbo.img"

echo
echo ":: done"
echo "   vendor_dlkm : $(ls "$OUT/vendor_dlkm"/*.ko | wc -l) modules"
echo "   system_dlkm : $(ls "$OUT/system_dlkm"/*.ko | wc -l) modules"
echo "   dtb.img     : $(stat -c%s "$OUT/dtb.img") bytes"
echo "   dtbo.img    : $(stat -c%s "$OUT/dtbo.img") bytes"
