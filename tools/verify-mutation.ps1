# Prova que o portão reprova de verdade. Cria um "mutante" por vez, roda o verify.ps1
# e exige que ele FALHE. Depois apaga o mutante. Rode quando mudar o portão ou as regras.
# Uso (na raiz do repositório):
#   .\tools\verify-mutation.ps1                                  # todos (pesado: 40+ rodadas do portão)
#   .\tools\verify-mutation.ps1 -Somente degrau,filme -Pausa 60  # só os que têm esse texto no nome,
#                                                               # esperando 60 s entre um e outro
#   -SemConferencia pula a rodada inicial sem mutantes (para lotes seguidos, já conferidos).
# Se o PC desligar no meio, o arquivo alterado fica guardado em tools/.mutante_pendente.json
# e é restaurado na próxima vez que este script rodar.
param(
    [string[]]$Somente = @(),
    [int]$Pausa = 0,
    [switch]$SemConferencia
)
$root = Split-Path -Parent $PSScriptRoot
$verify = Join-Path $PSScriptRoot 'verify.ps1'
$pendente = Join-Path $PSScriptRoot '.mutante_pendente.json'

# Restaura o que uma execução interrompida (desligamento, Ctrl+C) deixou alterado.
if (Test-Path $pendente) {
    $p = Get-Content $pendente -Raw -Encoding UTF8 | ConvertFrom-Json
    $alvo = Join-Path $root $p.path
    if ($null -ne $p.original) {
        [IO.File]::WriteAllText($alvo, $p.original, (New-Object Text.UTF8Encoding($false)))
    } else {
        Remove-Item "$alvo*" -Force -ErrorAction SilentlyContinue
    }
    Remove-Item $pendente -Force
    Write-Host ("Restaurado o arquivo deixado por uma execução interrompida: {0}" -f $p.path)
}

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
if (-not $SemConferencia) {
    & $verify *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "VERIFY-MUTATION: o verify.ps1 já falha sem mutantes. Corrija o projeto antes."
        exit 2
    }
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
       find = 'if _detectavel(pista) and Pistas.disponivel(pista, minuto):'; replace = 'if _detectavel(pista):' },
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
       find = 'if restantes() <= 0:'; replace = 'if false:' },
    @{ name = 'caçador não sobe degrau'; path = 'game/presentation/personagem/cacador.gd';
       find = '	_subir_degrau(delta)'; replace = '	pass' },
    @{ name = 'pistas de outros lugares aparecem aqui'; path = 'game/core/investigacao/sessao.gd';
       find = 'if pista["tipo"] != "marca" or pista["local"] != _local_atual:'; replace = 'if pista["tipo"] != "marca":' },
    @{ name = 'lote invade a rua'; path = 'game/core/cidade/lotes.gd';
       find = 'if distancia_segmento_poligono(pontos[s], pontos[s + 1], meus) < folga:'; replace = 'if false:' },
    @{ name = 'galeria sem parede'; path = 'game/presentation/cidade/bairro_3d.gd';
       find = 'subterraneo.add_child(corpo)'; replace = 'pass' },
    @{ name = 'parede corta o cruzamento'; path = 'game/core/cidade/subterraneo.gd';
       find = 'return dentro_da_galeria(meio + normal, corredores) != dentro_da_galeria(meio - normal, corredores)'; replace = 'return true' },
    @{ name = 'cruzar a linha não troca o bairro'; path = 'game/presentation/cidade/bairro_cena.gd';
       find = 'entrar_em(onde)'; replace = 'pass' },
    @{ name = 'minimapa não gira'; path = 'game/presentation/cidade/minimapa.gd';
       find = '(ponto - centro_mundo).rotated(giro) * ESCALA'; replace = '(ponto - centro_mundo) * ESCALA' },
    @{ name = 'esgoto de cada bairro separado'; path = 'game/presentation/cidade/bairro_cena.gd';
       find = 'subterraneo.montar(Sub.gerar_rede(dados, cfg, Rng.new(semente)), cfg, area.grow(10.0))'; replace = 'subterraneo.montar(Sub.gerar_rede([dados[0]], cfg, Rng.new(semente)), cfg, area.grow(10.0))' },
    @{ name = 'gente atravessa os prédios'; path = 'game/presentation/cidade/populacao_3d.gd';
       find = 'p["rota"] = _caminhos.caminho(de, para)'; replace = 'p["rota"] = PackedVector2Array([de, para])' },
    @{ name = 'gente fora da rotina'; path = 'game/presentation/cidade/populacao_3d.gd';
       find = 'var estado: Dictionary = _rotina.onde_esta(npc, minuto)'; replace = 'var estado: Dictionary = _rotina.onde_esta(npc, 0)' },
    @{ name = 'transeunte para no destino'; path = 'game/presentation/cidade/transeuntes_3d.gd';
       find = '			else:' + "`n" + '				_nova_rota(a)'; replace = '			else:' + "`n" + '				pass' },
    @{ name = 'ponto-chave sem placa'; path = 'game/presentation/cidade/populacao_3d.gd';
       find = 'placas.append(placa)'; replace = 'pass' },
    @{ name = 'polícia não persegue'; path = 'game/presentation/cidade/policia_3d.gd';
       find = 'p["perseguindo"] = deve and i == 0 and'; replace = 'p["perseguindo"] = false and' },
    @{ name = 'maré alta não alaga'; path = 'game/presentation/cidade/bairro_cena.gd';
       find = 'if mare.galerias_alagadas(minuto):'; replace = 'if false:' },
    @{ name = 'covil não conta para o bairro'; path = 'game/core/casos/solucionador.gd';
       find = '		if covil in tipos_de_locais:'; replace = '		if false:' },
    @{ name = 'provocado no início da pré-simulação'; path = 'game/core/casos/gerador_casos.gd';
       find = 'hora_da_provocacao = total_horas - '; replace = 'hora_da_provocacao = 0 * total_horas - ' },
    @{ name = 'ninguém nota o culpado sair'; path = 'game/core/casos/gerador_casos.gd';
       find = '_registrar_quem_notou(npcs, culpado, rotina'; replace = '_registrar_quem_notou([] as Array[Dictionary], culpado, rotina' },
    @{ name = 'crime não deixa marca'; path = 'game/core/casos/gerador_casos.gd';
       find = '			for marca in c["marcas"]:'; replace = '			for marca in []:' },
    @{ name = 'teste não pega pelo que a criatura é'; path = 'game/core/investigacao/regras_de_campo.gd';
       find = 'if not tem_fraqueza and not _pega_pelo_que_e(teste, ficha_verdade):'; replace = 'if not tem_fraqueza:' },
    @{ name = 'carta sem a família de quem morreu'; path = 'game/core/casos/cartas.gd';
       find = '	if desfecho.get("amaldicoado_morto", false):'; replace = '	if false:' },
    @{ name = 'contenção não se desgasta'; path = 'game/core/confronto/estado_criatura.gd';
       find = '		restante -= segundos'; replace = '		restante -= 0.0' },
    @{ name = 'crítico não mata'; path = 'game/core/confronto/ferimentos.gd';
       find = '			morto = true'; replace = '			morto = false' },
    @{ name = 'medo não atrapalha a mira'; path = 'game/core/confronto/arsenal.gd';
       find = '(1.0 + tremor * float(_cfg["tremor_multiplica_dispersao"]))'; replace = '1.0' },
    @{ name = 'sal não barra a criatura'; path = 'game/presentation/cidade/criatura_3d.gd';
       find = '	if Circulo.barra(ficha):'; replace = '	if false:' },
    @{ name = 'palavra errada não falha o ritual'; path = 'game/core/confronto/ritual.gd';
       find = '		situacao = FALHOU'; replace = '		pass' },
    @{ name = 'ritual errado não enfurece'; path = 'game/presentation/cidade/bairro_cena.gd';
       find = '			criatura.estado.enfurecer()'; replace = '			pass' },
    @{ name = 'acordo sem agradar antes'; path = 'game/core/confronto/negociacao.gd';
       find = '		if satisfacao >= int(_cfg["satisfacao_para_acordo"]):'; replace = '		if true:' },
    @{ name = 'furioso aceita a oferenda'; path = 'game/presentation/cidade/bairro_cena.gd';
       find = 'criatura.estado.agressividade > int(_cfg_negociacao["apaziguar_ate_agressividade"])'; replace = 'false' },
    @{ name = 'itens se sobrepõem na grade'; path = 'game/core/inventario/grade.gd';
       find = '		if x < e["x"] + e["w"] and e["x"] < x + w and y < e["y"] + e["h"] and e["y"] < y + h:'; replace = '		if false:' },
    @{ name = 'recarga não gasta munição'; path = 'game/presentation/cidade/bairro_cena.gd';
       find = '	mochila.retirar(item, vai)'; replace = '	pass' },
    @{ name = 'arma fora da mochila pode ser usada'; path = 'game/presentation/cidade/bairro_cena.gd';
       find = '	return int(arsenal.arma_de(id)["capacidade"]) == 0 or mochila.quantidade(id) > 0'; replace = '	return true' },
    @{ name = 'paga fora do prazo'; path = 'game/core/progressao/progresso.gd';
       find = '		ganho = int(desfecho.get("recompensa", 0))'; replace = '		ganho = int(contrato.get("recompensa", 0))' },
    @{ name = 'carro anda sem gasolina'; path = 'game/presentation/cidade/carro_3d.gd';
       find = '	if litros <= 0.0:'; replace = '	if false:' },
    @{ name = 'viagem rápida não gasta gasolina'; path = 'game/presentation/cidade/bairro_cena.gd';
       find = '	carro.litros -= float(d["litros"])'; replace = '	pass' },
    @{ name = 'sem teto de habilidades'; path = 'game/core/progressao/habilidades.gd';
       find = '	if pontos_gastos() >= int(_cfg["teto_de_pontos"]):'; replace = '	if false:' },
    @{ name = 'duas condições ao mesmo tempo'; path = 'game/core/condicoes/condicao.gd';
       find = '		return {"ok": false, "motivo": "já é %s: uma condição por vez" % _cfg[id]["nome"]}'; replace = '		pass' },
    @{ name = 'sensitivo sente corpo'; path = 'game/core/condicoes/condicao.gd';
       find = 'ficha.get("natureza", "") in _c()["sente_naturezas"] and '; replace = '' },
    @{ name = 'interlúdio não sara'; path = 'game/presentation/cidade/bairro_cena.gd';
       find = '		for k in int(e["cura_graus"]):'; replace = '		for k in 0:' },
    @{ name = 'disfarce não muda a suspeita'; path = 'game/presentation/cidade/bairro_cena.gd';
       find = 'suspeita.visto(id, minuto, cacador.aparencia.efeito("suspeita_de_quem_ve"))'; replace = 'suspeita.visto(id, minuto)' },
    @{ name = 'postes não acendem'; path = 'game/presentation/cidade/bairro_cena.gd';
       find = '	var acesos := noite > 0.5 and zona == "rua"'; replace = '	var acesos := false' },
    @{ name = 'tutorial pula o teste de campo'; path = 'game/core/investigacao/tutorial.gd';
       find = '			return sessao._testes_feitos > 0'; replace = '			return true' },
    @{ name = 'morte devolve a mochila inteira'; path = 'game/core/progressao/volta_da_morte.gd';
       find = '	var quantos := mini(int(ceil(ns.size() * fracao)), ns.size())'; replace = '	var quantos := 0' },
    @{ name = 'volta da morte sempre igual'; path = 'game/core/progressao/volta_da_morte.gd';
       find = '	var extra := maxi(volta - 1, 0)'; replace = '	var extra := 0' },
    @{ name = 'cliente exposto nao conta'; path = 'game/core/investigacao/regras_de_campo.gd';
       find = '		base["cliente_exposto"] = true'; replace = '		base["cliente_exposto"] = false' },
    @{ name = 'prender o saci nao fere inocente'; path = 'game/core/investigacao/regras_de_campo.gd';
       find = '		base["criatura_inocente"] = true'; replace = '		base["criatura_inocente"] = false' },
    @{ name = 'inofensiva pode ser culpada'; path = 'game/core/casos/gerador_casos.gd';
       find = '		if int(ficha["perigo"]) == 0:'; replace = '		if false:' },
    @{ name = 'arranhao leve passa condicao'; path = 'game/core/condicoes/condicao.gd';
       find = '	if not gravidade in ["grave", "critico"]:'; replace = '	if gravidade == "nenhum":' },
    @{ name = 'estigma nao soma'; path = 'game/core/mundo/suspeita.gd';
       find = '	if fator <= 0.0:'; replace = '	if true:' },
    @{ name = 'prata sai como bala comum'; path = 'game/core/confronto/arsenal.gd';
       find = '			item = str(tiros.pop_front())'; replace = '			tiros.pop_front()' },
    @{ name = 'bolsos sem limite'; path = 'game/core/confronto/bolsos.gd';
       find = '	if itens.size() >= LUGARES:'; replace = '	if false:' }
)

