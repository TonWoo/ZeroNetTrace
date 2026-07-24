param(
    [string]$GodotExe = "$PSScriptRoot\..\.tools\godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe"
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if (-not (Test-Path -LiteralPath $GodotExe)) {
    throw "Godot executable not found: $GodotExe"
}

$Output = (& $GodotExe --verbose --headless --path $ProjectRoot --quit-after 3 2>&1 | Out-String)
$ExitCode = $LASTEXITCODE
$Output

if ($ExitCode -ne 0) {
    exit $ExitCode
}

if ($Output -match '(?im)^ERROR:' -or $Output -match '(?im)^WARNING:' -or $Output -match '(?im)^Leaked instance:') {
    Write-Error 'Headless smoke test emitted an error, warning, or leaked instance.'
    exit 1
}

Write-Output 'PASS: headless main-scene smoke test is clean'
