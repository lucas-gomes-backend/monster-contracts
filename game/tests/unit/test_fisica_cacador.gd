extends "res://tests/framework/test_case.gd"
## Fase 2: o caçador andando com física de verdade na rua cinza (a cena entra na árvore
## e cada passo chama move_and_slide). Pega o que as contas puras não pegam: degraus.

const Rua := preload("res://presentation/greybox/rua.gd")
const PASSO := 1.0 / 60.0

var _rua: Node3D


func before_each() -> void:
	_rua = Rua.new()
	_rua.montar(12)
	(Engine.get_main_loop() as SceneTree).root.add_child(_rua)


func after_each() -> void:
	_rua.get_parent().remove_child(_rua)
	_rua.free()


func _andar(entrada: Vector2, segundos: float) -> void:
	for i in int(segundos / PASSO):
		_rua.cacador.passo(entrada, false, PASSO)


func test_cacador_fica_em_pe_no_asfalto() -> void:
	_rua.cacador.position = Vector3(1.0, 0.05, 0.0)
	_andar(Vector2.ZERO, 0.5)
	assert_true(_rua.cacador.is_on_floor(), "está no chão")
	assert_almost_eq(_rua.cacador.position.y, 0.0, 0.02, "em cima do asfalto")


func test_cacador_sobe_o_meio_fio_andando() -> void:
	# Do asfalto, andando para a direita (+x), até passar da guia da calçada (x = 3,5).
	_rua.cacador.position = Vector3(2.5, 0.05, 0.0)
	_andar(Vector2(1, 0), 1.5)
	assert_true(_rua.cacador.position.x > 4.0, "passou da guia: x = %.2f" % _rua.cacador.position.x)
	assert_almost_eq(_rua.cacador.position.y, Rua.ALTURA_CALCADA, 0.03, "em cima da calçada")


func test_cacador_desce_o_meio_fio_sem_flutuar() -> void:
	_rua.cacador.position = Vector3(4.5, Rua.ALTURA_CALCADA + 0.05, 0.0)
	_andar(Vector2(-1, 0), 1.5)
	assert_true(_rua.cacador.position.x < 3.0, "voltou para o asfalto")
	assert_almost_eq(_rua.cacador.position.y, 0.0, 0.03, "no asfalto, sem flutuar")


func test_cacador_nao_sobe_parede_de_casa() -> void:
	# Na calçada da direita, andando contra a fachada das casas (x = 6): parede alta não é degrau.
	_rua.cacador.position = Vector3(5.0, Rua.ALTURA_CALCADA + 0.05, -20.0)
	_andar(Vector2(1, 0), 2.0)
	assert_true(_rua.cacador.position.x < 6.0, "parou na parede")
	assert_almost_eq(_rua.cacador.position.y, Rua.ALTURA_CALCADA, 0.05, "não subiu na parede")


func test_cacador_sai_do_canal_do_esgoto_para_a_passarela() -> void:
	_rua.usar_passagem("bueiro")
	var base: Vector3 = _rua.esgoto.position
	# No meio do canal (fundo 0,4 abaixo das passarelas), andando para a passarela da direita.
	_rua.cacador.virar_para(0.0)
	_rua.cacador.position = base + Vector3(0.0, -0.35, 6.0)
	_andar(Vector2.ZERO, 0.3)
	_andar(Vector2(1, 0), 1.5)
	assert_true(_rua.cacador.position.x - base.x > 1.1, "chegou na passarela")
	assert_almost_eq(_rua.cacador.position.y, base.y, 0.05, "em cima da passarela")