if ($Somente.Count -gt 0) {
    $mutants = @($mutants | Where-Object { $nome = $_.name; @($Somente | Where-Object { $nome -like "*$_*" }).Count -gt 0 })
    Write-Host ("Rodando {0} mutante(s): {1}" -f $mutants.Count, (($mutants | ForEach-Object { $_.name }) -join '; '))
}

$survivors = @()
$primeiro = $true
foreach ($m in $mutants) {
    if (-not $primeiro -and $Pausa -gt 0) { Start-Sleep -Seconds $Pausa }
    $primeiro = $false
    $full = Join-Path $root $m.path
    if ($m.ContainsKey('find')) {
        $original = [IO.File]::ReadAllText($full, [Text.Encoding]::UTF8)
        if (-not $original.Contains($m.find)) {
            Write-Host ("MUTANTE INVÁLIDO (trecho não encontrado): {0}" -f $m.name)
            $survivors += $m.name
            continue
        }
        @{ path = $m.path; original = $original } | ConvertTo-Json | Set-Content $pendente -Encoding UTF8
        [IO.File]::WriteAllText($full, $original.Replace($m.find, $m.replace), (New-Object Text.UTF8Encoding($false)))
        & $verify *> $null
        $code = $LASTEXITCODE
        [IO.File]::WriteAllText($full, $original, (New-Object Text.UTF8Encoding($false)))
        Remove-Item $pendente -Force
    } else {
        @{ path = $m.path; original = $null } | ConvertTo-Json | Set-Content $pendente -Encoding UTF8
        Set-Content -Path $full -Value $m.body -Encoding UTF8 -NoNewline
        & $verify *> $null
        $code = $LASTEXITCODE
        Remove-Item "$full*" -Force -ErrorAction SilentlyContinue
        Remove-Item $pendente -Force
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
