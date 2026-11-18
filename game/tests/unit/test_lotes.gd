extends "res://tests/framework/test_case.gd"
## Fase 3: gerador de lotes dos bairros do mapa real (core/cidade).

const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Lotes := preload("res://core/cidade/lotes.gd")

const BAIRROS := ["valongo", "monte_serrat"]

var _cfg: Dictionary


func before_each() -> void:
	_cfg = Catalogo.carregar_config_lotes()["dados"]


func _bairro(id: String) -> Dictionary:
	return Catalogo.carregar_bairro_real(id)["dados"]


func _limite(b: Dictionary) -> PackedVector2Array:
	return Lotes._pontos(b["limite"])


func test_lotes_config_valida() -> void:
	var r := Catalogo.carregar_config_lotes()
	assert_eq(r["erros"].size(), 0, str(r["erros"]))


func test_lotes_mesma_semente_mesmos_lotes_e_outra_semente_outros() -> void:
	var b := _bairro("valongo")
	var a := Lotes.gerar(b, _cfg, Rng.new(7))
	var c := Lotes.gerar(b, _cfg, Rng.new(7))
	var d := Lotes.gerar(b, _cfg, Rng.new(8))
	assert_eq(str(a), str(c), "mesma semente")
	assert_ne(str(a), str(d), "semente diferente")


func test_lotes_bairro_de_verdade_tem_bastante_lote() -> void:
	for id in BAIRROS:
		var lotes := Lotes.gerar(_bairro(id), _cfg, Rng.new(1))
		assert_gte(lotes.size(), 20, "%s: %d lotes" % [id, lotes.size()])


func test_lotes_ficam_dentro_do_bairro() -> void:
	for id in BAIRROS:
		var b := _bairro(id)
		var limite := _limite(b)
		for lote in Lotes.gerar(b, _cfg, Rng.new(1)):
			for p in Lotes.cantos(lote):
				assert_true(Geometry2D.is_point_in_polygon(p, limite), "%s: lote %d fora do bairro" % [id, lote["id"]])


func test_lotes_nao_invadem_rua_nem_calcada() -> void:
	for id in BAIRROS:
		var b := _bairro(id)
		for lote in Lotes.gerar(b, _cfg, Rng.new(1)):
			var cantos := Lotes.cantos(lote)
			for rua in b["ruas"]:
				var minimo: float = float(rua["largura"]) / 2.0
				var p := Lotes._pontos(rua["pontos"])
				for s in p.size() - 1:
					var d := Lotes.distancia_segmento_poligono(p[s], p[s + 1], cantos)
					assert_true(d >= minimo, "%s: lote %d invade %s (%.2f m)" % [id, lote["id"], rua["nome"], d])


func test_lotes_nao_se_sobrepoem() -> void:
	for id in BAIRROS:
		var lotes := Lotes.gerar(_bairro(id), _cfg, Rng.new(1))
		for i in lotes.size():
			for j in range(i + 1, lotes.size()):
				var cruzam := Geometry2D.intersect_polygons(Lotes.cantos(lotes[i]), Lotes.cantos(lotes[j]))
				assert_eq(cruzam.size(), 0, "%s: lotes %d e %d se sobrepõem" % [id, i, j])


func test_lotes_morro_tem_mata_e_o_centro_nao() -> void:
	var tipos := {}
	for lote in Lotes.gerar(_bairro("monte_serrat"), _cfg, Rng.new(1)) + Lotes.gerar(_bairro("monte_serrat"), _cfg, Rng.new(2)):
		tipos[lote["tipo"]] = true
	assert_true(tipos.has(Lotes.TIPO_MATA), "morro tem mata")
	for lote in Lotes.gerar(_bairro("valongo"), _cfg, Rng.new(1)):
		assert_ne(lote["tipo"], Lotes.TIPO_MATA, "o centro não tem mata no kit")
