#!/usr/bin/env bash
# Build tuna.dtb / dtbo set fully from source.
#
# WHY THIS EXISTS
# ---------------
# Kleaf only builds arch/arm64/boot/dts. The per-subsystem device tree lives in 15 separate
# packages under vendor/qcom/opensource/*-devicetree/ (camera, audio, display, gpu, dsp, eva,
# ipa, mmrm, nfc, synx, video, eSE, bt, fingerprint, graphics), and Nothing shipped those with
# a Makefile but no BUILD.bazel -- so nothing ever compiled them. The base tuna.dtb Kleaf emits
# therefore has 3018 nodes and is missing 86 driver 'compatible' strings that the shipped DTB has
# (camera sensors, audio-pkt, bt_swr_mstr, camera-bus-nodes, ...).
#
# Qualcomm's convention is to compile those packages to overlays and fold them into the base DTB
# with fdtoverlaymerge (which is why that tool exists only in the QCOM-patched external/dtc).
# Board-variant overlays (qrd/mtp/cdp) are NOT merged -- they stay in dtbo.img and are applied at
# boot by the bootloader. Verified against the shipped dtb.img: SoC-level overlays are present in
# the Tuna base DTB, QRD ones are not.
#
# This closes the gap 86 -> 4 missing compatibles. The 4 remaining:
#   qcom,msm-mmrm-test          - test-only node, merged below for parity
#   qcom,regulator-ocp-notifier } pmic overlay nodes, driver present, node not in the published DTS
#   qcom,rpmh-pbs-regulator     }
#   nothing,lba_addr            - node for the unpublished nothing_rdump driver (see rdump.dtsi)
#
# Usage: build_tuna_dtb.sh <kernel-source-dir> <kleaf-out-dir> <output-dir>
set -euo pipefail

KSRC="${1:?kernel source dir (msm-kernel)}"
KOUT="${2:?kleaf output dir containing tuna.dtb + tuna-*.dtbo}"
OUT="${3:?output dir}"
DTC="${DTC:-$(dirname "$0")/../../../../../kernelws/dist/bin/dtc}"
FOM="${FDTOVERLAYMERGE:-$(dirname "$0")/../../../../../kernelws/dist/bin/fdtoverlaymerge}"

mkdir -p "$OUT/overlays"
cd "$KSRC"

