# Joga um caso gerado (Fase 1).
# Uso (na raiz do repositório):
#   .\tools\jogar.ps1 -Semente 7                       # abre a janela, com botões
#   .\tools\jogar.ps1 -Semente 7 -Texto                # no terminal, digitando comandos
#   .\tools\jogar.ps1 -Semente 7 -Comandos roteiro.txt # no terminal, com uma lista de comandos
param(
    [int]$Semente = 1,
    [switch]$Texto,
    [string]$Comandos = ""
)

. (Join-Path $PSScriptRoot 'godot.ps1')
$exe = Get-GodotExe
if (-not $exe) {
    Write-Host "Godot não encontrado. Defina GODOT_BIN ou instale: winget install --id GodotEngine.GodotEngine -e"
    exit 2
}
$project = Join-Path (Split-Path -Parent $PSScriptRoot) 'game'
# O jogo fala em UTF-8 (acentos). Sem isso, o console do Windows embaralha "ã", "ç", "é".
[Console]::OutputEncoding = [Text.Encoding]::UTF8
[Console]::InputEncoding = [Text.Encoding]::UTF8
& $exe --headless --path $project --import *> $null

if (-not $Texto -and -not $Comandos) {
    # Janela: o executável com janela (sem "_console") não prende o terminal.
    $janela = $exe -replace '_console\.exe$', '.exe'
    & $janela --path $project -- "--semente=$Semente"
    exit 0
}

$userArgs = @("--semente=$Semente")
if ($Comandos) { $userArgs += "--comandos=$((Resolve-Path $Comandos).Path -replace '\\','/')" }
& $exe --headless --path $project -s res://ferramentas/jogar_texto.gd -- @userArgs
exit $LASTEXITCODE
