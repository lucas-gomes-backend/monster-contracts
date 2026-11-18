extends "res://tests/framework/test_case.gd"
## Menu de pausa (Esc) e o ritmo da cidade (pessoas e mochila mais rápidas, pedido do Lucas).

const Cena := preload("res://presentation/cidade/bairro_cena.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")


func _cena() -> Node3D:
	var cena := Cena.new()
	cena.montar("valongo", 1)
	(Engine.get_main_loop() as SceneTree).root.add_child(cena)
	return cena


func _soltar(cena: Node3D) -> void:
	(Engine.get_main_loop() as SceneTree).paused = false
	cena.get_parent().remove_child(cena)
	cena.free()


func _esc() -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = KEY_ESCAPE
	e.pressed = true
	return e


func test_pausa_para_o_jogo_e_continuar_volta() -> void:
	var cena := _cena()
	cena.abrir_pausa()
	assert_true(cena.pausa_tela.visible)
	assert_true(cena.get_tree().paused, "o jogo para")
	assert_eq(cena.pausa_tela.process_mode, Node.PROCESS_MODE_ALWAYS, "o menu continua respondendo")
	cena.fechar_pausa()
	assert_false(cena.pausa_tela.visible)
	assert_false(cena.get_tree().paused)
	_soltar(cena)


func test_esc_no_menu_volta_da_subpagina_e_depois_continua() -> void:
	var cena := _cena()
	cena.abrir_pausa()
	cena.pausa_tela.mostrar("opcoes")
	cena.pausa_tela._input(_esc())
	assert_true(cena.pausa_tela.visible, "das opções volta para a pausa")
	assert_eq(cena.pausa_tela._pagina, "principal")
	cena.pausa_tela._input(_esc())
	assert_false(cena.pausa_tela.visible, "da pausa volta ao jogo")
	assert_false(cena.get_tree().paused)
	_soltar(cena)


func test_paginas_do_menu_tem_os_botoes() -> void:
	var cena := _cena()
	cena.abrir_pausa()
	var textos := func() -> Array:
		var lista: Array = []
		for filho in cena.pausa_tela._caixa.get_children():
			if filho is Button:
				lista.append(filho.text)
		return lista
	for b in ["Continuar", "Controles", "Opções", "Menu principal", "Sair do jogo"]:
		assert_has(textos.call(), b)
	cena.pausa_tela.mostrar("opcoes")
	var tem_slider := false
	for filho in cena.pausa_tela._caixa.get_children():
		tem_slider = tem_slider or filho is HSlider
	assert_true(tem_slider, "opções com sliders")
	_soltar(cena)


func test_pessoas_andam_no_ritmo_da_cidade_reduzida_e_a_mochila_abre_rapido() -> void:
	assert_gte(float(Catalogo.carregar_config_relogio_da_cidade()["dados"]["velocidade_a_pe"]), 2.5)
	assert_gte(float(Catalogo.carregar_config_transeuntes()["dados"]["velocidade"][0]), 2.0)
	var cacador: Dictionary = Catalogo.carregar_config_personagem()["dados"]
	var policia: float = Catalogo.carregar_config_suspeita()["dados"]["policia"]["velocidade"]
	assert_true(policia > float(cacador["velocidade_andar"]) and policia < float(cacador["velocidade_correr"]), "a polícia alcança quem anda, não quem corre")
	assert_true(float(Catalogo.carregar_config_inventario()["dados"]["abrir_mochila_segundos"]) <= 0.5)