# Include roots: kernel include/, the arch dts dirs, plus every opensource package that carries
# dt-bindings/ (camera-kernel, synx-kernel) or include/ (audio-kernel) or is a *-devicetree pkg.
INC=(-I include -I arch/arm64/boot/dts/vendor -I arch/arm64/boot/dts/vendor/qcom)
for d in vendor/qcom/opensource/*/; do
    [ -d "${d}dt-bindings" ] && INC+=(-I "${d%/}")
    [ -d "${d}include" ]     && INC+=(-I "${d}include")
    case "$d" in *-devicetree/) INC+=(-I "${d%/}");; esac
done

echo "== compiling subsystem overlays =="
n=0
while read -r f; do  # includes arbok-* (Nothing board) and wlan-devicetree
    b=$(basename "$f" .dts)
    cpp -nostdinc -undef -x assembler-with-cpp -D__DTS__ "${INC[@]}" "$f" -o "$OUT/overlays/$b.pp"
    "$DTC" -I dts -O dtb -@ -qq -o "$OUT/overlays/$b.dtbo" "$OUT/overlays/$b.pp"
    n=$((n+1))
done < <(find vendor/qcom/opensource/*-devicetree -name "tuna*.dts" | sort)
echo "   $n overlays compiled"

# SoC-level overlays -> merged into the base DTB (matches the shipped partitioning).
# Board-variant overlays (tuna-camera-sensor-qrd, tuna-ese-qrd, tuna-sde-display-qrd-overlay,
# tuna-nfc, tuna-wcn7750-bt) deliberately excluded -- they belong in dtbo.img.
MERGE=(tuna-camera tuna-audio tuna-audio-qrd tuna-sde tuna-dsp tuna-eva tuna-gpu
       tuna-ipa tuna-mmrm tuna-mmrm-test tuna-synx tuna-vidc tuna-smem-mailbox)

echo "== merging into base tuna.dtb =="
cp "$KOUT/tuna.dtb" "$OUT/tuna.dtb"
for o in "${MERGE[@]}"; do
    [ -f "$OUT/overlays/$o.dtbo" ] || { echo "   skip $o (not built)"; continue; }
    "$FOM" -i "$OUT/tuna.dtb" -o "$OUT/tuna.dtb.next" "$OUT/overlays/$o.dtbo"
    mv "$OUT/tuna.dtb.next" "$OUT/tuna.dtb"
    echo "   + $o"
done

echo "== done: $OUT/tuna.dtb ($(stat -c%s "$OUT/tuna.dtb") bytes) =="

# ---------------------------------------------------------------------------
# dtbo.img
# ---------------------------------------------------------------------------
# The shipped dtbo.img holds ONE fully-merged overlay per board variant (13 Tuna entries at
# 220-292 KB), NOT per-subsystem fragments -- confirmed by dumping the stock image's entry models.
# The `dtbo-y` lists in each package's Kbuild are the intermediate step; the final image merges
# each variant's subsystem overlays into its board overlay with fdtoverlaymerge.
#
# Two files are easy to miss and both matter:
#   * arbok-camera-sensor-t0.dts  -- "arbok" is Nothing's board name (cf. tuna-arbok-common-overlay
#     .dtsi).  Using tuna-camera-sensor-qrd.dts instead yields cam-sensor=3 + cam-i2c-sensor=1 and
#     the camera HAL enumerates 0 devices.  arbok gives cam-sensor=4 / cam-i2c-sensor=0, matching
#     the stock overlay exactly.
#   * vendor/qcom/opensource/wlan/wlan-devicetree/  -- nested one level deeper, so a
#     */*-devicetree glob misses it.  Without tuna-qrd-wcn7750 there is no qcom,wcn7750 node and
#     wlan0 never appears.
# Do NOT merge arbok-camera.dts (the SoC-level cpas/isp/cci block) into the overlay -- it belongs
# in the base DTB and shows up as 23 extra compatibles if merged here.
#
# Result: tuna-qrd-overlay = 310513 B vs stock 311536 B, with an IDENTICAL compatible set
# (0 missing / 0 extra).  Verified booting: 5 cameras, wlan0 up, 39 sensors, BT, fingerprint, Glyph.
QRD_MERGE="tuna-sde-display-qrd-overlay arbok-camera-sensor-t0 tuna-audio-qrd tuna-ese-qrd
           tuna-nfc tuna-wcn7750-bt tuna-qrd-wcn7750"

echo "== building dtbo.img =="
mkdir -p "$OUT/dtbo"; rm -f "$OUT"/dtbo/*.dtbo
cp "$KOUT"/tuna*overlay*.dtbo "$OUT/dtbo/" 2>/dev/null
Q="$OUT/dtbo/tuna-qrd-overlay.dtbo"
for o in $QRD_MERGE; do
    [ -f "$OUT/overlays/$o.dtbo" ] || { echo "   skip $o"; continue; }
    "$FOM" -i "$Q" -o "$OUT/dtbo/.t" "$OUT/overlays/$o.dtbo" >/dev/null 2>&1 && mv "$OUT/dtbo/.t" "$Q"
done
echo "   tuna-qrd-overlay: $(stat -c%s "$Q") B"
"${MKDTIMG:-mkdtimg}" create "$OUT/dtbo.img" --page_size=4096 "$OUT"/dtbo/*.dtbo
echo "== done: $OUT/dtbo.img ($(stat -c%s "$OUT/dtbo.img") bytes) =="
