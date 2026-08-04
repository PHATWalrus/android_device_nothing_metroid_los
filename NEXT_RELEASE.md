# Next release

## Blockers

- Face enrollment: reproduce from the capture screen with clean Face HAL,
  camera-provider, AVC and tombstone logs.
- Camera: validate UHD30 after Tuna profile selection and collect remaining
  lens/zoom edge cases from testers.
- Haptics: compare stock Nothing OS and Lineage effect IDs, amplitudes and driver
  gain/calibration; the stock service still feels weak.

## Community coverage

- Calls, SMS, mobile data, IMS, emergency UI, dual SIM and handover.
- Bluetooth LE Audio, USB-C audio, NFC HCE/secure element, wireless charging.
- Suspend drain, thermal throttling, HDR/video playback, camera third-party apps.

## Release gate

1. All modified projects committed on `lineage-23.0-metroid`.
2. Fresh install-clean `m bacon` using all available build resources.
3. VINTF, init, payload, AVB, signing and partition audits pass.
4. Target-slot boot, second boot, Enforcing, encryption and crash sweep pass.
5. Update `BASELINE.md`, release notes and SHA-256; then tag source.
