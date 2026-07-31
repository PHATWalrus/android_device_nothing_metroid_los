# Split ROM release assets

GitHub limits each release asset to 2 GiB. The 2026-07-31 full OTA is larger,
so it is uploaded as ordered `.part-aa`, `.part-ab`, and `.part-ac` files.

Download every part, the matching `.sha256` file, and one helper into the same
directory. Reassemble and verify with:

```bash
./reassemble-rom.sh
```

or on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\reassemble-rom.ps1
```

Sideload only the reconstructed `.zip`, never an individual part.
