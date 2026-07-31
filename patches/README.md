# Required source patches

The 2026-07-31 release was built with two clean topic commits outside this
device repository. Apply both patch sets after syncing LineageOS 23:

```bash
git -C frameworks/base am \
  ../../device/nothing/metroid/patches/frameworks_base/*.patch
git -C bootable/recovery am \
  ../../device/nothing/metroid/patches/bootable_recovery/*.patch
```

Recorded source revisions:

| Project | Base revision | Release commit |
|---|---|---|
| `frameworks/base` | `155701ba6a05d0061dbab1b9f1bfec2040cf4158` | `ee4f85c5dfee0d6feaa10a39536269b88d04a5c7` |
| `bootable/recovery` | `457416ed80f53280ea9e2421027b96ac1ab9cb5d` | `42ea725381c1b67fb2cee6b5f7d87a7d39d3f3fa` |

The framework patch carries the UDFPS coordinate override and two
`system_server` boot-safety fixes. The recovery patch raises minui's input
device capacity so the PMIC power and volume-down keys are registered after
the phone's squeeze-sensor input nodes.

Both mail patches are validated with `git am` against the revisions above.
