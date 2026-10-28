param(
    [string]$GameExe,
    [switch]$Restore,
    [switch]$PrepareOnly,
    [string]$CacheRoot = (Join-Path $env:LOCALAPPDATA 'GTAIV-RTX-FGFix\1.5.2-r2')
)

$ErrorActionPreference = 'Stop'

$upstreamZipName = 'GTAIV-Remix-CompatibilityMod-1.5.2.zip'
$upstreamInstallerName = 'GTAIV-Remix-CompMod-Installer.exe'
$upstreamZipUrl = "https://github.com/xoxor4d/gta4-rtx/releases/download/v1.5.2/$upstreamZipName"
$upstreamInstallerUrl = "https://github.com/xoxor4d/gta4-rtx/releases/download/v1.5.2/$upstreamInstallerName"
$upstreamZipHash = '7336AB1CBB232DB3E5447641AA3554A8F254D353A46E1E83C36B925B1F93FFB9'
$upstreamInstallerHash = 'F0A2DD89BBF9D6AE38C4A1FACF31212C7055EF56994F7F42E15676EAB7A1F15B'
$upstreamAsiHash = 'B53EE10F007791676BC797C1FAFE33925F3B3FD88BEFAC9599BBAE4D93A7D0BB'
$upstreamRuntimeHash = 'CABB37C2FDD4E65577247207A2FBDDCEE48C081176369AE62D7B3E57379A1D1C'
$patchedRuntimeHash = 'DEAC7A79E54277C42AA2B0782295E9008C14294B8A282A6339ACF6FBAF6AD0D1'
$runtimeEntryName = 'GTAIV-Remix-CompatibilityMod/.trex/d3d9.dll'
$patchDll = Join-Path $PSScriptRoot '.trex\d3d9.dll'

function Assert-Hash([string]$Path, [string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Missing file: $Path"
    }
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual -ne $Expected) {
        throw "Checksum mismatch for $Path. Expected $Expected; got $actual."
    }
}

function Get-GameExe {
    if ($GameExe) {
        $candidate = $GameExe
    } else {
        Add-Type -AssemblyName System.Windows.Forms
        $picker = New-Object System.Windows.Forms.OpenFileDialog
        $picker.Title = 'Select GTAIV.exe (GTA IV: The Complete Edition)'
        $picker.Filter = 'GTAIV.exe|GTAIV.exe'
        $picker.FileName = 'GTAIV.exe'
        if ($picker.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            throw 'Game selection was cancelled.'
        }
        $candidate = $picker.FileName
    }
    if ((Split-Path -Leaf $candidate) -ne 'GTAIV.exe' -or -not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw 'Select the GTAIV.exe inside the GTAIV game folder.'
    }
    return (Resolve-Path -LiteralPath $candidate).Path
}

function Assert-GameClosed {
    $running = Get-Process -Name 'GTAIV', 'NvRemixBridge' -ErrorAction SilentlyContinue
    if ($running) {
        throw 'Close GTA IV and RTX Remix before installing or restoring the runtime.'
    }
}

function Get-OfficialFile([string]$Url, [string]$Path, [string]$Hash) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        try {
            Assert-Hash $Path $Hash
            Write-Host "Using verified cached file: $(Split-Path -Leaf $Path)"
            return
        } catch {
            Remove-Item -LiteralPath $Path -Force
        }
    }
    Write-Host "Downloading $(Split-Path -Leaf $Path) from xoxor4d/gta4-rtx ..."
    $temporary = "$Path.download"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $temporary -TimeoutSec 900 -UseBasicParsing
        Assert-Hash $temporary $Hash
        Move-Item -LiteralPath $temporary -Destination $Path -Force
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    }
}

function Copy-ZipEntry([string]$ZipPath, [string]$EntryName, [string]$TargetPath) {
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $entry = $archive.GetEntry($EntryName)
        if (-not $entry) { throw "The official mod archive does not contain $EntryName" }
        $source = $entry.Open()
        try {
            $target = [System.IO.File]::Create($TargetPath)
            try { $source.CopyTo($target) } finally { $target.Dispose() }
        } finally { $source.Dispose() }
    } finally { $archive.Dispose() }
}

function Prepare-PatchedArchive([string]$OriginalPath, [string]$TargetPath) {
    Copy-Item -LiteralPath $OriginalPath -Destination $TargetPath -Force
    $archive = [System.IO.Compression.ZipFile]::Open($TargetPath, [System.IO.Compression.ZipArchiveMode]::Update)
    try {
        $entry = $archive.GetEntry($runtimeEntryName)
        if (-not $entry) { throw "The official mod archive does not contain $runtimeEntryName" }
        $entry.Delete()
        $replacement = $archive.CreateEntry($runtimeEntryName, [System.IO.Compression.CompressionLevel]::Optimal)
        $source = [System.IO.File]::OpenRead($patchDll)
        try {
            $target = $replacement.Open()
            try { $source.CopyTo($target) } finally { $target.Dispose() }
        } finally { $source.Dispose() }
    } finally { $archive.Dispose() }

    $verify = [System.IO.Compression.ZipFile]::OpenRead($TargetPath)
    try {
        $matches = @($verify.Entries | Where-Object { $_.FullName -eq $runtimeEntryName })
        if ($matches.Count -ne 1 -or $matches[0].Length -ne (Get-Item -LiteralPath $patchDll).Length) {
            throw 'The prepared installer archive failed validation.'
        }
    } finally { $verify.Dispose() }
}

