# Prova que o portão reprova de verdade. Cria um "mutante" por vez, roda o verify.ps1
# e exige que ele FALHE. Depois apaga o mutante. Rode quando mudar o portão ou as regras.
# Uso (na raiz do repositório):  .\tools\verify-mutation.ps1
$root = Split-Path -Parent $PSScriptRoot
$verify = Join-Path $PSScriptRoot 'verify.ps1'

# Quantas falhas comuns derrubam a taxa abaixo de 95%: depende do tamanho da suíte.
$testCount = (Get-ChildItem (Join-Path $root 'game/tests') -Recurse -Filter 'test_*.gd' |
    Select-String -Pattern '^func test_' | Measure-Object).Count
$failCount = [math]::Max(3, [math]::Ceiling($testCount * 0.06) + 1)
$failBody = "extends `"res://tests/framework/test_case.gd`"`n"
for ($i = 0; $i -lt $failCount; $i++) { $failBody += "func test_mutante_$i() -> void:`n`tassert_eq(1, 2)`n" }

$mutants = @(
    @{ name = "falhas comuns abaixo de 95% ($failCount de ~$testCount)"; path = 'game/tests/unit/test_mutante.gd';
       body = $failBody },
    @{ name = 'um teste obrigatório que falha'; path = 'game/tests/unit/test_mutante.gd';
       body = "extends `"res://tests/framework/test_case.gd`"`nconst OBRIGATORIO := true`nfunc test_mutante_obrigatorio() -> void:`n`tassert_eq(1, 2)`n" },
    @{ name = 'métrica abaixo do portão';    path = 'game/tests/unit/test_mutante.gd';
       body = "extends `"res://tests/framework/test_case.gd`"`nfunc test_mutante_metrica() -> void:`n`trecord_metric(`"casos_validos`", 0.5)`n" },
    @{ name = 'randi() no núcleo';           path = 'game/core/mutante.gd';
       body = "extends RefCounted`nfunc sortear() -> int:`n`treturn randi()`n" },
    @{ name = 'núcleo dependendo de cena';   path = 'game/core/mutante.gd';
       body = "extends Node`n" },
    @{ name = 'erro de parse em teste';      path = 'game/tests/unit/test_mutante.gd';
       body = "extends `"res://tests/framework/test_case.gd`"`nfunc test_mutante_quebrado() -> void`n`tassert_true(true)`n" },
    @{ name = 'ficha de criatura inválida';   path = 'game/data/creatures/mutante.json';
       body = "{`"id`": `"mutante`", `"nome`": `"Sem o resto da ficha`"}" },
    @{ name = 'duas criaturas indistinguíveis'; path = 'game/data/creatures/lobisomem_clone.json';
       body = ([IO.File]::ReadAllText((Join-Path $root 'game/data/creatures/lobisomem_br.json'), [Text.Encoding]::UTF8) -replace '"id": "lobisomem_br"', '"id": "lobisomem_clone"') },
    @{ name = 'regra com mais de 100 linhas'; path = 'rules/mutante.md';
       body = (("linha`n") * 150) }
)

# Sem mutante, o portão precisa estar verde. Senão "mutante morto" não prova nada.
& $verify *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "VERIFY-MUTATION: o verify.ps1 já falha sem mutantes. Corrija o projeto antes."
    exit 2
}

# Mutantes que ALTERAM código existente (trocam um trecho e depois restauram o arquivo).
$mutants += @(
    @{ name = 'lobisomem ignora o dia da semana'; path = 'game/core/criaturas/criatura.gd';
       find = 'return nome_dia == dias[0]'; replace = 'return true' },
    @{ name = 'marca sem ligação com o ataque'; path = 'game/core/criaturas/criatura.gd';
       find = '"evento_origem": ataque["id"],'; replace = '"evento_origem": -1,' },
    @{ name = 'registro aceita evento no passado'; path = 'game/core/eventos/registro.gd';
       find = 'minuto < _eventos[-1]["minuto"]'; replace = 'false' }
)

$survivors = @()
foreach ($m in $mutants) {
    $full = Join-Path $root $m.path
    if ($m.ContainsKey('find')) {
        $original = [IO.File]::ReadAllText($full, [Text.Encoding]::UTF8)
        if (-not $original.Contains($m.find)) {
            Write-Host ("MUTANTE INVÁLIDO (trecho não encontrado): {0}" -f $m.name)
            $survivors += $m.name
            continue
        }
        [IO.File]::WriteAllText($full, $original.Replace($m.find, $m.replace), (New-Object Text.UTF8Encoding($false)))
        & $verify *> $null
        $code = $LASTEXITCODE
        [IO.File]::WriteAllText($full, $original, (New-Object Text.UTF8Encoding($false)))
    } else {
        Set-Content -Path $full -Value $m.body -Encoding UTF8 -NoNewline
        & $verify *> $null
        $code = $LASTEXITCODE
        Remove-Item "$full*" -Force -ErrorAction SilentlyContinue
    }
    if ($code -eq 0) {
        Write-Host ("MUTANTE SOBREVIVEU: {0}" -f $m.name)
        $survivors += $m.name
    } else {
        Write-Host ("mutante morto: {0}" -f $m.name)
    }
}

if ($survivors.Count -gt 0) {
    Write-Host ("VERIFY-MUTATION: REPROVADO. O portão não pegou: {0}" -f ($survivors -join '; '))
    exit 1
}
Write-Host "VERIFY-MUTATION: APROVADO. O portão reprovou todos os mutantes."
exit 0
