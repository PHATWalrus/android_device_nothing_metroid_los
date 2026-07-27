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
while read -r f; do
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
