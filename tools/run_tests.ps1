# Roda a suíte de testes do Godot com o portão de 95%.
# Uso (na raiz do repositório):  .\tools\run_tests.ps1 [-Gate 0.95] [-Filter nome]
# Erros de script ou de parse no log reprovam a suíte, mesmo que o executor diga APROVADO.
param(
    [double]$Gate = 0.95,
    [string]$Filter = ""
)

. (Join-Path $PSScriptRoot 'godot.ps1')
$exe = Get-GodotExe
if (-not $exe) {
    Write-Host "Godot não encontrado. Defina GODOT_BIN ou instale: winget install --id GodotEngine.GodotEngine -e"
    exit 2
}

$project = Join-Path (Split-Path -Parent $PSScriptRoot) 'game'

& $exe --headless --path $project --import *> $null

$userArgs = @("--gate=$Gate")
if ($Filter) { $userArgs += "--filter=$Filter" }

$output = & $exe --headless --path $project -s res://tests/run_tests.gd -- @userArgs 2>&1 | ForEach-Object { "$_" }
$code = $LASTEXITCODE
$output | Where-Object { $_.Trim() -ne '' } | ForEach-Object { Write-Host $_ }

$engineErrors = $output | Where-Object { $_ -match 'SCRIPT ERROR|Parse Error|Failed to load script|Compile Error' }
if ($engineErrors) {
    Write-Host ""
    Write-Host "TESTES: erro de script da engine no log (reprova o portão):"
    $engineErrors | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
    exit 1
}
exit $code
