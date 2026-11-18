extends RefCounted
## Gerador de casos (docs/04). O gerador NÃO escreve pistas: ele decide a verdade,
## simula os 10 dias antes do contrato e deixa as pistas saírem do registro de eventos.
##
## Pipeline:
##   1. bairro e população (gerados pela semente)
##   2. verdade: estrutura (caça simples ou golpe), espécie, instância e hospedeiro humano
##   3. história: o gatilho, ligado a um morador
##   4. pré-simulação hora a hora: criatura, ruído agendado, boletins de ocorrência,
##      presença de testemunhas
##   5. contrato: cliente, pedido, o que esconde, recompensa e prazo
##   6. previsão do tempo (chuva) e pistas com validade (core/casos/pistas.gd)
##
## Se a pré-simulação não produz nenhum ataque, a tentativa é descartada e outra
## sub-semente é usada (docs/04, passo 8). A mesma semente gera sempre o mesmo caso.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Barramento := preload("res://core/eventos/barramento.gd")
const Relogio := preload("res://core/tempo/relogio.gd")
const Bairro := preload("res://core/mundo/bairro.gd")
const GeradorPopulacao := preload("res://core/npcs/gerador_populacao.gd")
const Rotina := preload("res://core/npcs/rotina.gd")
const Presenca := preload("res://core/npcs/presenca.gd")
const Criatura := preload("res://core/criaturas/criatura.gd")
const Pistas := preload("res://core/casos/pistas.gd")
const Testemunhas := preload("res://core/casos/testemunhas.gd")
const Solucionador := preload("res://core/casos/solucionador.gd")

const TIPOS_PRESENCIAVEIS := ["criatura.ataque", "ruido.ocorreu", "humano.crime"]
const MINUTOS_POR_DIA := 1440


## Gera um caso. Devolve o dicionário do caso, com "valido" = true, ou
## {"valido": false, "erros": [...]} se os dados estiverem quebrados ou nenhuma tentativa der certo.
static func gerar(semente: int, id_bairro: String = "paqueta") -> Dictionary:
	var dados := carregar_dados(id_bairro)
	if not dados["erros"].is_empty():
		return {"valido": false, "semente": semente, "erros": dados["erros"]}
	var tentativas := int(dados["casos"]["tentativas_maximas"])
	var descartes: Array = []  # [{tentativa, motivos}] das tentativas jogadas fora
	for tentativa in tentativas:
		var sub_semente := semente if tentativa == 0 else Rng.derive_seed(semente, "tentativa:%d" % tentativa)
		var caso := _gerar_tentativa(semente, sub_semente, tentativa, dados)
		if not caso.get("valido", false):
			descartes.append({"tentativa": tentativa, "motivos": ["sem incidente na pré-simulação"]})
			continue
		# Passo 8: o solucionador joga o caso como um iniciante. Caso injusto é descartado.
		var validacao := Solucionador.validar(caso, dados["criaturas"], dados["bairro"]["tipo"], Solucionador.tipos_de_locais(dados["bairro"]))
		caso["validacao"] = validacao
		if validacao["valido"]:
			caso["descartes"] = descartes
			return caso
		descartes.append({"tentativa": tentativa, "motivos": validacao["motivos"]})
	return {"valido": false, "semente": semente, "erros": ["nenhuma das %d tentativas gerou um caso justo" % tentativas], "descartes": descartes}


## Carrega e valida tudo o que o gerador usa. {"erros": [...], ...dados}
static func carregar_dados(id_bairro: String) -> Dictionary:
	var erros: Array[String] = []
	var criaturas := Catalogo.carregar_criaturas()
	var config_criaturas := Catalogo.carregar_config_criaturas()
	var populacao := Catalogo.carregar_config_populacao()
	var bairro := Catalogo.carregar_bairro(id_bairro)
	var casos := Catalogo.carregar_config_casos()
	var testemunhas := Catalogo.carregar_config_testemunhas()
	for r in [criaturas, config_criaturas, populacao, bairro, casos, testemunhas]:
		erros.append_array(r["erros"])
	return {
		"erros": erros,
		"criaturas": criaturas["criaturas"],
		"config_criaturas": config_criaturas["dados"],
		"populacao": populacao["dados"],
		"bairro": bairro["dados"],
		"casos": casos["dados"],
		"testemunhas": testemunhas["dados"],
	}


