# Pinned Google GKI

This is the only prebuilt kernel content in the tree. Everything else — all 306 buildable
`vendor_dlkm` modules, the base DTB and `dtbo.img` — is generated from the Nothing GPL kernel
source by `../stage_kernel_artifacts.sh`.

The LineageOS charter permits this explicitly:

> GKI devices MAY use either a source-built kernel or a prebuilt GKI image from Google, but MUST
> build all feasible modules from source.
> — `LineageOS/charter`, `device-support-requirements.md`, §Kernel

## Contents

| file | provenance |
|---|---|
| `Image` | `6.6.102-android15-8-gab8eb70a71b8-ab14350911-4k`, built by `kleaf@build-host` 2025-10-29. Google GKI build `ab14350911`. Shipped by Nothing on Nothing OS `Metroid_B4.0-250917-1218`. |
| `system_dlkm/` | 96 GKI modules from Google GKI build `ab13768703`, vermagic `6.6.87-android15-8-gc2569c3b141c-ab13768703-4k`. Also as shipped by Nothing. |

Note the `Image` and `system_dlkm` come from *different* Google GKI builds (6.6.102 vs 6.6.87).
That is how the device shipped, and it works because GKI enforces the KMI generation
(`android15-8`), which both share — not the point release.

## Why system_dlkm is not built from source

GKI modules belong to the GKI release, not to this device. Our own `//common:kernel_aarch64`
build is `android15-6.6` HEAD (6.6.142) and its `gki_defconfig` does not even match Google's —
it has no `CONFIG_TLS`, so it cannot produce the `tls.ko` this device loads. Pairing our GKI
modules with Google's `vmlinux` would be strictly worse than shipping the matched set.

## Switching to a fully source-built kernel

The Kleaf workspace already builds `//common:kernel_aarch64` and `//msm-kernel:sun_perf_dist`
end to end, so shipping our own `Image` + `system_dlkm` is a config change, not new work. It was
deliberately not done: it would move the device off the 6.6.102 GKI its firmware was validated
against, for no compliance gain. If you do switch, rebuild `vendor_dlkm` in the same pass so all
three stay consistent.
