extends RefCounted
## Gera a população de um bairro (docs/07): famílias por casa, nomes da comunidade, idades,
## ocupações, traços, segredos e relações (família, amizade, desafeto, trabalho).
##
## Toda aleatoriedade vem do stream "populacao:<bairro>" do RNG do mundo: a mesma semente
## gera sempre as mesmas pessoas. As pessoas geradas são fictícias.

const Bairro := preload("res://core/mundo/bairro.gd")


## Devolve a lista de NPCs (dicionários), em ordem de id.
static func gerar(bairro: RefCounted, config: Dictionary, rng_mundo: RefCounted) -> Array[Dictionary]:
	var g: RandomNumberGenerator = rng_mundo.stream("populacao:%s" % bairro.id)
	var npcs: Array[Dictionary] = []
	var vagas := {}
	var alvo := int(bairro.dados["populacao_alvo"])
	var numero_familia := 0

	for casa in bairro.locais_do_tipo("casa"):
		if npcs.size() >= alvo:
			break
		var comunidade := _sortear_comunidade(bairro.dados["comunidades"], g)
		var nomes: Dictionary = config["nomes"].get(comunidade, config["nomes"]["brasileira"])
		var sobrenome: String = _escolher(nomes["sobrenomes"], g)
		var faixa_familia: Array = config["tamanho_familia"]
		var tamanho := mini(g.randi_range(int(faixa_familia[0]), int(faixa_familia[1])), alvo - npcs.size())
		numero_familia += 1
		var familia_id := "%s/familia_%02d" % [bairro.id, numero_familia]
		var membros: Array[Dictionary] = []

		for i in tamanho:
			var papel := "responsavel"
			if i == 1 and g.randf() < float(config["chance_conjuge"]):
				papel = "conjuge"
			elif i >= 1:
				papel = "filho"
			var faixa_idade: Array = config["idade_filho"] if papel == "filho" else config["idade_responsavel"]
			var genero := "masculino" if g.randf() < 0.5 else "feminino"
			var npc := {
				"id": "%s#%02d" % [bairro.id, npcs.size() + 1],
				"nome": _escolher(nomes["masculinos"] if genero == "masculino" else nomes["femininos"], g),
				"sobrenome": sobrenome,
				"idade": g.randi_range(int(faixa_idade[0]), int(faixa_idade[1])),
				"genero": genero,
				"comunidade": comunidade,
				"casa": casa,
				"familia": familia_id,
				"papel": papel,
				"ocupacao": {},
				"trabalho": "",
				"tracos": [],
				"segredo": "",
				"relacoes": [],
				"memorias": [],
			}
			_definir_ocupacao(npc, bairro, config, vagas, g)
			npc["tracos"] = _sortear_tracos(config, g)
			if g.randf() < float(config["chance_segredo"]):
				npc["segredo"] = _escolher(config["segredos"], g)
			npcs.append(npc)
			membros.append(npc)

		for a in membros:
			for b in membros:
				if a["id"] != b["id"]:
					a["relacoes"].append({"com": b["id"], "tipo": "familia"})

	_relacoes_sociais(npcs, config, g)
	_relacoes_de_trabalho(npcs)
	return npcs


static func _definir_ocupacao(npc: Dictionary, bairro: RefCounted, config: Dictionary, vagas: Dictionary, g: RandomNumberGenerator) -> void:
	var idade: int = npc["idade"]
	var estudante: Array = config["idade_estudante"]
	if idade < int(estudante[0]):
		npc["ocupacao"] = {"id": "crianca"}
		return
	if idade <= int(estudante[1]):
		_aplicar_ocupacao(npc, config["ocupacao_estudante"], bairro)
		return
	if idade >= int(config["idade_aposentado"]):
		npc["ocupacao"] = {"id": "aposentado"}
		return

	var candidatas: Array = []
	for ocupacao in config["ocupacoes"]:
		if int(vagas.get(ocupacao["id"], 0)) >= int(ocupacao["maximo"]):
			continue
		var local: String = ocupacao["local"]
		if local == "casa" or local == Bairro.FORA_DO_BAIRRO or not bairro.locais_do_tipo(local).is_empty():
			candidatas.append(ocupacao)
	if candidatas.is_empty():
		npc["ocupacao"] = {"id": "desempregado"}
		return
	var escolhida: Dictionary = candidatas[g.randi_range(0, candidatas.size() - 1)]
	vagas[escolhida["id"]] = int(vagas.get(escolhida["id"], 0)) + 1
	_aplicar_ocupacao(npc, escolhida, bairro)


