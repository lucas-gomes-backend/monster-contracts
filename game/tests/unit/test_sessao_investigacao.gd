extends "res://tests/framework/test_case.gd"
## Sessão de investigação (core/investigacao/sessao.gd) e interface em texto (ui/texto).

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Sessao := preload("res://core/investigacao/sessao.gd")
const Interpretador := preload("res://ui/texto/interpretador.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Pistas := preload("res://core/casos/pistas.gd")

const SEMENTES := [1, 2, 3, 4, 5, 6, 7, 8]


func _sessao(semente: int) -> RefCounted:
	var caso := Gerador.gerar(semente)
	return Sessao.new(caso, Catalogo.carregar_criaturas()["criaturas"], Catalogo.carregar_bairro(caso["bairro"])["dados"], Catalogo.carregar_config_investigacao()["dados"])


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_investigacao()["dados"]


func test_investigacao_config_e_textos_sao_validos() -> void:
	assert_eq(Catalogo.carregar_config_investigacao()["erros"], [] as Array[String])
	assert_eq(Catalogo.carregar_textos_marcas()["erros"], [] as Array[String])


func test_textos_toda_marca_tem_descricao_e_toda_marca_de_criatura_tem_caracteristica() -> void:
	var textos: Dictionary = Catalogo.carregar_textos_marcas()["dados"]
	for ficha in Catalogo.carregar_criaturas()["criaturas"].values():
		for marca in ficha["marcas"]:
			var t: Dictionary = textos.get(marca["tag"], {})
			if str(t.get("pista", "")).is_empty() or str(t.get("caracteristica", "")).is_empty():
				fail("%s: marca %s sem texto de pista ou de característica" % [ficha["id"], marca["tag"]])
	for ruido in Catalogo.carregar_config_casos()["dados"]["ruidos"]:
		for marca in ruido["marcas"]:
			if str(textos.get(marca["tag"], {}).get("pista", "")).is_empty():
				fail("ruído %s: marca %s sem texto de pista" % [ruido["id"], marca["tag"]])


func test_sessao_comeca_na_hora_do_contrato() -> void:
	var s := _sessao(1)
	assert_eq(s.minuto, int(s.caso["contrato"]["minuto"]))


func test_sessao_ir_gasta_tempo_e_examinar_no_mesmo_lugar_gasta_menos() -> void:
	var s := _sessao(1)
	var local: String = s.locais()[0]
	var inicio: int = s.minuto
	s.ir(local)
	assert_eq(s.minuto - inicio, int(_cfg()["minutos_ir_ao_local"]) + int(_cfg()["minutos_examinar_local"]), "ir e examinar")
	var meio: int = s.minuto
	s.ir(local)
	assert_eq(s.minuto - meio, int(_cfg()["minutos_examinar_local"]), "já estava lá")


func test_sessao_lugar_desconhecido_nao_gasta_tempo() -> void:
	var s := _sessao(1)
	var antes: int = s.minuto
	assert_false(s.ir("paqueta/lugar_nenhum")["ok"])
	assert_eq(s.minuto, antes)


## Visita todos os lugares e confere cada pista nova contra o lugar e a hora da visita.
func _visitar_e_conferir(s: RefCounted, semente: int) -> int:
	var encontradas := 0
	var por_id := {}
	for pista in s.caso["pistas"]:
		por_id[pista["id"]] = pista
	for local in s.locais():
		var r: Dictionary = s.ir(local)
		for id in r["novas"]:
			encontradas += 1
			var pista: Dictionary = por_id[id]
			if pista["local"] != local:
				fail("semente %d: %s é de outro lugar" % [semente, id])
			if not Pistas.disponivel(pista, s.minuto):
				fail("semente %d: %s encontrada depois de vencer" % [semente, id])
			if not pista["detectar"] in _cfg()["deteccao_inicial"]:
				fail("semente %d: %s exige equipamento que o iniciante não tem" % [semente, id])
	return encontradas


func test_sessao_so_encontra_marcas_do_lugar_validas_e_detectaveis() -> void:
	var total := 0
	for semente in SEMENTES:
		total += _visitar_e_conferir(_sessao(semente), semente)
	assert_gte(total, 1, "encontrou alguma pista em %d sementes" % SEMENTES.size())


func test_sessao_quem_demora_um_mes_nao_acha_pista_de_cena() -> void:
	for semente in SEMENTES:
		var s := _sessao(semente)
		s.minuto += 30 * 24 * 60  # um mês depois do contrato
		_visitar_e_conferir(s, semente)
		for pista in s.caderno.pistas():
			if pista["onde"] == "cena":
				fail("semente %d: pista de cena %s sobreviveu a um mês" % [semente, pista["id"]])


func test_sessao_pesquisar_traz_registros() -> void:
	var com_registro := 0
	for semente in SEMENTES:
		var s := _sessao(semente)
		var r: Dictionary = s.pesquisar()
		for id in r["novas"]:
			com_registro += 1
		for pista in s.caderno.pistas():
			assert_eq(pista["tipo"], "registro", "semente %d" % semente)
	assert_gte(com_registro, 1, "algum registro em %d sementes" % SEMENTES.size())


func test_interpretador_comandos_principais_respondem() -> void:
	var s := _sessao(12)
	var jogo := Interpretador.new(s, Catalogo.carregar_criaturas()["criaturas"], Catalogo.carregar_textos_marcas()["dados"])
	assert_has(jogo.abertura(), "Cliente:")
	for comando in ["ajuda", "contrato", "hora", "locais", "ir l1", "pesquisar", "pistas", "bestiario", "bestiario lobisomem_br", "caracteristicas", "modo assistido", "hipoteses", "riscar corpo_seco", "circular lobisomem_br", "responder quem alguém"]:
		var resposta := jogo.executar(comando)
		if resposta.is_empty() or resposta.begins_with("Não entendi"):
			fail("comando '%s' não respondeu: %s" % [comando, resposta])
	assert_has(jogo.executar("comando_inexistente"), "Não entendi")
	jogo.executar("sair")
	assert_true(jogo.terminou)
