extends "res://tests/framework/test_case.gd"
## Fase 4: pontos-chave (delegacia, biblioteca, igreja, benzedeira, cemitério, motel,
## mecânico, lan house) nos bairros, com gente trabalhando, placa e letra no minimapa.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Bairro := preload("res://core/mundo/bairro.gd")
const Populacao := preload("res://core/npcs/gerador_populacao.gd")
const Populacao3D := preload("res://presentation/cidade/populacao_3d.gd")
const Lotes := preload("res://core/cidade/lotes.gd")

const BAIRROS := ["valongo", "centro", "paqueta"]


func _gente(id: String) -> Array:
	return Populacao.gerar(Bairro.new(Catalogo.carregar_bairro(id)["dados"]), Catalogo.carregar_config_populacao()["dados"], Rng.new(1))


func test_pontos_chave_dados_validos() -> void:
	var r := Catalogo.carregar_pontos_chave()
	assert_eq(r["erros"].size(), 0, str(r["erros"]))


func test_todos_os_pontos_chave_existem_nos_bairros_carregados() -> void:
	var achados := {}
	for id in BAIRROS:
		var b := Bairro.new(Catalogo.carregar_bairro(id)["dados"])
		for local in b.ids_locais():
			achados[b.local(local)["tipo"]] = true
		for npc in _gente(id):
			if npc["ocupacao"].get("id", "") == "benzedeira":
				achados["benzedeira"] = true
	for tipo in Catalogo.carregar_pontos_chave()["dados"]["tipos"]:
		assert_true(achados.has(tipo), "%s existe em algum dos bairros" % tipo)


func test_tem_gente_trabalhando_nos_pontos_chave_do_centro() -> void:
	var trabalhos := {}
	for npc in _gente("centro"):
		trabalhos[npc.get("trabalho", "")] = true
	for local in ["centro/delegacia", "centro/biblioteca", "centro/lan_house", "centro/motel"]:
		assert_true(trabalhos.has(local), "alguém trabalha em %s" % local)


func test_placas_e_letras_no_minimapa_nas_portas() -> void:
	var real: Dictionary = Catalogo.carregar_bairro_real("centro")["dados"]
	var lotes := Lotes.gerar(real, Catalogo.carregar_config_lotes()["dados"], Rng.new(1))
	var gente := Populacao3D.new()
	gente.montar("centro", real, lotes, 1)
	var tipos := {}
	for ponto in gente.pontos_chave:
		tipos[ponto["tipo"]] = true
		var porta: Vector2 = gente.lugares[ponto["local"]]["porta"]
		assert_true(ponto["porta"] == porta, "%s na porta" % ponto["local"])
	for tipo in ["delegacia", "biblioteca", "lan_house", "motel", "igreja"]:
		assert_true(tipos.has(tipo), "o Centro tem %s no minimapa" % tipo)
	assert_gte(gente.placas.size(), gente.pontos_chave.size(), "todo ponto-chave tem placa")
	for placa in gente.placas:
		assert_false(placa.text.is_empty())
		assert_true(placa.position.y > 2.0, "a placa fica em cima da porta")
	gente.free()
