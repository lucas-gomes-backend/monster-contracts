# PORTÃO ÚNICO do projeto. Precisa sair 0 antes de dizer "pronto" e antes de cada commit.
# Uso (na raiz do repositório):  .\tools\verify.ps1
# Etapas: tamanho dos arquivos de regras -> testes do importador da cidade (Python) -> testes do Godot (100% dos testes, métricas >= 95%; inclui arquitetura e determinismo).
param([double]$Gate = 0.95)

$failed = @()

Write-Host "== verify: documentação de regras =="
& (Join-Path $PSScriptRoot 'check-docs.ps1')
if ($LASTEXITCODE -ne 0) { $failed += 'docs' }

Write-Host ""
Write-Host "== verify: importador da cidade (Python) =="
$python = $null
foreach ($nome in 'python', 'python3') {
    $cmd = Get-Command $nome -ErrorAction SilentlyContinue
    if ($cmd) { $python = $cmd.Source; break }
}
if (-not $python) {
    Write-Host "Python não encontrado (precisa do Python 3 para os testes do importador)."
    $failed += 'importador'
} else {
    $env:PYTHONIOENCODING = 'utf-8'
    & $python -I -W ignore -m unittest discover -s (Join-Path $PSScriptRoot 'cidade/testes') 2>&1 | Select-Object -Last 3
    if ($LASTEXITCODE -ne 0) { $failed += 'importador' }
}

Write-Host ""
Write-Host "== verify: testes =="
& (Join-Path $PSScriptRoot 'run_tests.ps1') -Gate $Gate
if ($LASTEXITCODE -ne 0) { $failed += 'testes' }

Write-Host ""
if ($failed.Count -gt 0) {
    Write-Host ("VERIFY: REPROVADO ({0})" -f ($failed -join ', '))
    exit 1
}
Write-Host "VERIFY: APROVADO"
exit 0
