# Release process

The release workflow is intentionally tag-only. Do not create a
`lineage-23.0-*` tag until the exact OTA passes target-slot boot, the hardware
acceptance sweep, and a second reboot, and the blocker in `RELEASE_NOTES.md` has
been replaced with tested results.

## Prepare assets

The full OTA exceeds GitHub's 2 GiB per-asset limit. Split it into 1,900 MiB
parts, stage the matching recovery bundle and reassembly helpers, then create a
SHA-256 manifest:

```bash
split -b 1900M lineage-23.0-20260731-UNOFFICIAL-metroid.zip \
  lineage-23.0-20260731-UNOFFICIAL-metroid.zip.part-
sha256sum <every-release-asset-except-the-manifest> > release-assets.sha256
sha256sum -c release-assets.sha256
manifest_sha256="$(sha256sum release-assets.sha256 | awk '{print $1}')"
```

The current staged asset manifest is kept on the build host. Its hash must be
recomputed after any asset or provenance update.

## Serve the sealed directory

Expose only the sealed asset directory through a temporary HTTPS endpoint. Keep
the endpoint alive until the GitHub Actions run finishes. The workflow downloads
`release-assets.sha256`, verifies the manifest against the hash pinned in the
tag, rejects unsafe filenames, downloads every listed asset, and verifies every
asset before creating a prerelease.

## Create the annotated tag

Use exactly one metadata line for each required field:

```bash
git tag -a lineage-23.0-20260731 \
  -m 'LineageOS 23 metroid 2026-07-31 tester release' \
  -m 'asset-base-url=https://temporary-host.example' \
  -m "manifest-sha256=${manifest_sha256}"
git push origin lineage-23.0-20260731
```

The tag must be annotated, the asset URL must use HTTPS, and the manifest hash
must be 64 lowercase hexadecimal characters. Duplicate or missing metadata
lines fail before any asset download.

Monitor **Actions -> Publish ROM release**. After the prerelease exists and all
assets are visible, stop the temporary HTTPS endpoint and independently verify
one downloaded asset plus the published manifest.
