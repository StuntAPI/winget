# stunt — Windows installer (always the latest release).
#
# Installs stunt via winget from a local manifest. GoReleaser publishes each
# release's manifest to this repo (stuntapi/winget) under
# manifests/s/StuntAPI/Stunt/<version>/; this script clones it, picks the
# newest version, and hands it to `winget install --manifest`. So it always
# installs the latest release without you tracking a version number.
#
#   Install:  irm https://raw.githubusercontent.com/stuntapi/winget/main/install.ps1 | iex
#   Update:   re-run the same command
#   Remove:   winget uninstall StuntAPI.Stunt
#
# Requires: Windows 10/11 (App Installer / winget) and git.

$ErrorActionPreference = 'Stop'

$repo = 'https://github.com/stuntapi/winget.git'
$tmp = Join-Path $env:TEMP ('stunt-winget-' + [guid]::NewGuid().ToString('N'))

Write-Host 'Cloning stunt winget manifest repo...' -ForegroundColor Cyan
& git clone --quiet --depth 1 $repo $tmp
if ($LASTEXITCODE -ne 0) { throw 'git clone failed - is git installed and on PATH?' }

$manifestRoot = Join-Path $tmp 'manifests/s/StuntAPI/Stunt'
$dirs = Get-ChildItem $manifestRoot -Directory -ErrorAction SilentlyContinue
if (-not $dirs) {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    throw "no stunt manifests found at $manifestRoot"
}

# Newest version first (real semver sort; fall back to name sort for pre-release tags).
try {
    $latest = $dirs | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
} catch {
    $latest = $dirs | Sort-Object Name -Descending | Select-Object -First 1
}

Write-Host "Installing stunt $($latest.Name) via winget..." -ForegroundColor Cyan
& winget install --manifest $latest.FullName --accept-package-agreements --accept-source-agreements --disable-interactivity
$code = $LASTEXITCODE

Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue

if ($code -ne 0) { throw "winget install failed (exit $code)" }
Write-Host ''
Write-Host "stunt $($latest.Name) installed. Run 'stunt --version' to verify." -ForegroundColor Green