static func _gerar_tentativa(semente: int, sub_semente: int, tentativa: int, d: Dictionary) -> Dictionary:
	var cfg: Dictionary = d["casos"]
	var rng := Rng.new(sub_semente)
	var g: RandomNumberGenerator = rng.stream("caso")
	var bairro := Bairro.new(d["bairro"])
	var npcs := GeradorPopulacao.gerar(bairro, d["populacao"], rng)

	# 2. Verdade
	var estrutura := _sortear_por_peso(_estruturas_possiveis(cfg, bairro, d["criaturas"]), g)
	var especie := _escolher_especie(estrutura, bairro, d["criaturas"], g, cfg)
	if especie.is_empty():
		return {"valido": false}
	var ficha: Dictionary = d["criaturas"][especie]
	var instancia := "%s#%d" % [especie, semente]
	var hospedeiro := _escolher_hospedeiro(ficha, npcs, g)
	if ficha["disfarce"]["tipo"] == "forma_humana" and hospedeiro.is_empty():
		return {"valido": false}
	# Culpado humano: um morador comete o crime que provoca a criatura.
	var crime := {}
	var culpado := {}
	var g_crime: RandomNumberGenerator = rng.stream("crime")
	if tem_culpado(estrutura):
		var crimes := _crimes_possiveis(cfg, ficha, bairro)
		crime = crimes[g_crime.randi_range(0, crimes.size() - 1)]
		culpado = _escolher_culpado(npcs, hospedeiro, g_crime)
		if culpado.is_empty():
			return {"valido": false}

	# Datas
	var base: Dictionary = cfg["data_base"]
	var dia_contrato := Relogio.dias_de_civil(base["ano"], base["mes"], base["dia"]) + g.randi_range(0, int(cfg["dias_de_variacao_da_data"]))
	var contrato_min := dia_contrato * MINUTOS_POR_DIA + int(cfg["hora_do_contrato"]) * 60
	var inicio := contrato_min - int(cfg["pre_simulacao_dias"]) * MINUTOS_POR_DIA

	var locais: Array[String] = []
	for tipo in cfg["locais_de_ataque"]:
		locais.append_array(bairro.locais_do_tipo(tipo))

	# Sistemas. A ordem das assinaturas importa: a ausência do hospedeiro é marcada
	# ANTES da presença perguntar onde cada morador estava.
	var barramento := Barramento.new()
	var rotina := Rotina.new(d["populacao"], rng, bairro)
	if not hospedeiro.is_empty():
		hospedeiro["ausencias"] = []
		var antes := int(d["testemunhas"]["minutos_antes_do_ataque_para_sair"])
		var tag_sumico := _tag_de_testemunha(ficha, "hospedeiro")
		barramento.assinar("criatura.ataque", func(e: Dictionary) -> void:
			if e["ator"] != instancia:
				return
			var saida: int = e["minuto"] - antes
			hospedeiro["ausencias"].append([saida, e["minuto"] + 60, e["local"]])
			_registrar_quem_notou(npcs, hospedeiro, rotina, bairro, barramento, e, saida, tag_sumico))
	if not culpado.is_empty():
		culpado["ausencias"] = []
		var antes_do_crime := int(d["testemunhas"]["minutos_antes_do_ataque_para_sair"])
		barramento.assinar("humano.crime", func(e: Dictionary) -> void:
			var saida: int = e["minuto"] - antes_do_crime
			culpado["ausencias"].append([saida, e["minuto"] + 60, e["local"]])
			_registrar_quem_notou(npcs, culpado, rotina, bairro, barramento, e, saida, crime["tag_de_quem_notou"]))
	var _presenca := Presenca.new(npcs, rotina, bairro, barramento, TIPOS_PRESENCIAVEIS)
	var criatura := Criatura.new(ficha, instancia, rng, barramento, d["config_criaturas"], locais)

	var boletins: Array = []
	var g_boletim: RandomNumberGenerator = rng.stream("boletins")
	barramento.assinar("criatura.ataque", func(e: Dictionary) -> void:
		if e["ator"] == instancia and g_boletim.randf() < float(cfg["chance_boletim"]):
			var dia_seguinte := (int(e["minuto"]) / MINUTOS_POR_DIA + 1) * MINUTOS_POR_DIA
			boletins.append({"minuto": dia_seguinte + int(cfg["hora_do_boletim"]) * 60, "tipo": "boletim", "ataque": e["id"], "local": e["local"]}))

	# 3. História
	var gatilho: String = ficha["gatilhos"][g.randi_range(0, ficha["gatilhos"].size() - 1)]
	var ligado: String = hospedeiro["id"] if not hospedeiro.is_empty() else _adulto_qualquer(npcs, g)
	if not crime.is_empty():
		gatilho = crime["gatilho"]
		ligado = culpado["id"]
	var historia: Dictionary = barramento.publicar(inicio, "historia.gatilho", instancia, "", {"gatilho": gatilho, "npc_ligado": ligado, "especie": especie})
	# Registros antigos (cartório, jornal, igreja) que a história da criatura deixou.
	var g_historia: RandomNumberGenerator = rng.stream("historia")
	for marca in ficha["marcas"]:
		if marca["onde"] == "registro" and marca.get("sobre", "historia") == "historia":
			if g_historia.randf() < float(d["config_criaturas"]["chance_marca"][marca["freq"]]):
				barramento.publicar(inicio, "historia.registro", instancia, "", {"tag": marca["tag"], "evento_origem": historia["id"]})
	# A criatura que só age quando provocada (Curupira) é provocada perto do contrato,
	# dentro da validade da cena: senão o único ataque fica velho e as marcas somem antes
	# do caçador chegar. O golpista arma o golpe desde o início da pré-simulação, e as
	# outras criaturas acordam nele.
	var total_horas := int(cfg["pre_simulacao_dias"]) * 24
	var hora_da_provocacao := -1
	if ficha["necessidade"]["frequencia"] == "quando_provocada" and "humano" in ficha["familia"]:
		criatura.provocar(inicio, gatilho)
	elif ficha["necessidade"]["frequencia"] == "quando_provocada":
		var cena_h := int(cfg["validade_horas"]["cena"])
		hora_da_provocacao = total_horas - rng.stream("provocacao").randi_range(mini(24, cena_h / 2), maxi(cena_h - 6, 1))
	else:
		criatura.despertar(inicio, gatilho)

	# 4. Pré-simulação
	var agenda := _agendar_ruidos(cfg, bairro, inicio, rng.stream("ruido"))
	if not crime.is_empty():
		var crimes_agendados := _agendar_crimes(cfg, crime, culpado, bairro, inicio + hora_da_provocacao * 60, inicio, g_crime)
		agenda.append_array(crimes_agendados)
		# A provocação é o último crime: a criatura reage logo depois.
		hora_da_provocacao = (int(crimes_agendados[-1]["minuto"]) - inicio) / 60 + 1
	for hora in total_horas:
		var minuto := inicio + hora * 60
		if hora == hora_da_provocacao:
			criatura.provocar(minuto, gatilho)
		_emitir_pendentes(agenda, boletins, minuto, barramento)
		criatura.passo(minuto)
	_emitir_pendentes(agenda, boletins, contrato_min, barramento)
	barramento.encerrar()

	var registro: RefCounted = barramento.registro
	var ataques: Array = registro.buscar("criatura.ataque", instancia)
	if ataques.is_empty():
		return {"valido": false}

	# 5. Contrato
	# Cliente mentiroso: quem contrata é o próprio culpado, e esconde o crime.
	var cliente := culpado if estrutura == "cliente_mentiroso" else _escolher_cliente(npcs, ataques, hospedeiro if not hospedeiro.is_empty() else culpado, bairro, g)
	var pedidos: Array = cfg["pedidos"].get(estrutura, ["descobrir"])
	var contrato := {
		"minuto": contrato_min,
		"cliente": cliente["id"],
		"pedido": pedidos[g.randi_range(0, pedidos.size() - 1)],
		"esconde": "crime" if estrutura == "cliente_mentiroso" else cliente["segredo"],
		"recompensa": int(ficha["perigo"]) * int(cfg["recompensa_por_perigo"]),
		"prazo_minuto": contrato_min + int(cfg["prazo_dias"]) * MINUTOS_POR_DIA,
	}

	# 6. Previsão e pistas
	var chuva_em := -1
	if g.randf() < float(cfg["chance_chuva"]):
		var janela: Array = cfg["janela_chuva_horas"]
		chuva_em = contrato_min + g.randi_range(int(janela[0]), int(janela[1])) * 60

	var verdade := {
		"especie": especie,
		"instancia": instancia,
		"hospedeiro": hospedeiro.get("id", ""),
		"gatilho": gatilho,
		"npc_ligado": ligado,
		"locais": locais,
	}
	if not crime.is_empty():
		verdade["culpado"] = culpado["id"]
		verdade["crime"] = crime["id"]
		verdade["cliente_mentiroso"] = estrutura == "cliente_mentiroso"
	var caso := {
		"valido": true,
		"semente": semente,
		"sub_semente": sub_semente,
		"tentativa": tentativa,
		"bairro": bairro.id,
		"estrutura": estrutura,
		"verdade": verdade,
		"contrato": contrato,
		"inicio_minuto": inicio,
		"previsao": {"chuva_em": chuva_em},
		"npcs": npcs,
		"registro": registro,
		"pistas": Pistas.derivar(registro, cfg["validade_horas"], chuva_em),
		"depoimentos": Testemunhas.gerar(registro, npcs, rotina, bairro, d["criaturas"], cfg["ruidos"] + ([crime] if not crime.is_empty() else []), d["testemunhas"], hospedeiro, rng.stream("testemunhas")),
	}
	if estrutura == "criatura_errada":
		_culpar_inocente(caso, bairro, d, g)
	caso["hash"] = ("%s|%s|%s" % [JSON.stringify(verdade, "", true), JSON.stringify(contrato, "", true), registro.hash_canonico()]).sha256_text()
	return caso


