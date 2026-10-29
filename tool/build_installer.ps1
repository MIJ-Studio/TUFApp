# Builds the release app and packs it into installer\Output\TUFApp-Setup-<version>.exe with Inno Setup 6.
#
#   powershell -ExecutionPolicy Bypass -File tool\build_installer.ps1            (build, then pack)
#   powershell -ExecutionPolicy Bypass -File tool\build_installer.ps1 -SkipBuild (pack the existing build)
#
# Close a running Release build of TUFApp first; Windows locks its files.
param([switch]$SkipBuild)

$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot

# "version: 1.2.3+4" in pubspec.yaml → 1.2.3
$versionLine = Select-String -Path (Join-Path $project 'pubspec.yaml') -Pattern '^version:\s*([0-9.]+)' | Select-Object -First 1
if (-not $versionLine) { throw 'No version in pubspec.yaml.' }
$version = $versionLine.Matches[0].Groups[1].Value

if (-not $SkipBuild) {
  Push-Location $project
  try {
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'flutter build failed.' }
  } finally {
    Pop-Location
  }
}

# Visual C++ runtime DLLs from the Visual Studio that builds the app.
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
$crt = Get-ChildItem (Join-Path $vs 'VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT') -Directory -ErrorAction SilentlyContinue |
  Where-Object { Test-Path (Join-Path $_.FullName 'vcruntime140_1.dll') } |
  Sort-Object FullName -Descending | Select-Object -First 1
if (-not $crt) { throw "Visual C++ runtime DLLs not found under $vs\VC\Redist\MSVC." }

$iscc = @(
  (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
  (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
  (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe')
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { $iscc = (Get-Command iscc -ErrorAction SilentlyContinue).Source }
if (-not $iscc) { throw 'Inno Setup 6 is not installed (winget install JRSoftware.InnoSetup).' }

& $iscc "/DAppVersion=$version" "/DVcRuntimeDir=$($crt.FullName)" (Join-Path $project 'installer\tufapp.iss')
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup failed.' }
Write-Host "Installer: $(Join-Path $project "installer\Output\TUFApp-Setup-$version.exe")"
