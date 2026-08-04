# Split ROM release assets

GitHub limits each release asset to 2 GiB. The full OTA is larger,
so it is uploaded as exactly three ordered files: `.part-aa`, `.part-ab`, and
`.part-ac`.

Download every part, the matching `.sha256` file, and one helper into the same
directory. Reassemble and verify with:

```bash
./reassemble-rom.sh
```

or on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\reassemble-rom.ps1
```

Both helpers require all three parts, verify the original ZIP SHA-256, and check
the reconstructed ZIP directory. Sideload only that `.zip`, never an individual
part.
