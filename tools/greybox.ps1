# Abre a rua cinza da Fase 2 (greybox) para andar com o caçador.
# Uso (na raiz do repositório):
#   .\tools\greybox.ps1                          # abre a janela
#   .\tools\greybox.ps1 -Captura C:\temp\rua.png  # salva uma imagem depois de alguns quadros e fecha
param([string]$Captura = "")

. (Join-Path $PSScriptRoot 'godot.ps1')
$exe = Get-GodotExe
if (-not $exe) {
    Write-Host "Godot não encontrado. Defina GODOT_BIN ou instale: winget install --id GodotEngine.GodotEngine -e"
    exit 2
}
$project = Join-Path (Split-Path -Parent $PSScriptRoot) 'game'
& $exe --headless --path $project --import *> $null
if ($Captura) {
    # O executável de console espera a captura terminar antes de devolver o terminal.
    & $exe --path $project res://presentation/greybox/rua.tscn -- "--captura=$($Captura -replace '\\','/')"
    exit $LASTEXITCODE
}
$janela = $exe -replace '_console\.exe$', '.exe'
& $janela --path $project res://presentation/greybox/rua.tscn
exit 0
