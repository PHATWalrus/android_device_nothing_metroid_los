#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
FASTBOOT="${FASTBOOT:-fastboot}"

images=(boot init_boot vendor_boot dtbo pvmfw recovery vbmeta_system vbmeta_vendor vbmeta)
for image in "${images[@]}"; do
    if [[ ! -s "${image}.img" ]]; then
        echo "Missing ${image}.img" >&2
        exit 1
    fi
done

echo "Nothing Phone (3) / metroid Lineage Recovery bootstrap"
echo "This flashes the matched release boot and AVB chain to both slots."
echo "It does not disable AVB and does not touch super or userdata."
echo
"${FASTBOOT}" devices
"${FASTBOOT}" getvar product 2>&1 || true
read -r -p "Type metroid to continue: " confirmation
[[ "${confirmation}" == "metroid" ]] || { echo "Cancelled."; exit 1; }

"${FASTBOOT}" set_active a
"${FASTBOOT}" erase misc

for slot in a b; do
    "${FASTBOOT}" flash "boot_${slot}" boot.img
    "${FASTBOOT}" flash "init_boot_${slot}" init_boot.img
    "${FASTBOOT}" flash "vendor_boot_${slot}" vendor_boot.img
    "${FASTBOOT}" flash "dtbo_${slot}" dtbo.img
    "${FASTBOOT}" flash "pvmfw_${slot}" pvmfw.img
    "${FASTBOOT}" flash "recovery_${slot}" recovery.img
    "${FASTBOOT}" flash "vbmeta_system_${slot}" vbmeta_system.img
    "${FASTBOOT}" flash "vbmeta_vendor_${slot}" vbmeta_vendor.img
    "${FASTBOOT}" flash "vbmeta_${slot}" vbmeta.img
done

"${FASTBOOT}" set_active a
"${FASTBOOT}" erase misc
echo "Rebooting to Lineage Recovery. Do not reboot Android before sideloading the ROM."
"${FASTBOOT}" reboot recovery
