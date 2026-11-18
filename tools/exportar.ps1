# Gera uma versão do jogo para testar no Windows: build/MonsterContracts.zip
# (MonsterContracts.exe + MonsterContracts.pck). Uso (na raiz do repositório):
#   .\tools\exportar.ps1
# Não precisa dos "export templates": o .exe é o próprio Godot da máquina, que abre
# sozinho o .pck com o mesmo nome ao lado dele.
. (Join-Path $PSScriptRoot 'godot.ps1')
$exe = Get-GodotExe
if (-not $exe) {
    Write-Host "Godot não encontrado. Defina GODOT_BIN ou instale: winget install --id GodotEngine.GodotEngine -e"
    exit 2
}
$root = Split-Path -Parent $PSScriptRoot
$project = Join-Path $root 'game'
$pasta = Join-Path $root 'build\MonsterContracts'
if (Test-Path $pasta) { Remove-Item -Recurse -Force $pasta }
New-Item -ItemType Directory -Force $pasta | Out-Null
& $exe --headless --path $project --import *> $null
$pck = Join-Path $pasta 'MonsterContracts.pck'
& $exe --headless --path $project --export-pack "Windows Desktop" ($pck.Replace('\', '/')) 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -match 'ERROR|error' }
if (-not (Test-Path $pck)) {
    Write-Host "Falhou: o .pck não foi gerado."
    exit 1
}
$janela = $exe -replace '_console\.exe$', '.exe'
Copy-Item $janela (Join-Path $pasta 'MonsterContracts.exe')
Set-Content -Path (Join-Path $pasta 'LEIA-ME.txt') -Encoding utf8 -Value @'
Monster Contracts - corte vertical (versão de teste)

Abra MonsterContracts.exe. O MonsterContracts.pck precisa ficar na mesma pasta.
Na cidade: clique para prender o mouse, Esc solta. WASD anda, E entra no carro,
usa bueiros e o motel, M abre o mapa de viagem (no carro), I abre a mochila.

Mapa: © colaboradores do OpenStreetMap (ODbL).
'@
$zip = Join-Path $root 'build\MonsterContracts.zip'
if (Test-Path $zip) { Remove-Item -Force $zip }
Compress-Archive -Path $pasta -DestinationPath $zip
Write-Host ("Pronto: {0} ({1:N0} MB)" -f $zip, ((Get-Item $zip).Length / 1MB))
exit 0