## Vizinhos de rua (e a família) acordados na hora em que o hospedeiro saiu de casa
## notam o sumiço. Vira o evento "npc.notou_ausencia", ligado ao ataque.
static func _registrar_quem_notou(npcs: Array[Dictionary], hospedeiro: Dictionary, rotina: RefCounted, bairro: RefCounted, barramento: RefCounted, ataque: Dictionary, saida: int, tag: String) -> void:
	var rua_casa: String = bairro.rua_de(hospedeiro["casa"])
	for npc in npcs:
		if npc["id"] == hospedeiro["id"]:
			continue
		var posicao: Dictionary = rotina.onde_esta(npc, saida)
		if posicao["atividade"] in ["dormindo", "transformado"]:
			continue
		if bairro.rua_de(posicao["local"]) != rua_casa:
			continue
		barramento.publicar(ataque["minuto"], "npc.notou_ausencia", npc["id"], posicao["local"], {
			"quem": hospedeiro["id"],
			"saida_minuto": saida,
			"familia": npc["familia"] == hospedeiro["familia"],
			"tag": tag,
			"evento_origem": ataque["id"],
		})


## Primeira marca de testemunha da ficha sobre um assunto ("evento", "hospedeiro"...).
static func _tag_de_testemunha(ficha: Dictionary, sobre: String) -> String:
	for marca in ficha["marcas"]:
		if marca["onde"] == "testemunha" and marca.get("sobre", "evento") == sobre:
			return marca["tag"]
	return ""


