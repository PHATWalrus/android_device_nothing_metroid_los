param(
    [string]$Output = "lineage-23.0-20260731-UNOFFICIAL-metroid.zip"
)

$ErrorActionPreference = "Stop"
$parts = Get-ChildItem -File "$Output.part-*" | Sort-Object Name
if (-not $parts) {
    throw "No parts found for $Output"
}

$destination = [System.IO.File]::Create($Output)
try {
    foreach ($part in $parts) {
        $source = [System.IO.File]::OpenRead($part.FullName)
        try {
            $source.CopyTo($destination)
        }
        finally {
            $source.Dispose()
        }
    }
}
finally {
    $destination.Dispose()
}

$expected = ((Get-Content "$Output.sha256" -First 1) -split '\s+')[0].ToLowerInvariant()
$actual = (Get-FileHash -Algorithm SHA256 $Output).Hash.ToLowerInvariant()
if ($actual -ne $expected) {
    throw "SHA-256 mismatch: expected $expected, got $actual"
}

Write-Host "SHA-256 verified: $actual"
