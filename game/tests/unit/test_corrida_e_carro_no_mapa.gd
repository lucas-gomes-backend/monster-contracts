extends "res://tests/framework/test_case.gd"
## Pedidos do Lucas: correr liga e desliga no Shift (não segura) e o carro aparece no minimapa.

const Cena := preload("res://presentation/cidade/bairro_cena.gd")
const Minimapa := preload("res://presentation/cidade/minimapa.gd")


func _cena() -> Node3D:
	var cena := Cena.new()
	cena.montar("valongo", 1)
	return cena


func test_shift_liga_e_desliga_a_corrida() -> void:
	var cena := _cena()
	var c: CharacterBody3D = cena.cacador
	assert_false(c.correndo_ligado)
	var shift := InputEventKey.new()
	shift.physical_keycode = KEY_SHIFT
	shift.pressed = true
	c._unhandled_input(shift)
	assert_true(c.correndo_ligado, "um toque liga")
	c._unhandled_input(shift)
	assert_false(c.correndo_ligado, "outro desliga")
	cena.free()


func test_parar_de_andar_desliga_a_corrida() -> void:
	var cena := _cena()
	(Engine.get_main_loop() as SceneTree).root.add_child(cena)
	var c: CharacterBody3D = cena.cacador
	c.alternar_corrida()
	c._physics_process(1.0 / 60.0)  # sem tecla nenhuma: parado
	assert_false(c.correndo_ligado)
	cena.get_parent().remove_child(cena)
	cena.free()


func test_carro_aparece_no_minimapa_perto_e_preso_na_borda_longe() -> void:
	var cena := _cena()
	var mapa: Control = cena.minimapa
	var meio := Vector2(Minimapa.TAMANHO, Minimapa.TAMANHO) / 2.0
	var perto: Vector2 = mapa.posicao_do_carro()
	assert_ne(perto, Vector2.INF, "o carro estacionado do lado aparece")
	assert_true(perto.distance_to(meio) < 10.0, "pertinho da seta")
	cena.carro.position += Vector3(500, 0, 0)
	var longe: Vector2 = mapa.posicao_do_carro()
	assert_almost_eq(longe.distance_to(meio), Minimapa.TAMANHO / 2.0 - 8.0, 0.01, "longe: na borda, apontando o caminho")
	cena.carro.position -= Vector3(500, 0, 0)
	assert_true(cena.entrar_no_carro())
	assert_eq(mapa.posicao_do_carro(), Vector2.INF, "dirigindo, a seta já é o carro")
	cena.free()