static func _escolher_especie(estrutura: String, bairro: RefCounted, criaturas: Dictionary, g: RandomNumberGenerator, cfg: Dictionary) -> String:
	var candidatas := _especies_da_estrutura(estrutura, bairro, criaturas, cfg)
	if candidatas.is_empty():
		return ""
	return candidatas[g.randi_range(0, candidatas.size() - 1)]


## Espécies possíveis para a estrutura neste bairro. Golpe: só humanas. Culpado humano:
## criaturas que um crime de morador provoca (gatilho de um dos "crimes" com lugar no bairro).
static func _especies_da_estrutura(estrutura: String, bairro: RefCounted, criaturas: Dictionary, cfg: Dictionary) -> Array:
	var candidatas: Array = []
	var ids := criaturas.keys()
	ids.sort()
	for id in ids:
		var ficha: Dictionary = criaturas[id]
		if int(ficha["perigo"]) == 0:
			continue
		var humano: bool = "humano" in ficha["familia"]
		if (estrutura == "golpe") != humano:
			continue
		if not Solucionador.vive_no_bairro(ficha, bairro.dados["tipo"], Solucionador.tipos_de_locais(bairro.dados)):
			continue
		if tem_culpado(estrutura) and _crimes_possiveis(cfg, ficha, bairro).is_empty():
			continue
		if estrutura == "criatura_errada" and inocentes(bairro, criaturas).is_empty():
			continue
		candidatas.append(id)
	return candidatas


