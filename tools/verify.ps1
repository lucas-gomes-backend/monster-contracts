# PORTÃO ÚNICO do projeto. Precisa sair 0 antes de dizer "pronto" e antes de cada commit.
# Uso (na raiz do repositório):  .\tools\verify.ps1
# Etapas: tamanho dos arquivos de regras -> testes do Godot (portão de 95%, inclui arquitetura e determinismo).
param([double]$Gate = 0.95)

$failed = @()

Write-Host "== verify: documentação de regras =="
& (Join-Path $PSScriptRoot 'check-docs.ps1')
if ($LASTEXITCODE -ne 0) { $failed += 'docs' }

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
