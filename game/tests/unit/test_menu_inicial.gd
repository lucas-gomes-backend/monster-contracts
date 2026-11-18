extends "res://tests/framework/test_case.gd"
## O menu inicial fica inteiro dentro da tela (640x480) e centralizado.

const Inicio := preload("res://ui/inicio.gd")


func test_menu_inicial_centralizado_e_dentro_da_tela() -> void:
	# Como no jogo: a tela monta o menu com tamanho 0 e só depois cresce até a janela.
	var tela := Inicio.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(tela)
	tela.size = Vector2(640, 480)
	var colunas := tela.find_children("*", "VBoxContainer", true, false)
	assert_eq(colunas.size(), 1, "uma coluna de botões")
	var coluna: Control = colunas[0]
	# Os containers arrumam os filhos no próximo quadro: força agora.
	coluna.notification(Container.NOTIFICATION_SORT_CHILDREN)
	if coluna.get_parent() is Container:
		coluna.get_parent().notification(Container.NOTIFICATION_SORT_CHILDREN)
	var r := coluna.get_global_rect()
	assert_true(r.position.x >= 0 and r.position.y >= 0, "começa dentro da tela: %s" % r)
	assert_true(r.end.x <= 640 and r.end.y <= 480, "termina dentro da tela: %s" % r)
	assert_true(absf(r.get_center().x - 320.0) < 2.0, "centralizado na horizontal: %s" % r)
	tela.get_parent().remove_child(tela)
	tela.free()
