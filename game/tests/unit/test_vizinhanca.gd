extends "res://tests/framework/test_case.gd"
## Fase 3: divisas entre os bairros do mapa real (core/cidade/vizinhanca.gd).

const Catalogo := preload("res://core/dados/catalogo.gd")
const Viz := preload("res://core/cidade/vizinhanca.gd")
const Lotes := preload("res://core/cidade/lotes.gd")


func _limites() -> Dictionary:
	var limites := {}
	for id in Catalogo.bairros_reais():
		limites[id] = Lotes._pontos(Catalogo.carregar_bairro_real(id)["dados"]["limite"])
	return limites


func test_vizinhanca_dos_bairros_importados() -> void:
	var v := Viz.vizinhos(_limites())
	assert_has(v["valongo"], "centro")
	assert_has(v["centro"], "monte_serrat")
	assert_has(v["centro"], "paqueta")
	assert_false("paqueta" in v["valongo"], "Valongo e Paquetá não fazem divisa")
	for id in v:
		for outro in v[id]:
			assert_has(v[outro], id, "divisa de mão dupla: %s e %s" % [id, outro])


func test_vizinhanca_quadrados_encostados_e_separados() -> void:
	var a := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)])
	var b := PackedVector2Array([Vector2(12, 0), Vector2(20, 0), Vector2(20, 10), Vector2(12, 10)])
	var c := PackedVector2Array([Vector2(40, 0), Vector2(50, 0), Vector2(50, 10), Vector2(40, 10)])
	assert_true(Viz.encostam(a, b), "a 2 m: divisa")
	assert_false(Viz.encostam(a, c), "a 30 m: não")


func test_bairro_em_prefere_o_atual_na_sobreposicao() -> void:
	var a := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)])
	var b := PackedVector2Array([Vector2(8, 0), Vector2(20, 0), Vector2(20, 10), Vector2(8, 10)])
	var limites := {"a": a, "b": b}
	assert_eq(Viz.bairro_em(Vector2(5, 5), limites), "a")
	assert_eq(Viz.bairro_em(Vector2(15, 5), limites), "b")
	assert_eq(Viz.bairro_em(Vector2(9, 5), limites, "b"), "b", "na faixa dos dois, fica no atual")
	assert_eq(Viz.bairro_em(Vector2(9, 5), limites, "a"), "a")
	assert_eq(Viz.bairro_em(Vector2(99, 5), limites), "", "fora de todos")
