# Prova que o portão reprova de verdade. Cria um "mutante" por vez, roda o verify.ps1
# e exige que ele FALHE. Depois apaga o mutante. Rode quando mudar o portão ou as regras.
# Uso (na raiz do repositório):  .\tools\verify-mutation.ps1
$root = Split-Path -Parent $PSScriptRoot
$verify = Join-Path $PSScriptRoot 'verify.ps1'

$mutants = @(
    @{ name = 'um único teste que falha';    path = 'game/tests/unit/test_mutante.gd';
       body = "extends `"res://tests/framework/test_case.gd`"`nfunc test_mutante_falha() -> void:`n`tassert_eq(1, 2)`n" },
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
       find = 'minuto < _eventos[-1]["minuto"]'; replace = 'false' },
    @{ name = 'NPC trabalha em casa em vez do trabalho'; path = 'game/core/npcs/rotina.gd';
       find = 'return {"local": npc["trabalho"], "atividade": "trabalhando"}'; replace = 'return {"local": npc["casa"], "atividade": "trabalhando"}' },
    @{ name = 'quem dorme pesado também ouve'; path = 'game/core/npcs/presenca.gd';
       find = '(acordado or "sono_leve" in npc["tracos"])'; replace = 'true' },
    @{ name = 'amizade só de um lado'; path = 'game/core/npcs/gerador_populacao.gd';
       find = 'b["relacoes"].append({"com": a["id"], "tipo": tipo})'; replace = 'pass' },
    @{ name = 'chuva não apaga pegadas'; path = 'game/core/casos/pistas.gd';
       find = 'if onde == "cena" and chuva_em >= 0 and chuva_em > minuto:'; replace = 'if false:' },
    @{ name = 'hospedeiro não some durante o ataque'; path = 'game/core/casos/gerador_casos.gd';
       find = 'hospedeiro["ausencias"].append([saida, e["minuto"] + 60, e["local"]])'; replace = 'pass' },
    @{ name = 'mentira sem ninguém para desmentir'; path = 'game/core/casos/testemunhas.gd';
       find = 'posicao["atividade"] == "lazer" and not viu_pessoas.is_empty()'; replace = 'posicao["local"] != npc["casa"]' },
    @{ name = 'família entrega o sumiço'; path = 'game/core/casos/testemunhas.gd';
       find = 'continue  # a família não conta'; replace = 'pass  # a família não conta' },
    @{ name = 'medroso não exagera'; path = 'game/core/casos/testemunhas.gd';
       find = 'if i < 0 or not medroso:'; replace = 'if true:' },
    @{ name = 'solucionador aceita uma só evidência'; path = 'game/core/casos/solucionador.gd';
       find = 'const MINIMO_EVIDENCIAS := 2'; replace = 'const MINIMO_EVIDENCIAS := 1' },
    @{ name = 'ruído descarta espécies'; path = 'game/core/casos/solucionador.gd';
       find = 'if vocabulario.has(ev["tag"]) and not tags_especie.has(ev["tag"]):'; replace = 'if not tags_especie.has(ev["tag"]):' },
    @{ name = 'um boletim vira padrão'; path = 'game/core/casos/solucionador.gd';
       find = 'const MINIMO_BOLETINS_PADRAO := 2'; replace = 'const MINIMO_BOLETINS_PADRAO := 1' },
    @{ name = 'gerador muda sem atualizar a referência'; path = 'game/data/config/casos.json';
       find = '"chance_boletim": 0.5'; replace = '"chance_boletim": 0.9' },
    @{ name = 'sessão acha pista vencida'; path = 'game/core/investigacao/sessao.gd';
       find = 'if not _detectavel(pista) or not Pistas.disponivel(pista, minuto):'; replace = 'if not _detectavel(pista):' },
    @{ name = 'sessão acha pista de outro lugar'; path = 'game/core/investigacao/sessao.gd';
       find = 'if pista["tipo"] != "marca" or pista["local"] != local:'; replace = 'if pista["tipo"] != "marca":' },
    @{ name = 'caderno não filtra as compatíveis'; path = 'game/core/caderno/caderno.gd';
       find = 'if not _especies[id].has(tag):'; replace = 'if false:' },
    @{ name = 'caderno liga evidência que não tem'; path = 'game/core/caderno/caderno.gd';
       find = 'if not _pistas.has(fonte) and not _depoimentos.has(fonte):'; replace = 'if false:' },
    @{ name = 'qualquer prova desmente'; path = 'game/core/investigacao/sessao.gd';
       find = 'if desmente(prova, dep):'; replace = 'if true:' },
    @{ name = 'entrevista quem não está aqui'; path = 'game/core/investigacao/sessao.gd';
       find = 'return {"ok": false, "erro": "essa pessoa não está aqui agora", "novos": [], "minutos": 0}'; replace = 'pass' },
    @{ name = 'ferimento revela qualquer pessoa'; path = 'game/core/investigacao/regras_de_campo.gd';
       find = 'return not alvo.is_empty() and alvo == verdade["hospedeiro"]'; replace = 'return true' },
    @{ name = 'desfecho ignora a pessoa'; path = 'game/core/investigacao/regras_de_campo.gd';
       find = 'base["quem_certo"] = not precisa_quem or alvo == verdade["hospedeiro"]'; replace = 'base["quem_certo"] = true' },
    @{ name = 'relatório ignora os lugares visitados'; path = 'game/core/investigacao/relatorio.gd';
       find = 'if not sessao.visitas.has(pista["local"]):'; replace = 'if false:' },
    @{ name = 'relatório troca certas por erradas'; path = 'game/core/investigacao/relatorio.gd';
       find = '(certas if tag in marcas_da_fonte.get(fonte, []) else erradas)'; replace = '(erradas if tag in marcas_da_fonte.get(fonte, []) else certas)' },
    @{ name = 'caçador anda sem olhar para a câmera'; path = 'game/presentation/personagem/cacador.gd';
       find = 'var frente := Vector3(-sin(yaw_rad), 0.0, -cos(yaw_rad))'; replace = 'var frente := Vector3(0.0, 0.0, -1.0)' },
    @{ name = 'câmera sem limite de inclinação'; path = 'game/presentation/personagem/cacador.gd';
       find = 'return clampf(graus, cfg["inclinacao_minima"], cfg["inclinacao_maxima"])'; replace = 'return graus' },
    @{ name = 'foto ignora o alcance'; path = 'game/presentation/inspecao/mira.gd';
       find = 'if origem.distance_to(ponto) <= alcance and angulo_ate'; replace = 'if angulo_ate' },
    @{ name = 'filme nunca acaba'; path = 'game/presentation/inspecao/album.gd';
       find = 'if restantes() <= 0:'; replace = 'if false:' }
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
