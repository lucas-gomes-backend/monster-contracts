extends "res://tests/framework/test_case.gd"
## Fase 4: os bairros do corte vertical (Valongo e Centro) com gente de verdade: lugares
## nos lotes reais, cerca de 30 moradores com rotina e caminhos a pé pelas ruas.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Bairro := preload("res://core/mundo/bairro.gd")
const Lotes := preload("res://core/cidade/lotes.gd")
const Lugares := preload("res://core/cidade/lugares_reais.gd")
const Caminhos := preload("res://core/cidade/caminhos.gd")
const Populacao := preload("res://core/npcs/gerador_populacao.gd")
const Rotina := preload("res://core/npcs/rotina.gd")

const BAIRROS := ["valongo", "centro"]


func _real(id: String) -> Dictionary:
	return Catalogo.carregar_bairro_real(id)["dados"]


func _lotes(id: String, semente: int = 1) -> Array:
	return Lotes.gerar(_real(id), Catalogo.carregar_config_lotes()["dados"], Rng.new(semente))


func _abstrato(id: String) -> RefCounted:
	return Bairro.new(Catalogo.carregar_bairro(id)["dados"])


func test_bairros_do_corte_vertical_tem_dados_validos() -> void:
	for id in BAIRROS:
		var r := Catalogo.carregar_bairro(id)
		assert_eq(r["erros"].size(), 0, "%s: %s" % [id, r["erros"]])


func test_ruas_dos_dados_existem_no_mapa_real() -> void:
	for id in BAIRROS:
		var reais := {}
		for rua in _real(id)["ruas"]:
			reais[Lugares.slug(rua["nome"])] = true
		for rua in _abstrato(id).dados["ruas"]:
			assert_true(reais.has(rua), "%s: a rua %s existe no mapa" % [id, rua])


func test_slug_tira_acento_e_espaco() -> void:
	assert_eq(Lugares.slug("Rua São Bento"), "rua_sao_bento")
	assert_eq(Lugares.slug("Avenida Presidente Getúlio Dornelles Vargas"), "avenida_presidente_getulio_dornelles_vargas")
	assert_eq(Lugares.slug("Praça Mauá"), "praca_maua")


func test_cada_lugar_ganha_um_lote_so_dele_e_uma_porta_na_calcada() -> void:
	for id in BAIRROS:
		var abstrato := _abstrato(id)
		var real := _real(id)
		var lugares := Lugares.atribuir(abstrato, real, _lotes(id), Rng.new(1))
		assert_eq(lugares.size(), abstrato.ids_locais().size(), "%s: todo lugar tem lote" % id)
		var usados := {}
		for lugar in lugares:
			assert_false(usados.has(lugares[lugar]["lote"]), "%s: lote repetido em %s" % [id, lugar])
			usados[lugares[lugar]["lote"]] = true
			var porta: Vector2 = lugares[lugar]["porta"]
			var perto_de_rua := false
			for rua in real["ruas"]:
				var p := Lotes._pontos(rua["pontos"])
				for i in p.size() - 1:
					if porta.distance_to(Geometry2D.get_closest_point_to_segment(porta, p[i], p[i + 1])) < float(rua["largura"]) / 2.0 + 3.0:
						perto_de_rua = true
			assert_true(perto_de_rua, "%s: a porta de %s fica na calçada" % [id, lugar])


func test_lugar_fica_na_rua_pedida_quando_ha_lote_nela() -> void:
	var lugares := Lugares.atribuir(_abstrato("centro"), _real("centro"), _lotes("centro"), Rng.new(1))
	assert_eq(lugares["centro/catedral"]["rua"], "rua_general_camara", "a catedral na Rua General Câmara")


func test_cerca_de_30_moradores_com_rotina_em_cada_bairro() -> void:
	var cfg: Dictionary = Catalogo.carregar_config_populacao()["dados"]
	for id in BAIRROS:
		var abstrato := _abstrato(id)
		var gente := Populacao.gerar(abstrato, cfg, Rng.new(1))
		assert_true(gente.size() >= 25 and gente.size() <= 40, "%s: %d moradores" % [id, gente.size()])
		var rotina := Rotina.new(cfg, Rng.new(1), abstrato)
		var trabalhando := 0
		var minuto := 25000000 + 10 * 60  # um dia qualquer, às 10h
		for npc in gente:
			var onde: Dictionary = rotina.onde_esta(npc, minuto)
			assert_true(abstrato.existe(onde["local"]) or onde["local"] == Bairro.FORA_DO_BAIRRO, "%s: %s num lugar que existe" % [id, npc["id"]])
			if onde["atividade"] == "trabalhando":
				trabalhando += 1
		assert_gte(trabalhando, 1, "%s: de dia tem gente trabalhando" % id)


func test_caminho_a_pe_vai_pelas_ruas() -> void:
	var real := _real("valongo")
	var caminhos := Caminhos.new(real["ruas"])
	assert_gte(caminhos.pontos(), 50)
	var lugares := Lugares.atribuir(_abstrato("valongo"), real, _lotes("valongo"), Rng.new(1))
	var de: Vector2 = lugares["valongo/igreja"]["porta"]
	var para: Vector2 = lugares["valongo/bar"]["porta"]
	var c := caminhos.caminho(de, para)
	assert_eq(c[0], de)
	assert_eq(c[-1], para)
	assert_gte(c.size(), 3, "passa por pontos das ruas")
	for i in range(1, c.size() - 1):
		var na_rua := false
		for rua in real["ruas"]:
			var p := Lotes._pontos(rua["pontos"])
			for k in p.size() - 1:
				if c[i].distance_to(Geometry2D.get_closest_point_to_segment(c[i], p[k], p[k + 1])) < 0.5:
					na_rua = true
		assert_true(na_rua, "o ponto %d do caminho fica numa rua" % i)
