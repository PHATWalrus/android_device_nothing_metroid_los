#!/usr/bin/env bash
set -euo pipefail

name="${1:-lineage-23.0-20260731-UNOFFICIAL-metroid.zip}"
parts=("${name}".part-*)
if [[ ! -e "${parts[0]}" ]]; then
    echo "No parts found for ${name}" >&2
    exit 1
fi

cat "${parts[@]}" > "${name}"
sha256sum -c "${name}.sha256"
