param(
    [string]$Output = "lineage-23.0-20260731-UNOFFICIAL-metroid.zip"
)

$ErrorActionPreference = "Stop"
$outputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Output)
$parts = @("$outputPath.part-aa", "$outputPath.part-ab", "$outputPath.part-ac")
foreach ($part in $parts) {
    if (-not (Test-Path -PathType Leaf $part)) {
        throw "Missing $part"
    }
}

$destination = [System.IO.File]::Create($outputPath)
try {
    foreach ($part in $parts) {
        $source = [System.IO.File]::OpenRead($part)
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

$expected = ((Get-Content "$outputPath.sha256" -First 1) -split '\s+')[0].ToLowerInvariant()
$actual = (Get-FileHash -Algorithm SHA256 $outputPath).Hash.ToLowerInvariant()
if ($actual -ne $expected) {
    throw "SHA-256 mismatch: expected $expected, got $actual"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($outputPath)
try {
    if ($archive.Entries.Count -eq 0) {
        throw "Reconstructed ZIP contains no entries"
    }
}
finally {
    $archive.Dispose()
}

Write-Host "SHA-256 verified: $actual"
