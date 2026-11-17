extends "res://tests/framework/test_case.gd"
## Máquina de estados das criaturas (core/criaturas/criatura.gd). Testes de propriedade:
## conferem o que precisa valer sempre, em várias sementes (rules/testes.md).

const Catalogo := preload("res://core/dados/catalogo.gd")
const Criatura := preload("res://core/criaturas/criatura.gd")
const Rng := preload("res://core/rng.gd")
const Barramento := preload("res://core/eventos/barramento.gd")
const Relogio := preload("res://core/tempo/relogio.gd")

const SEMENTES := [1, 2, 3, 4, 5]
const LOCAIS := ["paqueta/galinheiro_1", "paqueta/cemiterio", "morro_sao_bento/chiqueiro"]
## Segunda-feira, 2015-11-09, 00:00.
const INICIO := {"ano": 2015, "mes": 11, "dia": 9}


func _config(sobrescrever: Dictionary = {}) -> Dictionary:
	var config: Dictionary = Catalogo.carregar_config_criaturas()["dados"].duplicate(true)
	config.merge(sobrescrever, true)
	return config


func _ficha(especie: String) -> Dictionary:
	return Catalogo.carregar_criaturas()["criaturas"][especie]


## Simula uma criatura hora a hora. Devolve {"criatura", "registro"}.
func _simular(especie: String, semente: int, dias: int, config: Dictionary = {}, despertar := true) -> Dictionary:
	var barramento := Barramento.new()
	var criatura := Criatura.new(_ficha(especie), "%s#1" % especie, Rng.new(semente), barramento, config if not config.is_empty() else _config(), LOCAIS)
	var inicio := Relogio.minutos_de(INICIO["ano"], INICIO["mes"], INICIO["dia"])
	if despertar:
		criatura.despertar(inicio, "teste")
	for hora in dias * 24:
		criatura.passo(inicio + hora * 60)
	return {"criatura": criatura, "registro": barramento.registro}


func test_criatura_dormente_nao_gera_nenhum_evento() -> void:
	var r: RefCounted = _simular("lobisomem_br", 1, 30, {}, false)["registro"]
	assert_eq(r.tamanho(), 0)


func test_criatura_config_da_simulacao_e_valida() -> void:
	assert_eq(Catalogo.carregar_config_criaturas()["erros"], [] as Array[String])


func test_lobisomem_so_ataca_na_noite_de_quinta_para_sexta() -> void:
	var total := 0
	for semente in SEMENTES:
		for ataque in _simular("lobisomem_br", semente, 60)["registro"].buscar("criatura.ataque"):
			total += 1
			var relogio := Relogio.new(ataque["minuto"])
			if not relogio.noite_entre("quinta", "sexta"):
				fail("semente %d: ataque fora da noite de quinta para sexta (%s)" % [semente, str(relogio.data())])
	assert_gte(total, 1, "houve ataques para conferir")


func test_lobisomem_ataca_no_maximo_uma_vez_por_noite() -> void:
	for semente in SEMENTES:
		var noites := {}
		for ataque in _simular("lobisomem_br", semente, 60)["registro"].buscar("criatura.ataque"):
			var noite: int = (int(ataque["minuto"]) + 6 * 60) / Relogio.MINUTOS_POR_DIA
			if noites.has(noite):
				fail("semente %d: dois ataques na mesma noite" % semente)
			noites[noite] = true


func test_criatura_toda_marca_aponta_para_um_ataque_real() -> void:
	for semente in SEMENTES:
		var r: RefCounted = _simular("lobisomem_br", semente, 60)["registro"]
		for marca in r.buscar("marca.depositada"):
			var origem: Dictionary = r.obter(int(marca["dados"]["evento_origem"]))
			if origem.get("tipo", "") != "criatura.ataque" or origem["minuto"] != marca["minuto"] or origem["local"] != marca["local"]:
				fail("semente %d: marca %s sem ataque de origem coerente" % [semente, marca["dados"]["tag"]])


func test_criatura_marca_sempre_aparece_em_todo_ataque() -> void:
	for semente in SEMENTES:
		var r: RefCounted = _simular("lobisomem_br", semente, 60)["registro"]
		var com_pegada := {}
		for marca in r.buscar("marca.depositada"):
			if marca["dados"]["tag"] == "pegadas_cao_grande":
				com_pegada[int(marca["dados"]["evento_origem"])] = true
		for ataque in r.buscar("criatura.ataque"):
			if not com_pegada.has(ataque["id"]):
				fail("semente %d: ataque %d sem a marca 'sempre'" % [semente, ataque["id"]])


