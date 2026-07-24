#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
top="$(cd -- "${script_dir}/../../.." && pwd)"
mode="${1:-apply}"

if [[ "${mode}" != "apply" && "${mode}" != "--check" ]]; then
    echo "Usage: ${0##*/} [--check]" >&2
    exit 2
fi

while read -r project patch; do
    [[ -z "${project}" ]] && continue

    project_dir="${top}/${project}"
    patch_file="${script_dir}/patches/${patch}"

    if [[ ! -d "${project_dir}/.git" && ! -f "${project_dir}/.git" ]]; then
        echo "Missing Git project: ${project}" >&2
        exit 1
    fi

    if [[ ! -f "${patch_file}" ]]; then
        echo "Missing patch: ${patch}" >&2
        exit 1
    fi

    if git -C "${project_dir}" apply --reverse --check "${patch_file}" >/dev/null 2>&1; then
        echo "Already applied: ${patch}"
    elif git -C "${project_dir}" apply --check "${patch_file}" >/dev/null 2>&1; then
        if [[ "${mode}" == "apply" ]]; then
            git -C "${project_dir}" apply "${patch_file}"
            echo "Applied: ${patch}"
        else
            echo "Would apply: ${patch}"
        fi
    else
        echo "Patch does not apply cleanly: ${patch}" >&2
        git -C "${project_dir}" apply --check --verbose "${patch_file}" >&2 || true
        exit 1
    fi
done < "${script_dir}/patches/series"