static func _aplicar_ocupacao(npc: Dictionary, ocupacao: Dictionary, bairro: RefCounted) -> void:
	npc["ocupacao"] = ocupacao.duplicate(true)
	var local: String = ocupacao["local"]
	if local == "casa":
		npc["trabalho"] = npc["casa"]
	elif local == Bairro.FORA_DO_BAIRRO:
		npc["trabalho"] = Bairro.FORA_DO_BAIRRO
	else:
		var opcoes: Array[String] = bairro.locais_do_tipo(local)
		npc["trabalho"] = opcoes[0] if not opcoes.is_empty() else ""


static func _sortear_tracos(config: Dictionary, g: RandomNumberGenerator) -> Array:
	var faixa: Array = config["tracos_por_pessoa"]
	var quantidade := g.randi_range(int(faixa[0]), int(faixa[1]))
	var baralho: Array = config["tracos"].duplicate()
	for i in range(baralho.size() - 1, 0, -1):
		var j := g.randi_range(0, i)
		var tmp = baralho[i]
		baralho[i] = baralho[j]
		baralho[j] = tmp
	var escolhidos := baralho.slice(0, quantidade)
	escolhidos.sort()
	return escolhidos


static func _relacoes_sociais(npcs: Array[Dictionary], config: Dictionary, g: RandomNumberGenerator) -> void:
	var adultos: Array[Dictionary] = []
	for npc in npcs:
		if int(npc["idade"]) >= 16:
			adultos.append(npc)
	if adultos.size() < 2:
		return
	for tipo in ["amizade", "desafeto"]:
		var chance := float(config["chance_amizade"] if tipo == "amizade" else config["chance_desafeto"])
		for a in adultos:
			if g.randf() >= chance:
				continue
			var b: Dictionary = adultos[g.randi_range(0, adultos.size() - 1)]
			if b["id"] == a["id"] or _relacionados(a, b["id"]):
				continue
			a["relacoes"].append({"com": b["id"], "tipo": tipo})
			b["relacoes"].append({"com": a["id"], "tipo": tipo})


static func _relacoes_de_trabalho(npcs: Array[Dictionary]) -> void:
	var por_local := {}
	for npc in npcs:
		var trabalho: String = npc["trabalho"]
		if trabalho.is_empty() or trabalho == Bairro.FORA_DO_BAIRRO or trabalho == npc["casa"]:
			continue
		if not por_local.has(trabalho):
			por_local[trabalho] = []
		por_local[trabalho].append(npc)
	var locais := por_local.keys()
	locais.sort()
	for local in locais:
		var dono: Dictionary = {}
		for npc in por_local[local]:
			if npc["ocupacao"].get("dono", false):
				dono = npc
				break
		if dono.is_empty():
			continue
		for npc in por_local[local]:
			if npc["id"] != dono["id"] and not _relacionados(npc, dono["id"]):
				npc["relacoes"].append({"com": dono["id"], "tipo": "patrao"})
				dono["relacoes"].append({"com": npc["id"], "tipo": "empregado"})


static func _relacionados(npc: Dictionary, outro_id: String) -> bool:
	for relacao in npc["relacoes"]:
		if relacao["com"] == outro_id:
			return true
	return false


static func _sortear_comunidade(comunidades: Array, g: RandomNumberGenerator) -> String:
	var total := 0
	for c in comunidades:
		total += int(c["peso"])
	var sorteio := g.randi_range(1, total)
	for c in comunidades:
		sorteio -= int(c["peso"])
		if sorteio <= 0:
			return c["id"]
	return comunidades[0]["id"]


static func _escolher(lista: Array, g: RandomNumberGenerator) -> Variant:
	return lista[g.randi_range(0, lista.size() - 1)]
