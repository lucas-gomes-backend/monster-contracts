extends "res://tests/framework/test_case.gd"
## Gerador de casos e pistas (core/casos). Testes de propriedade em várias sementes:
## conferem o que todo caso gerado precisa respeitar (docs/04).

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Pistas := preload("res://core/casos/pistas.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")

const SEMENTES := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

var _cache := {}


func _caso(semente: int) -> Dictionary:
	if not _cache.has(semente):
		_cache[semente] = Gerador.gerar(semente)
	return _cache[semente]


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_casos()["dados"]


func test_casos_config_e_valida() -> void:
	assert_eq(Catalogo.carregar_config_casos()["erros"], [] as Array[String])


func test_casos_todas_as_sementes_geram_caso_valido_com_ataque() -> void:
	for semente in SEMENTES:
		var caso := _caso(semente)
		if not caso.get("valido", false):
			fail("semente %d: %s" % [semente, str(caso.get("erros", []))])
			continue
		assert_gte(caso["registro"].buscar("criatura.ataque", caso["verdade"]["instancia"]).size(), 1, "semente %d" % semente)


func test_casos_mesma_semente_gera_o_mesmo_caso() -> void:
	assert_eq(Gerador.gerar(77)["hash"], Gerador.gerar(77)["hash"])


func test_casos_sementes_diferentes_geram_casos_diferentes() -> void:
	assert_ne(_caso(1)["hash"], _caso(2)["hash"])


func test_casos_especie_combina_com_o_bairro_e_a_estrutura() -> void:
	var criaturas: Dictionary = Catalogo.carregar_criaturas()["criaturas"]
	for semente in SEMENTES:
		var caso := _caso(semente)
		var ficha: Dictionary = criaturas[caso["verdade"]["especie"]]
		var golpe: bool = caso["estrutura"] == "golpe"
		assert_eq("humano" in ficha["familia"], golpe, "semente %d: golpe <-> golpe humano" % semente)
		if not ("coringa" in ficha["bairros"] or "antigo_religioso" in ficha["bairros"]):
			fail("semente %d: %s não vive no Paquetá" % [semente, ficha["id"]])


func test_casos_hospedeiro_respeita_a_ficha_e_some_nos_ataques() -> void:
	var criaturas: Dictionary = Catalogo.carregar_criaturas()["criaturas"]
	for semente in SEMENTES:
		var caso := _caso(semente)
		var ficha: Dictionary = criaturas[caso["verdade"]["especie"]]
		var hospedeiro_id: String = caso["verdade"]["hospedeiro"]
		if not ficha.has("hospedeiro"):
			assert_eq(hospedeiro_id, "", "semente %d: sem hospedeiro" % semente)
			continue
		var hospedeiro: Dictionary = {}
		for npc in caso["npcs"]:
			if npc["id"] == hospedeiro_id:
				hospedeiro = npc
		assert_false(hospedeiro.is_empty(), "semente %d: hospedeiro existe" % semente)
		if hospedeiro.is_empty():
			continue
		if ficha["hospedeiro"].has("genero"):
			assert_eq(hospedeiro["genero"], ficha["hospedeiro"]["genero"], "semente %d" % semente)
		var ataques: Array = caso["registro"].buscar("criatura.ataque", caso["verdade"]["instancia"])
		assert_eq(hospedeiro.get("ausencias", []).size(), ataques.size(), "semente %d: some em cada ataque" % semente)


func test_casos_criatura_nao_testemunha_o_proprio_ataque() -> void:
	for semente in SEMENTES:
		var caso := _caso(semente)
		var hospedeiro: String = caso["verdade"]["hospedeiro"]
		for pista in caso["pistas"]:
			if pista["tipo"] == "testemunho" and pista["npc"] == hospedeiro and pista["origem"] == "criatura":
				fail("semente %d: o hospedeiro testemunhou o próprio ataque" % semente)


