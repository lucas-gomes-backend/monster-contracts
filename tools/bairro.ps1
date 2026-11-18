# Anda num bairro do mapa real (Fase 3), montado a partir de game/data/cidade/<id>.json.
# Uso (na raiz do repositório):
#   .\tools\bairro.ps1 -Bairro valongo                 # abre a janela
#   .\tools\bairro.ps1 -Bairro monte_serrat -Semente 3  # outra semente: outros prédios
#   .\tools\bairro.ps1 -Bairro valongo -Captura C:\temp\b.png -Extra --virar=90  # imagem e fecha
param([string]$Bairro = "valongo", [int]$Semente = 1, [string]$Captura = "", [string[]]$Extra = @())

. (Join-Path $PSScriptRoot 'godot.ps1')
$exe = Get-GodotExe
if (-not $exe) {
    Write-Host "Godot não encontrado. Defina GODOT_BIN ou instale: winget install --id GodotEngine.GodotEngine -e"
    exit 2
}
$project = Join-Path (Split-Path -Parent $PSScriptRoot) 'game'
& $exe --headless --path $project --import *> $null
$userArgs = @("--bairro=$Bairro", "--semente=$Semente") + $Extra
if ($Captura) {
    & $exe --path $project res://presentation/cidade/bairro.tscn -- @userArgs "--captura=$($Captura -replace '\\','/')"
    exit $LASTEXITCODE
}
$janela = $exe -replace '_console\.exe$', '.exe'
& $janela --path $project res://presentation/cidade/bairro.tscn -- @userArgs
exit 0