## Criaturas inofensivas (perigo 0) que vivem no bairro: levam a culpa na criatura errada.
static func inocentes(bairro: RefCounted, criaturas: Dictionary) -> Array:
	var lista: Array = []
	var ids := criaturas.keys()
	ids.sort()
	for id in ids:
		if int(criaturas[id]["perigo"]) == 0 and Solucionador.vive_no_bairro(criaturas[id], bairro.dados["tipo"], Solucionador.tipos_de_locais(bairro.dados)):
			lista.append(id)
	return lista


## Só sorteia estruturas que têm alguma espécie possível no bairro.
static func _estruturas_possiveis(cfg: Dictionary, bairro: RefCounted, criaturas: Dictionary) -> Array:
	var possiveis: Array = []
	for e in cfg["estruturas"]:
		if not _especies_da_estrutura(e["id"], bairro, criaturas, cfg).is_empty():
			possiveis.append(e)
	return possiveis if not possiveis.is_empty() else cfg["estruturas"]


## Crimes que provocam esta criatura e têm onde acontecer neste bairro.
static func _crimes_possiveis(cfg: Dictionary, ficha: Dictionary, bairro: RefCounted) -> Array:
	var crimes: Array = []
	for c in cfg.get("crimes", []):
		if c["gatilho"] in ficha["gatilhos"] and not bairro.locais_do_tipo(c["tipo_local"]).is_empty():
			crimes.append(c)
	return crimes


## Criatura errada (docs/04): uma criatura inofensiva leva a culpa só na fofoca. Ela não
## age; o cliente pede para matá-la e quem viu alguma coisa (menos os céticos) jura que foi
## ela, mas a forma que a testemunha descreve é a da criatura de verdade.
static func _culpar_inocente(caso: Dictionary, bairro: RefCounted, d: Dictionary, g: RandomNumberGenerator) -> void:
	var opcoes := inocentes(bairro, d["criaturas"])
	var acusada: String = opcoes[g.randi_range(0, opcoes.size() - 1)]
	var nome := str(d["criaturas"][acusada]["nome"]).to_lower()
	caso["verdade"]["criatura_acusada"] = acusada
	caso["contrato"]["acusa"] = acusada
	var ceticas: Array = d["testemunhas"]["interpretacoes_ceticas"]
	for dep in caso["depoimentos"]:
		if dep["tipo"] == "presenciou" and not str(dep["interpretacao"]) in ceticas:
			dep["interpretacao"] = nome


