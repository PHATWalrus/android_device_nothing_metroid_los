# Installation

These instructions are for the Nothing Phone (3), codename `metroid`.

## Requirements

- Unlocked bootloader.
- Current Google platform-tools (`adb` and `fastboot`).
- Nothing OS B4.1 (`Metroid_B4.1-260414-1846`) firmware baseline.
- A complete stock restore package and a tested recovery procedure.
- The full OTA ZIP and recovery bootstrap bundle from the same release.

The ROM does not redistribute modem or bootloader firmware. Back up all data.
Unlocking and the required factory reset erase internal storage.

## Safety rules

- Never use `--disable-verity`, `--disable-verification`, or root vbmeta flags.
- Never mix recovery, vbmeta, boot, or ROM artifacts from different releases.
- `fastboot boot` hangs on this device; use the matched bootstrap scripts.
- Do not manually choose the OTA target slot. Android Update Engine does that.
- Stop on the first failed command. Do not repeatedly flash random partitions.

## Clean install from stock

1. Verify the downloaded hashes against the release checksums.
2. Extract the recovery bootstrap bundle.
3. Reboot the phone to the bootloader:

   ```bash
   adb reboot bootloader
   ```

4. Confirm the serial with `fastboot devices`, then run the script from the
   extracted bundle:

   ```text
   Windows: flash-lineage-recovery.bat
   Linux:   ./flash-lineage-recovery.sh
   ```

   Type `metroid` at the confirmation prompt. The script flashes the matched
   boot and AVB chain to both slots, clears `misc`, and reboots to Lineage
   Recovery. It does not flash `super` and does not disable AVB.

5. In Lineage Recovery select **Factory reset**, then **Format data / factory
   reset**.
6. Return to the main menu and select **Apply update**, then **Apply from ADB**.
7. On the computer run:

   ```bash
   adb sideload lineage-23.0-20260804-UNOFFICIAL-metroid.zip
   ```

   The host progress can stop near 47% while the device continues verifying and
   installing the A/B payload. Wait for recovery to report success. Do not
   disconnect the cable during verification or postinstall.

8. Decline optional add-ons for the first boot, then select **Reboot system
   now**. First boot can take several minutes.

## Update from an earlier matching-key build

1. Reboot to Lineage Recovery.
2. Select **Apply update**, then **Apply from ADB**.
3. Run `adb sideload <new-full-OTA.zip>`.
4. Reboot after recovery reports success. Do not factory reset unless the
   release notes require it.

## Bug reports

Include the exact ZIP SHA-256, firmware version, clean or upgrade install,
reproduction steps, and logs:

```bash
adb logcat -b all -d > logcat.txt
adb shell dmesg > dmesg.txt
```

Reproduce without an unlisted kernel, root module, or add-on before reporting.
