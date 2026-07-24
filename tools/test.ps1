param(
    [string]$GodotExe = "$PSScriptRoot\..\.tools\godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe"
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if (-not (Test-Path -LiteralPath $GodotExe)) {
    throw "Godot executable not found: $GodotExe"
}

$PreviousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$EditorScanOutput = (& $GodotExe --headless --editor --path $ProjectRoot --quit 2>&1 | Out-String)
$EditorScanExitCode = $LASTEXITCODE
$ErrorActionPreference = $PreviousErrorActionPreference
$EditorScanOutput
if ($EditorScanExitCode -ne 0) { exit $EditorScanExitCode }
if ($EditorScanOutput -match 'Detected another project\.godot') {
    Write-Error 'Root project scan detected a nested Godot project.'
    exit 1
}

& $GodotExe --headless --path $ProjectRoot --script res://tests/run_tests.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $GodotExe --headless --path $ProjectRoot --script res://tests/run_window_smoke.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $GodotExe --headless --path $ProjectRoot --script res://tests/run_horror_smoke.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& (Join-Path $PSScriptRoot 'smoke_headless.ps1') -GodotExe $GodotExe
exit $LASTEXITCODE
