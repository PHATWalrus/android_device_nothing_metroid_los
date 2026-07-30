# Prebuilt kernel modules — source not published

Every other module in `vendor_dlkm` is built from source by `stage_kernel_artifacts.sh`
(306 of 313 as of 2026-07-28). These seven are not, because **Nothing has not released their
source**. They are GPL kernel modules, so this is a gap on the vendor's side, not a choice.

Verified 2026-07-28 by content grep across `msm-kernel/`, all 37 `vendor/qcom/opensource/*`
packages and the stock `dump_a16` image, trying both `-` and `_` spellings: only the compiled
`.ko` exists anywhere.

| module | what it is |
|---|---|
| `aw882xx_dlkm.ko` | Awinic AW882xx smart audio amplifier codec |
| `stm_nfc_i2c.ko` | ST NFC controller (ST's Android driver, not mainline `st-nci`) |
| `stm_st54se_gpio.ko` | ST ST54 secure element GPIO |
| `nothing_performance.ko` | Nothing's performance/boost driver |
| `nothing_rdump.ko` | Nothing's raw-dump driver (the `nothing,lba_addr` DT node belongs to it) |
| `rpmb_state.ko` | RPMB state |
| `spmi-pmic-err-debug.ko` | SPMI PMIC error debug |

## Which copy is pinned, and why it matters

Four of these ship in **both** the stock `vendor_boot` ramdisk and `vendor_dlkm` — as *different
builds*: `6.6.102` in the ramdisk, `6.6.87` in `vendor_dlkm`. Pin the **6.6.102** copies:

| module | pinned from | vermagic |
|---|---|---|
| `nothing_performance` | stock vendor_boot ramdisk | `6.6.102-android15-8-maybe-dirty-4k` |
| `nothing_rdump` | stock vendor_boot ramdisk | `6.6.102-android15-8-maybe-dirty-4k` |
| `rpmb_state` | stock vendor_boot ramdisk | `6.6.102-android15-8-maybe-dirty-4k` |
| `spmi-pmic-err-debug` | stock vendor_boot ramdisk | `6.6.102-android15-8-maybe-dirty-4k` |
| `aw882xx_dlkm` | stock `vendor_dlkm` | `6.6.87-android15-8-maybe-dirty-4k` |
| `stm_nfc_i2c` | stock `vendor_dlkm` | `6.6.87-android15-8-maybe-dirty-4k` |
| `stm_st54se_gpio` | stock `vendor_dlkm` | `6.6.87-android15-8-maybe-dirty-4k` |

The last three are `vendor_dlkm`-only, and `6.6.87` is fine there: second-stage module loading is
lenient about vermagic, which is why stock ships them that way. **First-stage is not** — a ramdisk
module whose vermagic does not exactly match the running GKI is rejected, and enough rejections
mean nothing mounts and the device hangs on the logo. Taking the `vendor_dlkm` copies of the first
four is exactly that mistake; see `metroid-vermagic-first-stage` in memory.

All pinned from stock Nothing OS `Metroid_B4.0-250917-1218`.

If Nothing ever publishes these, delete this directory and drop the names from
`UNPUBLISHED` in `stage_kernel_artifacts.sh`.
