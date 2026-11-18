extends RefCounted
## Depoimentos das testemunhas (docs/04, "Testemunhas"): o que cada pessoa CONTA, a partir
## do que ela realmente presenciou, passando pelo filtro de percepção e pelas mentiras.
##
## Filtro de percepção:
##   ouviu (não viu)      -> só o som; dormindo, só "um barulho estranho"
##   noite                -> chance de a forma virar "um vulto"
##   medroso              -> exagera o tamanho (um degrau acima)
##   bebeu (lazer no bar) -> erra a hora e pode trocar a forma
##   crença               -> dá um nome ao que viu (às vezes errado); céticos dão nomes "normais"
##
## Mentiras: SÓ acontecem se puderem ser desmascaradas (docs/04: "toda mentira contradiz
## algum fato verificável").
##   onde_estava        -> quem tem segredo e estava fora de casa, com outras pessoas no mesmo
##                         lugar, diz que estava em casa. Os outros contam que o viram lá.
##   protege_familiar   -> a família do hospedeiro diz que ele não saiu. Um vizinho de fora
##                         da família notou que ele saiu.

const Relogio := preload("res://core/tempo/relogio.gd")


static func gerar(registro: RefCounted, npcs: Array[Dictionary], rotina: RefCounted, bairro: RefCounted, criaturas: Dictionary, ruidos: Array, cfg: Dictionary, hospedeiro: Dictionary, g: RandomNumberGenerator) -> Array[Dictionary]:
	var por_id := {}
	for npc in npcs:
		por_id[npc["id"]] = npc
	var ruidos_por_id := {}
	for ruido in ruidos:
		ruidos_por_id[ruido["id"]] = ruido
	var formas := _todas_as_formas(criaturas, ruidos)

	var depoimentos: Array[Dictionary] = []
	for evento in registro.buscar("npc.presenciou"):
		var npc: Dictionary = por_id.get(evento["ator"], {})
		if npc.is_empty():
			continue
		var causa: Dictionary = registro.obter(int(evento["dados"]["evento_origem"]))
		var observavel := _observavel(causa, criaturas, ruidos_por_id)
		var ficha: Dictionary = criaturas.get(causa["dados"].get("especie", ""), {})
		depoimentos.append(_depoimento_presencial(evento, causa, npc, observavel, ficha, npcs, rotina, bairro, formas, cfg, g))

	var notados: Array = registro.buscar("npc.notou_ausencia")
	for evento in notados:
		if evento["dados"]["familia"]:
			continue  # a família não conta: protege (ver abaixo)
		depoimentos.append({
			"tipo": "ausencia",
			"npc": evento["ator"],
			"evento": evento["id"],
			"causa": evento["dados"]["evento_origem"],
			"modo": "notou_ausencia",
			"relato": {"quem_saiu": evento["dados"]["quem"], "hora_declarada": Relogio.data_de(evento["dados"]["saida_minuto"])["hora"]},
			"interpretacao": "",
			"tags": [evento["dados"]["tag"]] if not str(evento["dados"]["tag"]).is_empty() else [],
			"viu_pessoas": [],
			"local_declarado": evento["local"],
			"mentira": {},
		})

	if not hospedeiro.is_empty():
		depoimentos.append_array(_alibis_da_familia(registro, npcs, hospedeiro, notados))

	for i in depoimentos.size():
		depoimentos[i]["id"] = "dep_%03d" % i
	return depoimentos


