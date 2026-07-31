#!/usr/bin/env bash
set -euo pipefail

name="${1:-lineage-23.0-20260731-UNOFFICIAL-metroid.zip}"
parts=("${name}.part-aa" "${name}.part-ab" "${name}.part-ac")
for part in "${parts[@]}"; do
    [[ -s "${part}" ]] || { echo "Missing ${part}" >&2; exit 1; }
done

cat "${parts[@]}" > "${name}"
sha256sum -c "${name}.sha256"
unzip -tq "${name}"
