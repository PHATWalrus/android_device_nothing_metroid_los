# Lineage Recovery bootstrap

This directory is the source for the release bootstrap bundle. Release bundles
also contain the nine `.img` files extracted from the matching full OTA payload
and a `SHA256SUMS.txt` file.

Use this only for the Nothing Phone (3), codename `metroid`, on the documented
Nothing OS B4.1 firmware baseline. The scripts:

- flash the matched `boot`, `init_boot`, `vendor_boot`, `dtbo`, `pvmfw`,
  `recovery`, `vbmeta_system`, `vbmeta_vendor`, and root `vbmeta` images to both
  slots;
- keep root vbmeta flags at zero and never disable verification;
- leave `super`, `userdata`, and `metadata` untouched;
- activate slot A, clear stale recovery commands from `misc`, and reboot to
  Lineage Recovery.

Treat the bootstrap as one uninterrupted operation. Both slots are updated so
the boot and AVB chain remains coherent regardless of the slot selected by the
subsequent A/B OTA. If any fastboot command fails or the cable disconnects, do
not reboot Android; stop and use the documented stock recovery procedure.

Do not mix a bootstrap bundle with a ROM ZIP from another build. Do not reboot
Android after bootstrapping until the matching full OTA has installed
successfully from Lineage Recovery.

See [`../INSTALL.md`](../INSTALL.md) for the complete workflow.