try {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if ($Restore -and $PrepareOnly) { throw 'Choose either Restore or PrepareOnly.' }
    if (-not $Restore) { Assert-Hash $patchDll $patchedRuntimeHash }
    New-Item -ItemType Directory -Path $CacheRoot -Force | Out-Null
    $originalZip = Join-Path $CacheRoot $upstreamZipName
    $installerExe = Join-Path $CacheRoot $upstreamInstallerName
    $workingDir = Join-Path $CacheRoot 'prepared-installer'
    $preparedZip = Join-Path $workingDir $upstreamZipName

    if ($PrepareOnly) {
        Get-OfficialFile $upstreamZipUrl $originalZip $upstreamZipHash
        New-Item -ItemType Directory -Path $workingDir -Force | Out-Null
        Prepare-PatchedArchive $originalZip $preparedZip
        Write-Host "Prepared verified v1.5.2 archive: $preparedZip"
        exit 0
    }

    Assert-GameClosed
    $selectedExe = Get-GameExe
    $gameDir = Split-Path -Parent $selectedExe
    $runtimeDir = Join-Path $gameDir '.trex'
    $runtime = Join-Path $runtimeDir 'd3d9.dll'
    $backup = Join-Path $runtimeDir 'd3d9.dll.before-fgfix-1.5.2'

    if ($Restore) {
        if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
            throw "No automatic backup was found at $backup"
        }
        Copy-Item -LiteralPath $backup -Destination $runtime -Force
        Write-Host "Restored the previous runtime from $backup"
        exit 0
    }

    $asi = Join-Path $gameDir 'a_gta4-rtx.asi'
    $bridge = Join-Path $gameDir 'd3d9.dll'
    $modInstalled = (Test-Path -LiteralPath $asi -PathType Leaf) -and
        (Test-Path -LiteralPath $bridge -PathType Leaf) -and
        (Test-Path -LiteralPath $runtime -PathType Leaf)
    $sameModVersion = $modInstalled -and ((Get-FileHash -LiteralPath $asi -Algorithm SHA256).Hash -eq $upstreamAsiHash)

    if ($sameModVersion) {
        if ((Get-FileHash -LiteralPath $runtime -Algorithm SHA256).Hash -eq $patchedRuntimeHash) {
            if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
                Get-OfficialFile $upstreamZipUrl $originalZip $upstreamZipHash
                Copy-ZipEntry $originalZip $runtimeEntryName $backup
                Assert-Hash $backup $upstreamRuntimeHash
            }
            Write-Host 'The shimmer fix is already installed. Restore.cmd can restore the original v1.5.2 runtime.'
            exit 0
        }
        if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
            Copy-Item -LiteralPath $runtime -Destination $backup
        }
        Copy-Item -LiteralPath $patchDll -Destination $runtime -Force
        Assert-Hash $runtime $patchedRuntimeHash
        Write-Host "Installed the shimmer fix. The previous runtime was saved automatically at $backup"
        exit 0
    }

    Write-Host 'Preparing a fresh install of GTA IV RTX Remix Compatibility Mod v1.5.2.'
    Get-OfficialFile $upstreamZipUrl $originalZip $upstreamZipHash
    Get-OfficialFile $upstreamInstallerUrl $installerExe $upstreamInstallerHash
    New-Item -ItemType Directory -Path $workingDir -Force | Out-Null
    Prepare-PatchedArchive $originalZip $preparedZip
    Copy-Item -LiteralPath $installerExe -Destination (Join-Path $workingDir $upstreamInstallerName) -Force
    Write-Host 'The official installer will open. Select the same GTAIV.exe, choose full install if asked, and accept the required base mod.'
    $process = Start-Process -FilePath (Join-Path $workingDir $upstreamInstallerName) -WorkingDirectory $workingDir -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "The official installer exited with code $($process.ExitCode)." }
    if (-not (Test-Path -LiteralPath $runtime -PathType Leaf)) { throw 'The runtime was not installed. Check the official installer output.' }
    Assert-Hash $runtime $patchedRuntimeHash
    if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
        Copy-ZipEntry $originalZip $runtimeEntryName $backup
        Assert-Hash $backup $upstreamRuntimeHash
    }
    Remove-Item -LiteralPath $preparedZip -Force
    Write-Host "Installed the shimmer fix. The original runtime was saved automatically at $backup"
    Write-Host 'For DLSS 5 Neural Rendering, provide nvngx_dlssnr.dll yourself as described by xoxor4d/gta4-rtx.'
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