static func _depoimento_presencial(evento: Dictionary, causa: Dictionary, npc: Dictionary, observavel: Dictionary, ficha: Dictionary, npcs: Array[Dictionary], rotina: RefCounted, bairro: RefCounted, formas: Array, cfg: Dictionary, g: RandomNumberGenerator) -> Dictionary:
	var minuto: int = causa["minuto"]
	var posicao: Dictionary = rotina.onde_esta(npc, minuto)
	var dormindo: bool = posicao["atividade"] == "dormindo"
	var noite := Relogio.new(minuto).eh_noite()
	var bebado: bool = "bebe_muito" in npc["tracos"] and posicao["atividade"] == "lazer" and bairro.local(posicao["local"]).get("tipo", "") == "bar"
	var modo: String = evento["dados"]["modo"]

	var relato := {}
	if modo == "viu":
		var forma: String = observavel.get("forma", cfg["forma_vaga"])
		if noite and g.randf() < float(cfg["chance_vago_a_noite"]):
			forma = cfg["forma_vaga"]
		if bebado and g.randf() < float(cfg["chance_bebado_trocar_forma"]):
			forma = formas[g.randi_range(0, formas.size() - 1)]
		relato["forma"] = forma
		relato["tamanho"] = _tamanho_percebido(observavel.get("tamanho", "medio"), "medroso" in npc["tracos"], cfg["escala_tamanho"])
	relato["som"] = cfg["som_de_quem_ouviu"] if dormindo else observavel.get("som", cfg["som_de_quem_ouviu"])

	var erro := 0
	if bebado:
		erro = g.randi_range(int(cfg["erro_hora_bebado"][0]), int(cfg["erro_hora_bebado"][1])) * (1 if g.randf() < 0.5 else -1)
	elif dormindo:
		erro = g.randi_range(int(cfg["erro_hora_sono"][0]), int(cfg["erro_hora_sono"][1]))
	relato["hora_declarada"] = posmod(int(Relogio.data_de(minuto)["hora"]) + erro, 24)

	var tags: Array = []
	if causa["tipo"] == "criatura.ataque" and modo == "viu":
		for marca in ficha.get("marcas", []):
			if marca["onde"] == "testemunha" and marca.get("sobre", "evento") == "evento":
				if g.randf() < float(cfg["chance_marca_de_testemunha"][marca["freq"]]):
					tags.append(marca["tag"])

	var viu_pessoas: Array = []
	if not dormindo:
		for outro in npcs:
			if outro["id"] == npc["id"]:
				continue
			var p: Dictionary = rotina.onde_esta(outro, minuto)
			if p["local"] == posicao["local"] and not p["atividade"] in ["dormindo", "transformado"]:
				viu_pessoas.append(outro["id"])

	var depoimento := {
		"tipo": "presenciou",
		"npc": npc["id"],
		"evento": evento["id"],
		"causa": causa["id"],
		"modo": modo,
		"relato": relato,
		"interpretacao": _interpretacao(npc, cfg, g),
		"tags": tags,
		"viu_pessoas": viu_pessoas,
		"local_declarado": posicao["local"],
		"mentira": {},
	}
	# Mentira por vergonha: só se alguém no mesmo lugar puder desmentir.
	if npc["segredo"] in cfg["segredos_que_fazem_mentir"] and posicao["atividade"] == "lazer" and not viu_pessoas.is_empty():
		depoimento["local_declarado"] = npc["casa"]
		depoimento["mentira"] = {"tipo": "onde_estava", "verdade": posicao["local"], "motivo": npc["segredo"]}
	return depoimento


## A família do hospedeiro jura que ele não saiu, mas só quando um vizinho de fora da
## família notou a saída (senão a mentira não teria como ser desmascarada).
static func _alibis_da_familia(registro: RefCounted, npcs: Array[Dictionary], hospedeiro: Dictionary, notados: Array) -> Array[Dictionary]:
	var desmentidos := {}
	for evento in notados:
		if not evento["dados"]["familia"]:
			desmentidos[int(evento["dados"]["evento_origem"])] = int(evento["dados"]["saida_minuto"])
	var alibis: Array[Dictionary] = []
	var ataques := desmentidos.keys()
	ataques.sort()
	for npc in npcs:
		if npc["familia"] != hospedeiro["familia"] or npc["id"] == hospedeiro["id"] or int(npc["idade"]) < 14:
			continue
		for ataque_id in ataques:
			alibis.append({
				"tipo": "alibi",
				"npc": npc["id"],
				"evento": -1,
				"causa": ataque_id,
				"modo": "alibi",
				"relato": {"sobre": hospedeiro["id"], "afirma": "ficou_em_casa_a_noite_toda"},
				"interpretacao": "",
				"tags": [],
				"viu_pessoas": [],
				"local_declarado": npc["casa"],
				"mentira": {"tipo": "protege_familiar", "verdade": "saiu_as_%02dh" % Relogio.data_de(desmentidos[ataque_id])["hora"], "motivo": "familia"},
			})
	return alibis


static func _observavel(causa: Dictionary, criaturas: Dictionary, ruidos: Dictionary) -> Dictionary:
	if causa["tipo"] == "criatura.ataque":
		return criaturas.get(causa["dados"].get("especie", ""), {}).get("observavel", {})
	if causa["tipo"] == "ruido.ocorreu":
		return ruidos.get(causa["dados"].get("ruido", ""), {}).get("observavel", {})
	if causa["tipo"] == "humano.crime":
		return ruidos.get(causa["dados"].get("crime", ""), {}).get("observavel", {})
	return {}


static func _tamanho_percebido(real: String, medroso: bool, escala: Array) -> String:
	var i := escala.find(real)
	if i < 0 or not medroso:
		return real
	return escala[mini(i + 1, escala.size() - 1)]


static func _interpretacao(npc: Dictionary, cfg: Dictionary, g: RandomNumberGenerator) -> String:
	if "cetico" in npc["tracos"]:
		var ceticas: Array = cfg["interpretacoes_ceticas"]
		return ceticas[g.randi_range(0, ceticas.size() - 1)]
	var chance := float(cfg["chance_interpretar"]["religioso" if "religioso" in npc["tracos"] else "padrao"])
	if g.randf() >= chance:
		return ""
	var nomes: Array = cfg["interpretacoes"].get(npc["comunidade"], cfg["interpretacoes"]["brasileira"])
	return nomes[g.randi_range(0, nomes.size() - 1)]


static func _todas_as_formas(criaturas: Dictionary, ruidos: Array) -> Array:
	var formas: Array = []
	var ids := criaturas.keys()
	ids.sort()
	for id in ids:
		if criaturas[id].has("observavel"):
			formas.append(criaturas[id]["observavel"]["forma"])
	for ruido in ruidos:
		formas.append(ruido["observavel"]["forma"])
	return formas
