extends Control
## Tela da mochila (docs/08): a grade com os itens, o cursor e o item na mão. Perto do carro,
## Tab troca para o porta-malas. Os itens vêm da cena (bairro_cena.gd).

const CASA := 34.0

var cena: Node  # bairro_cena: mochila, porta_malas, grade_aberta, cursor, na_mao, itens


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if cena == null:
		return
	var fonte := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.05, 0.82))
	var grade: RefCounted = cena.grade_aberta()
	var titulo := "MOCHILA" if grade == cena.mochila else "PORTA-MALAS"
	draw_string(fonte, Vector2(12, 18), "%s   peso da mochila: %.1f kg" % [titulo, cena.mochila.peso_g() / 1000.0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.9, 0.8))
	var origem := Vector2(12, 28)
	for y in grade.altura:
		for x in grade.largura:
			draw_rect(Rect2(origem + Vector2(x, y) * CASA, Vector2(CASA - 2, CASA - 2)), Color(0.3, 0.28, 0.25))
	for e in grade.entradas:
		var r := Rect2(origem + Vector2(e["x"], e["y"]) * CASA, Vector2(e["w"], e["h"]) * CASA - Vector2(2, 2))
		draw_rect(r, Color(0.35, 0.3, 0.22))
		var nome: String = cena.itens[e["item"]]["nome"]
		draw_string(fonte, r.position + Vector2(3, 12), nome.substr(0, 6 * int(e["w"])), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 4, 9, Color(0.95, 0.92, 0.85))
		if int(e["quantidade"]) > 1:
			draw_string(fonte, r.position + Vector2(3, r.size.y - 4), "x%d" % int(e["quantidade"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 0.9, 0.5))
	var c: Vector2i = cena.cursor
	var w := 1
	var h := 1
	if not cena.na_mao.is_empty():
		w = cena.na_mao["w"]
		h = cena.na_mao["h"]
	var cor := Color(1, 0.85, 0.3) if cena.na_mao.is_empty() else (Color(0.4, 1, 0.4) if grade.cabe(c.x, c.y, w, h) else Color(1, 0.3, 0.3))
	draw_rect(Rect2(origem + Vector2(c) * CASA, Vector2(w, h) * CASA - Vector2(2, 2)), cor, false, 2.0)
	var dica := "Setas mover · Espaço pegar/soltar · R girar · B pôr no bolso · I fechar"
	if cena.perto_do_carro():
		draw_string(fonte, Vector2(12, size.y - 8), "Tab: trocar entre mochila e porta-malas (o carro está perto)", HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 10, Color(0.8, 0.8, 0.75))
	draw_string(fonte, Vector2(12, size.y - 22), dica, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 10, Color(0.8, 0.8, 0.75))
	if not cena.na_mao.is_empty():
		draw_string(fonte, Vector2(12, size.y - 38), "Na mão: %s x%d" % [cena.itens[cena.na_mao["item"]]["nome"], int(cena.na_mao["quantidade"])], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 1, 0.4))
