# Required source patches

The 2026-08-04 tester release was built with topic commits outside this device
repository. Until the corresponding `logix727` forks exist, apply the checked-in
mail patches after syncing LineageOS 23:

```bash
git -C frameworks/base am \
  ../../device/nothing/metroid/patches/frameworks_base/*.patch
git -C bootable/recovery am \
  ../../device/nothing/metroid/patches/bootable_recovery/*.patch
git -C packages/apps/Aperture am \
  ../../../device/nothing/metroid/patches/aperture/*.patch
git -C packages/apps/Settings am \
  ../../../device/nothing/metroid/patches/settings/*.patch
git -C vendor/qcom/opensource/vibrator am \
  ../../../../device/nothing/metroid/patches/vibrator/*.patch
```

Recorded source revisions:

| Project | Base revision | Release commit |
|---|---|---|
| `frameworks/base` | `155701ba6a05d0061dbab1b9f1bfec2040cf4158` | `ee4f85c5dfee0d6feaa10a39536269b88d04a5c7` |
| `bootable/recovery` | `457416ed80f53280ea9e2421027b96ac1ab9cb5d` | `42ea725381c1b67fb2cee6b5f7d87a7d39d3f3fa` |
| `packages/apps/Aperture` | `7f0c98fbd0d9959a4e22f93116a2e855a97285ac` | `e3d66ba62335ee9ac95ea183d0b1ebf6e611734c` |
| `packages/apps/Settings` | `ff1e876d2e558bc72cb51fb9d8206115f8ef75f9` | `e1521e76f588b94bb754101bf47a97c8df078747` |
| `vendor/qcom/opensource/vibrator` | `7636b284f04d59024e48d1480bf822cadd3005f6` | `a1b22e719f0e1e7f2986860601a94b66f36ac2f5` |

The framework patch carries the UDFPS coordinate override and two
`system_server` boot-safety fixes. The recovery patch raises minui's input
device capacity so the PMIC power and volume-down keys are registered after
the phone's squeeze-sensor input nodes.

The vendor tree is proprietary and must not be published. Its text-only
configuration replay is under `patches/vendor_nothing_metroid/`; apply it only
to a private vendor tree populated from your own stock dump.
