extends "res://tests/framework/test_case.gd"
## Fase 3: um bairro do mapa real montado em 3D (presentation/cidade). Inclui física de
## verdade: o caçador precisa pisar no terreno importado e andar pela rua.

const Cena := preload("res://presentation/cidade/bairro_cena.gd")
const Lotes := preload("res://core/cidade/lotes.gd")
const PASSO := 1.0 / 60.0

var _cena: Node3D


func _montar(id: String) -> void:
	_cena = Cena.new()
	_cena.montar(id, 1)
	(Engine.get_main_loop() as SceneTree).root.add_child(_cena)


func after_each() -> void:
	if _cena:
		_cena.get_parent().remove_child(_cena)
		_cena.free()
		_cena = null


func _andar(entrada: Vector2, segundos: float) -> void:
	for i in int(segundos / PASSO):
		_cena.cacador.passo(entrada, false, PASSO)


func test_bairro_um_predio_por_lote_de_predio() -> void:
	_montar("valongo")
	var b: Node3D = _cena.bairro
	var de_predio := 0
	for lote in b.lotes:
		if lote["tipo"] == Lotes.TIPO_PREDIO:
			de_predio += 1
	assert_gte(de_predio, 10)
	assert_eq(b.predios.size(), de_predio)


func test_bairro_morro_tem_mata_e_o_pico_alto() -> void:
	_montar("monte_serrat")
	var b: Node3D = _cena.bairro
	assert_gte(b.arvores.multimesh.instance_count, 100, "o morro é coberto de mata")
	var pico: Dictionary = {}
	for m in b.dados["marcos"]:
		if m["tipo"] == "natural=peak":
			pico = m
	assert_gte(b.terreno.altura(float(pico["posicao"][0]), float(pico["posicao"][1])), 60.0, "o topo fica bem acima da rua")


func test_bairro_cacador_cai_no_chao_e_fica_em_pe() -> void:
	for id in ["valongo", "monte_serrat"]:
		_montar(id)
		_andar(Vector2.ZERO, 1.0)
		var p: Vector3 = _cena.cacador.position
		var chao: float = _cena.bairro.terreno.altura(p.x, p.z)
		assert_true(_cena.cacador.is_on_floor(), "%s: está no chão" % id)
		assert_almost_eq(p.y, chao, 0.25, "%s: os pés no terreno (y %.2f, chão %.2f)" % [id, p.y, chao])
		after_each()


func test_bairro_cacador_anda_pela_rua_sem_atravessar_o_chao() -> void:
	_montar("valongo")
	_andar(Vector2.ZERO, 0.5)
	var antes: Vector3 = _cena.cacador.position
	_andar(Vector2(0, 1), 2.0)
	var depois: Vector3 = _cena.cacador.position
	assert_gte(Vector2(antes.x, antes.z).distance_to(Vector2(depois.x, depois.z)), 2.0, "andou pela rua")
	var chao: float = _cena.bairro.terreno.altura(depois.x, depois.z)
	assert_true(depois.y > chao - 0.25, "não afundou no chão (y %.2f, chão %.2f)" % [depois.y, chao])


func test_bairro_chegada_e_um_ponto_de_verdade_em_todo_bairro() -> void:
	for id in ["valongo", "monte_serrat"]:
		_montar(id)
		var p: Vector3 = _cena.cacador.position
		assert_true(p.is_finite(), "%s: chegada %s" % [id, p])
		assert_true(Geometry2D.is_point_in_polygon(Vector2(p.x, p.z), Lotes._pontos(_cena.bairro.dados["limite"])), "%s: chega dentro do bairro" % id)
		after_each()
