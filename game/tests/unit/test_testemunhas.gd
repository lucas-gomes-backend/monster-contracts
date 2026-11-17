extends "res://tests/framework/test_case.gd"
## Depoimentos: filtro de percepção e mentiras (core/casos/testemunhas.gd). Propriedades em
## várias sementes, mais casos montados à mão para o filtro.

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Testemunhas := preload("res://core/casos/testemunhas.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")

const SEMENTES := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]

var _casos := {}


func _caso(semente: int) -> Dictionary:
	if not _casos.has(semente):
		_casos[semente] = Gerador.gerar(semente)
	return _casos[semente]


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_testemunhas()["dados"]


func _npcs_por_id(caso: Dictionary) -> Dictionary:
	var por_id := {}
	for npc in caso["npcs"]:
		por_id[npc["id"]] = npc
	return por_id


func test_testemunhas_config_e_valida() -> void:
	assert_eq(Catalogo.carregar_config_testemunhas()["erros"], [] as Array[String])


func test_testemunhas_todo_depoimento_vem_de_um_evento_real() -> void:
	for semente in SEMENTES:
		var caso := _caso(semente)
		var registro: RefCounted = caso["registro"]
		var por_id := _npcs_por_id(caso)
		for dep in caso["depoimentos"]:
			if not por_id.has(dep["npc"]):
				fail("semente %d: %s de alguém que não existe" % [semente, dep["id"]])
			if registro.obter(int(dep["causa"])).is_empty():
				fail("semente %d: %s sem causa" % [semente, dep["id"]])
			if dep["tipo"] != "alibi" and registro.obter(int(dep["evento"])).is_empty():
				fail("semente %d: %s sem evento" % [semente, dep["id"]])


func test_testemunhas_quem_so_ouviu_nao_descreve_forma() -> void:
	for semente in SEMENTES:
		for dep in _caso(semente)["depoimentos"]:
			if dep["modo"] == "ouviu" and (dep["relato"].has("forma") or dep["relato"].has("tamanho")):
				fail("semente %d: %s ouviu mas descreveu a forma" % [semente, dep["id"]])


func test_testemunhas_toda_mentira_pode_ser_desmascarada() -> void:
	var total := 0
	for semente in SEMENTES:
		var caso := _caso(semente)
		for dep in caso["depoimentos"]:
			if dep["mentira"].is_empty():
				continue
			total += 1
			if not _desmentida(dep, caso):
				fail("semente %d: %s mente (%s) sem ninguém para desmentir" % [semente, dep["id"], dep["mentira"]["tipo"]])
	assert_gte(total, 1, "houve mentiras para conferir em %d sementes" % SEMENTES.size())


func _desmentida(dep: Dictionary, caso: Dictionary) -> bool:
	match dep["mentira"]["tipo"]:
		"onde_estava":
			for outro in caso["depoimentos"]:
				if outro["npc"] != dep["npc"] and outro["causa"] == dep["causa"] and dep["npc"] in outro["viu_pessoas"]:
					return true
		"protege_familiar":
			for outro in caso["depoimentos"]:
				if outro["tipo"] == "ausencia" and outro["causa"] == dep["causa"] and outro["relato"]["quem_saiu"] == dep["relato"]["sobre"]:
					return true
	return false


func test_testemunhas_familia_do_hospedeiro_nunca_entrega_o_sumico() -> void:
	for semente in SEMENTES:
		var caso := _caso(semente)
		var hospedeiro: String = caso["verdade"]["hospedeiro"]
		if hospedeiro.is_empty():
			continue
		var por_id := _npcs_por_id(caso)
		var familia: String = por_id[hospedeiro]["familia"]
		for dep in caso["depoimentos"]:
			if dep["tipo"] == "ausencia" and por_id[dep["npc"]]["familia"] == familia:
				fail("semente %d: a família contou do sumiço" % semente)


func test_testemunhas_interpretacao_vem_das_listas() -> void:
	var cfg := _cfg()
	var permitidas := {"": true}
	for lista in cfg["interpretacoes"].values():
		for nome in lista:
			permitidas[nome] = true
	for nome in cfg["interpretacoes_ceticas"]:
		permitidas[nome] = true
	for semente in SEMENTES:
		for dep in _caso(semente)["depoimentos"]:
			if not permitidas.has(dep["interpretacao"]):
				fail("semente %d: interpretação desconhecida %s" % [semente, dep["interpretacao"]])


func test_testemunhas_mesma_semente_gera_os_mesmos_depoimentos() -> void:
	assert_eq(JSON.stringify(Gerador.gerar(31)["depoimentos"], "", true), JSON.stringify(Gerador.gerar(31)["depoimentos"], "", true))


func test_testemunhas_medroso_exagera_o_tamanho() -> void:
	var escala: Array = _cfg()["escala_tamanho"]
	assert_eq(Testemunhas._tamanho_percebido("grande", true, escala), "enorme", "medroso")
	assert_eq(Testemunhas._tamanho_percebido("grande", false, escala), "grande", "sem medo")
	assert_eq(Testemunhas._tamanho_percebido("gigante", true, escala), "gigante", "não passa do máximo")


func test_testemunhas_cetico_sempre_da_um_nome_normal() -> void:
	var cfg := _cfg()
	var g := RandomNumberGenerator.new()
	g.seed = 1
	for i in 50:
		var nome := Testemunhas._interpretacao({"tracos": ["cetico"], "comunidade": "brasileira"}, cfg, g)
		assert_has(cfg["interpretacoes_ceticas"], nome)
