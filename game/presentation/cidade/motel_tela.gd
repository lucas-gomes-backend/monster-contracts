extends Control
## Menu do motel (docs/08, "Base": quarto de motel): descansar, guardar coisas, comprar
## suprimentos e melhorias por telefone, abastecer o carro. Lista numerada (1 a 9).

var cena: Node  # bairro_cena: opcoes_do_motel(), progresso


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if cena == null:
		return
	var fonte := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.04, 0.06, 0.88))
	var p: RefCounted = cena.progresso
	var linhas: Array = ["%s   R$ %d · reputação: %s" % [cena.titulo_do_motel(), p.dinheiro, p.nivel_de_reputacao()], ""]
	var opcoes: Array = cena.opcoes_do_motel()
	for i in opcoes.size():
		linhas.append("%d) %s" % [i + 1, opcoes[i]["texto"]])
	linhas.append("")
	linhas.append("Esc: sair" if cena.menu_do_motel == "principal" else "Esc: voltar")
	for i in linhas.size():
		draw_string(fonte, Vector2(14, 20 + i * 16), str(linhas[i]), HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 12, Color(0.95, 0.9, 0.85))