func test_criatura_nao_deposita_marca_de_testemunha_nem_de_registro() -> void:
	var r: RefCounted = _simular("lobisomem_br", 1, 60)["registro"]
	for marca in r.buscar("marca.depositada"):
		assert_has(["cena", "corpo", "ambiente", "covil"], marca["dados"]["onde"], marca["dados"]["tag"])


func test_curupira_sem_provocacao_nao_ataca_e_com_provocacao_ataca_uma_vez() -> void:
	var barramento := Barramento.new()
	var curupira := Criatura.new(_ficha("curupira"), "curupira#1", Rng.new(7), barramento, _config(), LOCAIS)
	var inicio := Relogio.minutos_de(2015, 11, 9)
	curupira.despertar(inicio, "teste")
	for hora in 10 * 24:
		curupira.passo(inicio + hora * 60)
	assert_eq(barramento.registro.buscar("criatura.ataque").size(), 0, "sem provocação")
	var depois := inicio + 10 * 24 * 60
	curupira.provocar(depois, "desmatamento")
	for hora in 10 * 24:
		curupira.passo(depois + hora * 60)
	assert_eq(barramento.registro.buscar("criatura.ataque").size(), 1, "uma resposta por provocação")


func test_criatura_necessidade_nao_atendida_escala_ate_o_maximo() -> void:
	var config := _config({"chance_ataque_por_hora": 0.0})
	var resultado := _simular("lobisomem_br", 1, 70, config)
	var maximo := int(config["escalada_maxima"])
	assert_eq(resultado["criatura"].nivel_escalada, maximo, "nível final")
	assert_eq(resultado["registro"].buscar("criatura.escalou").size(), maximo, "um evento por nível")
	assert_eq(resultado["registro"].buscar("criatura.ataque").size(), 0, "sem ataques com chance zero")


func test_criatura_escalada_libera_vitimas_piores() -> void:
	var config := _config({"chance_ataque_por_hora": 0.0})
	var resultado := _simular("lobisomem_br", 3, 70, config)
	var criatura: RefCounted = resultado["criatura"]
	criatura._config["chance_ataque_por_hora"] = 1.0
	var alvos := {}
	var inicio := Relogio.minutos_de(2015, 11, 9) + 70 * 24 * 60
	for hora in 120 * 24:
		criatura.passo(inicio + hora * 60)
	for ataque in resultado["registro"].buscar("criatura.ataque"):
		alvos[ataque["dados"]["alvo"]] = true
	assert_has(alvos, "pessoas_sozinhas", "no nível máximo, pessoas viram alvo")


func test_criatura_reacao_ao_cacador_depende_da_inteligencia() -> void:
	var esperado := {"lobisomem_br": "ataca_o_cacador", "curupira": "muda_de_rotina", "golpe_humano": "planta_pista_falsa"}
	for especie in esperado:
		var barramento := Barramento.new()
		var criatura := Criatura.new(_ficha(especie), "%s#1" % especie, Rng.new(1), barramento, _config(), LOCAIS)
		criatura.despertar(0, "teste")
		criatura.perceber_cacador(60)
		var reacoes: Array = barramento.registro.buscar("criatura.reagiu")
		assert_eq(reacoes.size(), 1, especie)
		if reacoes.size() == 1:
			assert_eq(reacoes[0]["dados"]["reacao"], esperado[especie], especie)


func test_criatura_janela_de_quinta_para_sexta() -> void:
	var lobo := Criatura.new(_ficha("lobisomem_br"), "lobo#1", Rng.new(1), Barramento.new(), _config(), LOCAIS)
	assert_true(lobo.em_janela(Relogio.minutos_de(2015, 11, 12, 23, 30)), "quinta 23h30")
	assert_true(lobo.em_janela(Relogio.minutos_de(2015, 11, 13, 2, 0)), "sexta 2h")
	assert_false(lobo.em_janela(Relogio.minutos_de(2015, 11, 13, 23, 30)), "sexta 23h30")
	assert_false(lobo.em_janela(Relogio.minutos_de(2015, 11, 12, 22, 0)), "quinta 22h")
