# Roda a suíte de testes do Godot com o portão de 95%.
# Uso (na raiz do repositório):  .\tools\run_tests.ps1
#                                .\tools\run_tests.ps1 -Gate 0.95 -Filter gerador
param(
    [double]$Gate = 0.95,
    [string]$Filter = ""
)

$godot = Get-Command godot_console -ErrorAction SilentlyContinue
if ($godot) {
    $exe = $godot.Source
} else {
    $exe = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "Godot_v4*_win64_console.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $exe) {
    Write-Error "Godot não encontrado. Instale com: winget install --id GodotEngine.GodotEngine -e"
    exit 2
}

$root = Split-Path -Parent $PSScriptRoot
$project = Join-Path $root "game"

& $exe --headless --path $project --import *> $null

$userArgs = @("--gate=$Gate")
if ($Filter) { $userArgs += "--filter=$Filter" }

& $exe --headless --path $project -s res://tests/run_tests.gd -- @userArgs
exit $LASTEXITCODE
