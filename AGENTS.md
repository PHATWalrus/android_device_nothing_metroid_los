# Metroid maintainer rules

This tree tracks the installed 2026-08-04 LineageOS 23 tester baseline. Read
`BASELINE.md` and `NEXT_RELEASE.md` before changing source.

## Invariants

- Never publish proprietary vendor blobs or private signing keys.
- Never declare an unserved stable HAL. Run `m check-vintf-all` after VINTF work.
- Keep `ro.hw_timeout_multiplier=4` in `/system/build.prop`.
- Preserve the 232-line installed `init.target.rc` with `OPUS_NTLOG_KEEP` and no
  `OPUS-USB-BRINGUP` block unless a measured boot experiment replaces it.
- Product/package changes require an install-clean release build. Incremental
  staging can retain removed RC/VINTF files.
- Build one coherent OTA; do not mix raw images from different builds.
- Before installation, inspect init, VINTF, payload-equivalence, AVB and signing
  audit results. Installation/slot/erase operations require explicit approval.
- Keep the display off outside short UI/camera test windows.

## Branches and upstream

- Persistent local work uses `lineage-23.0-metroid` in every modified project.
- Keep topic commits small and merge/rebase Lineage upstream into those branches.
- Update `BASELINE.md` only after a coherent OTA passes audits and target boot.
- Do not release from dirty or detached projects.

## Current known gaps

- Face enrollment is not working.
- Camera lens/zoom/UHD behavior needs community coverage.
- Haptics remain weaker than Nothing OS despite loading the stock service.
- Cellular/IMS/emergency calling needs physical-SIM testing.

Do not infer hardware support from Binder registration. Test the real operation
and collect logs/tombstones before changing code.
