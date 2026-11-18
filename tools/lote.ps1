# Gera um lote de casos e mostra as estatísticas do gerador.
# Uso (na raiz do repositório):
#   .\tools\lote.ps1                      # 100 casos, sementes 1 a 100
#   .\tools\lote.ps1 -Casos 500 -Inicio 1000 -Saida lote.json
#   .\tools\lote.ps1 -Bairro valongo       # casos em outro bairro (padrão: paqueta)
#   .\tools\lote.ps1 -AtualizarReferencia # regrava game/tests/baselines/lote.json (20 sementes)
# A referência só deve mudar num commit explícito, quando o gerador mudou de propósito.
param(
    [int]$Casos = 100,
    [int]$Inicio = 1,
    [string]$Saida = "",
    [string]$Bairro = "paqueta",
    [switch]$AtualizarReferencia
)

. (Join-Path $PSScriptRoot 'godot.ps1')
$exe = Get-GodotExe
if (-not $exe) {
    Write-Host "Godot não encontrado. Defina GODOT_BIN ou instale: winget install --id GodotEngine.GodotEngine -e"
    exit 2
}

$root = Split-Path -Parent $PSScriptRoot
$project = Join-Path $root 'game'
if ($AtualizarReferencia) {
    $Casos = 20
    $Inicio = 1
    $Saida = Join-Path $project 'tests/baselines/lote.json'
}

& $exe --headless --path $project --import *> $null
$userArgs = @("--casos=$Casos", "--inicio=$Inicio", "--bairro=$Bairro")
if ($Saida) { $userArgs += "--saida=$((Resolve-Path -LiteralPath (Split-Path -Parent $Saida)).Path -replace '\\','/')/$(Split-Path -Leaf $Saida)" }
& $exe --headless --path $project -s res://ferramentas/lote.gd -- @userArgs 2>&1 | ForEach-Object { "$_" } | Where-Object { $_.Trim() -ne '' -and $_ -notmatch '^Godot Engine' }
exit $LASTEXITCODE
