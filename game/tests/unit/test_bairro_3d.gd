extends "res://tests/framework/test_case.gd"
## Fase 3: um bairro do mapa real montado em 3D (presentation/cidade). Inclui física de
## verdade: o caçador precisa pisar no chão (a cidade é plana) e andar pela rua.

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


func test_bairro_morro_tem_mata_e_tudo_fica_no_chao_plano() -> void:
	_montar("monte_serrat")
	var b: Node3D = _cena.bairro
	assert_gte(b.arvores.multimesh.instance_count, 100, "o morro é coberto de mata")
	for predio in b.predios:
		var forma: BoxShape3D = predio.get_child(0).shape
		assert_almost_eq(predio.position.y - forma.size.y / 2.0, 0.0, 0.001, "%s apoiado no chão" % predio.name)


func test_bairro_cacador_cai_no_chao_e_fica_em_pe() -> void:
	for id in ["valongo", "monte_serrat"]:
		_montar(id)
		_andar(Vector2.ZERO, 1.0)
		var p: Vector3 = _cena.cacador.position
		assert_true(_cena.cacador.is_on_floor(), "%s: está no chão" % id)
		assert_almost_eq(p.y, 0.0, 0.05, "%s: os pés no chão (y %.2f)" % [id, p.y])
		after_each()


func test_bairro_cacador_anda_pela_rua_sem_atravessar_o_chao() -> void:
	_montar("valongo")
	_andar(Vector2.ZERO, 0.5)
	var antes: Vector3 = _cena.cacador.position
	_andar(Vector2(0, 1), 2.0)
	var depois: Vector3 = _cena.cacador.position
	assert_gte(Vector2(antes.x, antes.z).distance_to(Vector2(depois.x, depois.z)), 2.0, "andou pela rua")
	assert_almost_eq(depois.y, 0.0, 0.05, "continua no chão plano (y %.2f)" % depois.y)


func test_bairro_chegada_e_um_ponto_de_verdade_em_todo_bairro() -> void:
	for id in ["valongo", "monte_serrat"]:
		_montar(id)
		var p: Vector3 = _cena.cacador.position
		assert_true(p.is_finite(), "%s: chegada %s" % [id, p])
		assert_true(Geometry2D.is_point_in_polygon(Vector2(p.x, p.z), Lotes._pontos(_cena.bairro.dados["limite"])), "%s: chega dentro do bairro" % id)
		after_each()


func test_subterraneo_fica_embaixo_com_um_bueiro_por_ponto_de_descida() -> void:
	_montar("valongo")
	var b: Node3D = _cena.bairro
	assert_true(b.subterraneo.position.y < -2.0, "as galerias ficam embaixo da rua")
	assert_eq(b.bueiros.size(), b.galerias["bueiros"].size())
	assert_gte(b.bueiros.size(), 1)


func test_bueiro_desce_para_a_galeria_escura_e_a_escada_sobe() -> void:
	_montar("valongo")
	_cena.usar_bueiro(0)
	assert_eq(_cena.zona, "esgoto")
	assert_false(_cena.sol.visible, "o sol não chega lá embaixo")
	_andar(Vector2.ZERO, 1.0)
	var p: Vector3 = _cena.cacador.position
	assert_true(_cena.cacador.is_on_floor(), "pisa no piso da galeria")
	assert_almost_eq(p.y, -_cena.bairro.profundidade, 0.1, "no fundo (y %.2f)" % p.y)
	_cena.usar_bueiro(0)
	assert_eq(_cena.zona, "rua")
	assert_true(_cena.sol.visible)


func test_paredes_da_galeria_seguram_o_cacador() -> void:
	# Lá embaixo, andando em todas as direções por um tempo: nunca sai do traçado das galerias.
	const Sub := preload("res://core/cidade/subterraneo.gd")
	_montar("valongo")
	_cena.usar_bueiro(0)
	_andar(Vector2.ZERO, 0.5)
	for direcao in [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 1)]:
		_andar(direcao, 2.0)
		var p: Vector3 = _cena.cacador.position
		assert_true(Sub.dentro_da_galeria(Vector2(p.x, p.z), _cena.bairro.galerias["corredores"]), "atravessou a parede em %s" % p)
		assert_true(p.y > -_cena.bairro.profundidade - 0.5, "não caiu do piso")
