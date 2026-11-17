# Joga um caso gerado em texto, no terminal (Fase 1).
# Uso (na raiz do repositório):
#   .\tools\jogar.ps1 -Semente 7                       # interativo
#   .\tools\jogar.ps1 -Semente 7 -Comandos roteiro.txt # roda uma lista de comandos
param(
    [int]$Semente = 1,
    [string]$Comandos = ""
)

. (Join-Path $PSScriptRoot 'godot.ps1')
$exe = Get-GodotExe
if (-not $exe) {
    Write-Host "Godot não encontrado. Defina GODOT_BIN ou instale: winget install --id GodotEngine.GodotEngine -e"
    exit 2
}
$project = Join-Path (Split-Path -Parent $PSScriptRoot) 'game'
& $exe --headless --path $project --import *> $null

$userArgs = @("--semente=$Semente")
if ($Comandos) { $userArgs += "--comandos=$((Resolve-Path $Comandos).Path -replace '\\','/')" }
& $exe --headless --path $project -s res://ferramentas/jogar_texto.gd -- @userArgs
exit $LASTEXITCODE
