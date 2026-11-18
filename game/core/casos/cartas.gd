extends RefCounted
## Cartas e presentes depois do caso (docs/04, "Cartas e presentes"). Saem do desfecho e da
## verdade do caso: citam nomes, lugares e o que aconteceu. Os textos são dados
## (data/textos/cartas.json). Mesma semente e mesmo desfecho, mesmas cartas.
##
## Cada carta: {"situacao", "de" (cliente, testemunha, familia, acusado, ninguem),
##              "remetente" (id do NPC ou ""), "texto", "presente" (ou "")}

const Rng := preload("res://core/rng.gd")
const Bairro := preload("res://core/mundo/bairro.gd")

## Quais situações o desfecho produz, em ordem. "encerram": as resoluções que acabam com os
## ataques (config/testes_de_campo.json, resolucoes_que_encerram_os_ataques).
static func situacoes(desfecho: Dictionary, encerram: Array) -> Array[String]:
	var lista: Array[String] = []
	if desfecho.is_empty():
		return lista
	var resolucao: String = desfecho["resolucao"]
	if desfecho.get("sucesso", false) and resolucao in encerram and not desfecho.get("prazo_estourado", false):
		lista.append("pessoas_salvas")
		if resolucao in ["apaziguar", "negociar"]:
			lista.append("criatura_poupada")
		if resolucao == "expor":
			lista.append("cliente_exposto")
	else:
		lista.append("vitimas_por_demora")
	if desfecho.get("cliente_exposto", false) and not "cliente_exposto" in lista:
		lista.append("cliente_exposto")
	if desfecho.get("amaldicoado_morto", false):
		lista.append("amaldicoado_morto")
	if not str(desfecho.get("inocente_prejudicado", "")).is_empty():
		lista.append("inocente_prejudicado")
	return lista


static func gerar(caso: Dictionary, desfecho: Dictionary, criaturas: Dictionary, dados_bairro: Dictionary, textos: Dictionary, encerram: Array) -> Array[Dictionary]:
	var cartas: Array[Dictionary] = []
	var g: RandomNumberGenerator = Rng.new(int(caso["sub_semente"])).stream("cartas")
	var bairro := Bairro.new(dados_bairro)
	var por_id := {}
	for npc in caso["npcs"]:
		por_id[npc["id"]] = npc
	var verdade: Dictionary = caso["verdade"]
	var ataques: Array = caso["registro"].buscar("criatura.ataque", verdade["instancia"])
	var local_id: String = ataques[-1]["local"] if not ataques.is_empty() else ""
	var base := {
		"cliente": _nome(por_id.get(caso["contrato"]["cliente"], {})),
		"criatura": criaturas.get(verdade["especie"], {}).get("nome", ""),
		"local": bairro.local(local_id).get("nome", "o bairro") if not local_id.is_empty() else "o bairro",
		"bairro": dados_bairro.get("nome", ""),
	}
	for situacao in situacoes(desfecho, encerram):
		var pessoa_id := _pessoa_da_situacao(situacao, verdade, desfecho)
		var modelos: Array = textos["situacoes"][situacao]
		var usados := {}  # o mesmo modelo não se repete na mesma situação, se houver outro
		for remetente in _remetentes(situacao, modelos, caso, pessoa_id, por_id, ataques, textos, g):
			var possiveis: Array = modelos.filter(func(m): return m["de"] == remetente["de"])
			var novos: Array = possiveis.filter(func(m): return not usados.has(m["texto"]))
			if not novos.is_empty():
				possiveis = novos
			var modelo: Dictionary = possiveis[g.randi_range(0, possiveis.size() - 1)]
			usados[modelo["texto"]] = true
			var pessoa: Dictionary = por_id.get(pessoa_id, {})
			var trocas := base.duplicate()
			trocas["remetente"] = _nome(por_id.get(remetente["id"], {}))
			trocas["pessoa"] = _nome(pessoa)
			trocas["ocupacao"] = str(pessoa.get("ocupacao", {}).get("id", "")).replace("_", " ")
			var presente := ""
			var presentes: Array = modelo["presentes"]
			if not presentes.is_empty() and (remetente["de"] == "ninguem" or g.randf() < float(textos["chance_de_presente"])):
				presente = presentes[g.randi_range(0, presentes.size() - 1)]
			cartas.append({
				"situacao": situacao,
				"de": remetente["de"],
				"remetente": remetente["id"],
				"texto": _preencher(modelo["texto"], trocas),
				"presente": presente,
			})
	return cartas


## A pessoa de quem a carta fala: o inocente prejudicado, o amaldiçoado morto ou o exposto.
static func _pessoa_da_situacao(situacao: String, verdade: Dictionary, desfecho: Dictionary) -> String:
	match situacao:
		"inocente_prejudicado":
			return desfecho["inocente_prejudicado"]
		"cliente_exposto":
			return str(verdade.get("culpado", "")) if desfecho.get("cliente_exposto", false) else str(verdade["hospedeiro"])
		"amaldicoado_morto":
			return verdade["hospedeiro"]
	return ""


## Quem escreve: [{"de", "id"}]. Testemunhas são quem viu um ataque; a família é a da pessoa.
static func _remetentes(situacao: String, modelos: Array, caso: Dictionary, pessoa_id: String, por_id: Dictionary, ataques: Array, textos: Dictionary, g: RandomNumberGenerator) -> Array:
	var tipos := {}
	for m in modelos:
		tipos[m["de"]] = true
	var lista: Array = []
	var cliente: String = caso["contrato"]["cliente"]
	if tipos.has("cliente"):
		lista.append({"de": "cliente", "id": cliente})
	if tipos.has("ninguem"):
		lista.append({"de": "ninguem", "id": ""})
	if tipos.has("acusado"):
		lista.append({"de": "acusado", "id": pessoa_id})
	if tipos.has("testemunha"):
		var ids_ataque := {}
		for a in ataques:
			ids_ataque[int(a["id"])] = true
		var viram: Array = []
		for npc in caso["npcs"]:
			if npc["id"] == cliente or npc["id"] == caso["verdade"]["hospedeiro"] or int(npc["idade"]) < 8:
				continue
			for memoria in npc["memorias"]:
				if ids_ataque.has(int(memoria["evento_origem"])):
					viram.append(npc["id"])
					break
		var faixa: Array = textos["testemunhas_que_escrevem"]
		var quantas := mini(g.randi_range(int(faixa[0]), int(faixa[1])), viram.size())
		for i in quantas:
			var escolhido: String = viram.pop_at(g.randi_range(0, viram.size() - 1))
			lista.append({"de": "testemunha", "id": escolhido})
	if tipos.has("familia"):
		var pessoa: Dictionary = por_id.get(pessoa_id, {})
		var parentes: Array = []
		for npc in caso["npcs"]:
			if npc["id"] != pessoa_id and not pessoa.is_empty() and npc["familia"] == pessoa["familia"] and int(npc["idade"]) >= 14:
				parentes.append(npc["id"])
		# Sem parente no bairro, quem escreve é um vizinho que conhecia a pessoa (o cliente).
		lista.append({"de": "familia", "id": parentes[g.randi_range(0, parentes.size() - 1)] if not parentes.is_empty() else cliente})
	return lista


static func _nome(npc: Dictionary) -> String:
	if npc.is_empty():
		return ""
	return "%s %s" % [npc["nome"], npc["sobrenome"]]


static func _preencher(texto: String, trocas: Dictionary) -> String:
	var saida := texto
	for chave in trocas:
		saida = saida.replace("{%s}" % chave, str(trocas[chave]))
	return saida
