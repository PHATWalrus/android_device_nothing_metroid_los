# Metroid tree guardrails

- Preserve the booting baseline tagged `known-good-boot-20260708` while changing one subsystem at a time.
- Do not run a build without user approval.
- Do not push. Create local commits only.
- Use `/mnt/ccache` with a 50 GiB limit.
- Keep checkout paths fixed at `device/nothing/metroid`, `vendor/nothing/metroid`, and `kernel/nothing/sm8735`.
- The current prebuilt boot chain is staged at `device/nothing/metroid-kernel` and is not supplied by roomservice.
- Keep VINTF declarations limited to services present in the product. The custom fragments currently contain 45 declarations found verbatim in the supplied stock firmware.
- Do not add framework patches to compensate for a missing or broken device HAL. Fix the service packaging or device configuration first.
- Keep the current ext4 vendor and DLKM formats until a device test confirms a filesystem migration.
- Retain `ro.hw_timeout_multiplier=4` and the MAX_USES_PER_BOOT key strategy until dexpreopt and keystore behavior are validated on device.