## Estruturas com um culpado humano (o crime provoca a criatura). No cliente mentiroso,
## o culpado é quem contrata o caçador.
static func tem_culpado(estrutura: String) -> bool:
	return estrutura in ["culpado_humano", "cliente_mentiroso"]


## O culpado: um adulto que não é o hospedeiro da criatura.
static func _escolher_culpado(npcs: Array[Dictionary], hospedeiro: Dictionary, g: RandomNumberGenerator) -> Dictionary:
	var adultos: Array[Dictionary] = []
	for npc in npcs:
		if int(npc["idade"]) >= 18 and npc["id"] != hospedeiro.get("id", ""):
			adultos.append(npc)
	return adultos[g.randi_range(0, adultos.size() - 1)] if not adultos.is_empty() else {}


## Os crimes do culpado: o último perto da provocação ("ate"), os outros nas noites
## anteriores, todos no mesmo lugar.
static func _agendar_crimes(cfg: Dictionary, crime: Dictionary, culpado: Dictionary, bairro: RefCounted, ate: int, inicio: int, g: RandomNumberGenerator) -> Array:
	var faixa: Array = cfg["crimes_por_caso"]
	var quantidade := g.randi_range(int(faixa[0]), int(faixa[1]))
	var locais: Array[String] = bairro.locais_do_tipo(crime["tipo_local"])
	var local: String = locais[g.randi_range(0, locais.size() - 1)]
	var ultimo_dia: int = ate / MINUTOS_POR_DIA
	var agenda: Array = []
	for i in quantidade:
		var dia: int = maxi(ultimo_dia - (quantidade - 1 - i) * g.randi_range(1, 2), inicio / MINUTOS_POR_DIA + 1)
		var hora := g.randi_range(21, 23) if crime["noturno"] else g.randi_range(8, 18)
		agenda.append({"minuto": dia * MINUTOS_POR_DIA + hora * 60, "tipo": "crime", "crime": crime, "culpado": culpado["id"], "local": local})
	agenda.sort_custom(func(a, b): return int(a["minuto"]) < int(b["minuto"]))
	return agenda


static func _escolher_hospedeiro(ficha: Dictionary, npcs: Array[Dictionary], g: RandomNumberGenerator) -> Dictionary:
	if not ficha.has("hospedeiro"):
		return {}
	var regra: Dictionary = ficha["hospedeiro"]
	var candidatos: Array[Dictionary] = []
	for npc in npcs:
		var idade: int = npc["idade"]
		if idade < int(regra["idade_min"]) or idade > int(regra["idade_max"]):
			continue
		if regra.has("genero") and npc["genero"] != regra["genero"]:
			continue
		candidatos.append(npc)
	if candidatos.is_empty():
		return {}
	return candidatos[g.randi_range(0, candidatos.size() - 1)]


static func _escolher_cliente(npcs: Array[Dictionary], ataques: Array, hospedeiro: Dictionary, bairro: RefCounted, g: RandomNumberGenerator) -> Dictionary:
	var ids_ataque := {}
	for a in ataques:
		ids_ataque[int(a["id"])] = true
	var rua_ataque: String = bairro.rua_de(ataques[0]["local"])
	var testemunhas: Array[Dictionary] = []
	var vizinhos: Array[Dictionary] = []
	var adultos: Array[Dictionary] = []
	for npc in npcs:
		if int(npc["idade"]) < 18 or npc["id"] == hospedeiro.get("id", ""):
			continue
		adultos.append(npc)
		if bairro.rua_de(npc["casa"]) == rua_ataque:
			vizinhos.append(npc)
		for memoria in npc["memorias"]:
			if ids_ataque.has(int(memoria["evento_origem"])):
				testemunhas.append(npc)
				break
	for grupo in [testemunhas, vizinhos, adultos]:
		if not grupo.is_empty():
			return grupo[g.randi_range(0, grupo.size() - 1)]
	return npcs[0]


