# Confere o tamanho dos arquivos que os agentes leem: AGENTS.md, CLAUDE.md e rules/*.md.
# Teto: 100 linhas por arquivo (rules/implementacao.md). Os docs de design (docs/) ficam de fora.
$root = Split-Path -Parent $PSScriptRoot
$limit = 100
$files = @()
foreach ($f in 'AGENTS.md', 'CLAUDE.md') {
    $p = Join-Path $root $f
    if (Test-Path $p) { $files += Get-Item $p }
}
$rulesDir = Join-Path $root 'rules'
if (Test-Path $rulesDir) { $files += Get-ChildItem $rulesDir -Filter *.md -Recurse }

$bad = 0
foreach ($file in $files) {
    $lines = (Get-Content $file.FullName -Encoding UTF8 | Measure-Object -Line).Lines
    if ($lines -gt $limit) {
        Write-Host ("DOCS: {0} tem {1} linhas (teto {2})" -f $file.Name, $lines, $limit)
        $bad++
    }
}
if ($bad -gt 0) { exit 1 }
Write-Host ("DOCS: {0} arquivos dentro do teto de {1} linhas" -f $files.Count, $limit)
exit 0
