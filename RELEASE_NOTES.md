# LineageOS 23 for Nothing Phone (3) (`metroid`)

## 2026-08-04 tester build

This is an **unofficial prerelease for testers**, not a daily-driver or official
LineageOS build.

SHA-256:

`74c012f8ef5a5cce1a860442be06bc412c43e11881c2f5f004559cec9c6c4869`

### Verified

- Full Virtual A/B recovery sideload and target-slot boot.
- Enforcing SELinux, encrypted `/data`, stable `system_server`.
- Payload-to-target-files equivalence for all 16 partitions and full AVB graph.
- Display, touch, Wi-Fi, Bluetooth, NFC, GNSS, audio, USB and sensors register.
- Fingerprint enrollment artwork and lockscreen indication placement corrected.
- Camera photo/video, front screen flash, physical rear lenses, logical SAT
  `0.6x/1x/3x` and FHD60 work in controlled tests.
- Nothing stock vibrator service, RC, RichTap/AW dependencies and SFDC are loaded.

### Known issues / tester focus

- Face unlock enrollment still fails and needs logs.
- Camera zoom/lens behavior is improved but still needs broad app/mode testing.
- Haptics remain noticeably weaker than Nothing OS despite the stock stack.
- UHD/4K routing was enabled in this build and needs device validation.
- Cellular calls, SMS, mobile data, IMS and emergency calling require SIM testing.
- Unlocked bootloader means no Widevine L1, strong Play Integrity or HDCP trust.

Report the exact ZIP hash, firmware, install type, reproduction steps, `logcat`,
`dmesg` and new tombstones. See [`INSTALL.md`](INSTALL.md).