func test_casos_toda_pista_tem_proveniencia_coerente() -> void:
	for semente in SEMENTES:
		var caso := _caso(semente)
		var registro: RefCounted = caso["registro"]
		for pista in caso["pistas"]:
			var evento: Dictionary = registro.obter(int(pista["evento"]))
			var causa: Dictionary = registro.obter(int(pista["causa"]))
			if evento.is_empty() or causa.is_empty():
				fail("semente %d: %s sem evento ou causa" % [semente, pista["id"]])
				continue
			var esperado: Array = ["criatura.ataque", "historia.gatilho"] if pista["origem"] == "criatura" else ["ruido.ocorreu"]
			if not causa["tipo"] in esperado:
				fail("semente %d: %s com causa %s" % [semente, pista["id"], causa["tipo"]])
			if pista["tipo"] != "registro" and causa["minuto"] != pista["minuto"]:
				fail("semente %d: %s em momento diferente da causa" % [semente, pista["id"]])


func test_casos_todo_evento_fica_entre_o_inicio_e_o_contrato() -> void:
	for semente in SEMENTES:
		var caso := _caso(semente)
		for evento in caso["registro"].buscar():
			if evento["minuto"] < caso["inicio_minuto"] or evento["minuto"] > caso["contrato"]["minuto"]:
				fail("semente %d: evento %s fora da pré-simulação" % [semente, evento["tipo"]])


func test_casos_ruido_existe_e_fica_na_faixa() -> void:
	var faixa: Array = _cfg()["ruidos_por_caso"]
	for semente in SEMENTES:
		var quantidade: int = _caso(semente)["registro"].buscar("ruido.ocorreu").size()
		if quantidade < int(faixa[0]) or quantidade > int(faixa[1]):
			fail("semente %d: %d ruídos" % [semente, quantidade])


func test_casos_cliente_e_um_morador_adulto_que_nao_e_a_criatura() -> void:
	for semente in SEMENTES:
		var caso := _caso(semente)
		var cliente: String = caso["contrato"]["cliente"]
		assert_ne(cliente, caso["verdade"]["hospedeiro"], "semente %d" % semente)
		var achou := false
		for npc in caso["npcs"]:
			if npc["id"] == cliente:
				achou = int(npc["idade"]) >= 18
		assert_true(achou, "semente %d: cliente adulto do bairro" % semente)


func test_casos_validade_das_pistas_e_a_chuva() -> void:
	for semente in SEMENTES:
		var caso := _caso(semente)
		var chuva: int = caso["previsao"]["chuva_em"]
		for pista in caso["pistas"]:
			var fim: int = pista["valida_ate"]
			if fim >= 0 and fim <= int(pista["minuto"]):
				fail("semente %d: %s expira antes de existir" % [semente, pista["id"]])
			if pista["onde"] == "cena" and chuva >= 0 and fim > chuva:
				fail("semente %d: %s de cena sobrevive à chuva" % [semente, pista["id"]])
			if pista["onde"] == "registro" and fim != -1:
				fail("semente %d: registro não deveria expirar" % semente)


func test_pistas_disponivel_respeita_a_validade() -> void:
	assert_true(Pistas.disponivel({"valida_ate": -1}, 999999), "sem validade")
	assert_true(Pistas.disponivel({"valida_ate": 100}, 99), "antes")
	assert_false(Pistas.disponivel({"valida_ate": 100}, 100), "no limite")


func test_pistas_chuva_encurta_so_a_cena() -> void:
	var horas := {"cena": 72, "corpo": 168, "registro": -1}
	assert_eq(Pistas.validade("cena", 0, horas, 600), 600, "chuva apaga a cena")
	assert_eq(Pistas.validade("corpo", 0, horas, 600), 168 * 60, "corpo não molha")
	assert_eq(Pistas.validade("cena", 1000, horas, 600), 1000 + 72 * 60, "chuva antes da pista não conta")
	assert_eq(Pistas.validade("registro", 0, horas, 600), -1, "registro não expira")