static func _adulto_qualquer(npcs: Array[Dictionary], g: RandomNumberGenerator) -> String:
	var adultos: Array[String] = []
	for npc in npcs:
		if int(npc["idade"]) >= 18:
			adultos.append(npc["id"])
	return adultos[g.randi_range(0, adultos.size() - 1)] if not adultos.is_empty() else ""


## Ruído: eventos normais do bairro que deixam marcas parecidas com as de criaturas.
static func _agendar_ruidos(cfg: Dictionary, bairro: RefCounted, inicio: int, g: RandomNumberGenerator) -> Array:
	var agenda: Array = []
	var faixa: Array = cfg["ruidos_por_caso"]
	var quantidade := g.randi_range(int(faixa[0]), int(faixa[1]))
	var dias := int(cfg["pre_simulacao_dias"])
	for i in quantidade:
		var ruido: Dictionary = cfg["ruidos"][g.randi_range(0, cfg["ruidos"].size() - 1)]
		var locais: Array[String] = bairro.locais_do_tipo(ruido["tipo_local"])
		if locais.is_empty():
			continue
		# Começa à meia-noite do dia seguinte ao início, para cair sempre dentro da pré-simulação.
		var dia: int = inicio / MINUTOS_POR_DIA + 1 + g.randi_range(0, dias - 2)
		var hora := g.randi_range(20, 27) % 24 if ruido["noturno"] else g.randi_range(8, 18)
		var minuto := dia * MINUTOS_POR_DIA + hora * 60
		agenda.append({"minuto": minuto, "tipo": "ruido", "ruido": ruido, "local": locais[g.randi_range(0, locais.size() - 1)]})
	return agenda


## Publica, em ordem de tempo, os ruídos e boletins com minuto <= "ate".
static func _emitir_pendentes(agenda: Array, boletins: Array, ate: int, barramento: RefCounted) -> void:
	var pendentes: Array = []
	for lista in [agenda, boletins]:
		var restantes: Array = []
		for item in lista:
			if int(item["minuto"]) <= ate:
				pendentes.append(item)
			else:
				restantes.append(item)
		lista.assign(restantes)
	pendentes.sort_custom(func(a, b): return int(a["minuto"]) < int(b["minuto"]) or (int(a["minuto"]) == int(b["minuto"]) and str(a["tipo"]) < str(b["tipo"])))
	for item in pendentes:
		if item["tipo"] == "boletim":
			barramento.publicar(item["minuto"], "registro.boletim", "delegacia", item["local"], {"evento_origem": item["ataque"]})
			continue
		if item["tipo"] == "crime":
			var c: Dictionary = item["crime"]
			var feito: Dictionary = barramento.publicar(item["minuto"], "humano.crime", item["culpado"], item["local"], {"crime": c["id"]})
			for marca in c["marcas"]:
				barramento.publicar(item["minuto"], "marca.depositada", item["culpado"], item["local"], {
					"tag": marca["tag"], "onde": marca["onde"], "detectar": marca["detectar"], "freq": "comum", "evento_origem": feito["id"],
				})
			continue
		var ruido: Dictionary = item["ruido"]
		var evento: Dictionary = barramento.publicar(item["minuto"], "ruido.ocorreu", "ruido:%s" % ruido["id"], item["local"], {"ruido": ruido["id"]})
		for marca in ruido["marcas"]:
			barramento.publicar(item["minuto"], "marca.depositada", "ruido:%s" % ruido["id"], item["local"], {
				"tag": marca["tag"],
				"onde": marca["onde"],
				"detectar": marca["detectar"],
				"freq": "comum",
				"evento_origem": evento["id"],
			})


static func _sortear_por_peso(opcoes: Array, g: RandomNumberGenerator) -> String:
	var total := 0
	for o in opcoes:
		total += int(o["peso"])
	var sorteio := g.randi_range(1, maxi(total, 1))
	for o in opcoes:
		sorteio -= int(o["peso"])
		if sorteio <= 0:
			return o["id"]
	return opcoes[0]["id"]
