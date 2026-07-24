param(
    [string]$GodotExe = "$PSScriptRoot\..\.tools\godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe"
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$BuildDir = Join-Path $ProjectRoot 'builds\windows'
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

& (Join-Path $PSScriptRoot 'test.ps1') -GodotExe $GodotExe
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$ExePath = Join-Path $BuildDir 'ZeroNetTrace.exe'
$PckPath = Join-Path $BuildDir 'ZeroNetTrace.pck'
& $GodotExe --headless --path $ProjectRoot --export-release "Windows Desktop" $ExePath
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$ProbeProject = Join-Path $ProjectRoot '.tools\export_probe'
& $GodotExe --headless --path $ProbeProject --script res://check_pack.gd -- $PckPath
exit $LASTEXITCODE
