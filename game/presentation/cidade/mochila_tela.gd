extends Control
## Tela da mochila no estilo da maleta do Resident Evil 4 (docs/08): cada item aparece no
## formato dele, com cor, nome e quantidade; o item na mão flutua por cima, verde onde cabe e
## vermelho onde não cabe. Perto do carro, a mochila (sempre menor) e o porta-malas ficam
## lado a lado e o cursor passa de uma para a outra. Mouse: apontar escolhe a casa, botão
## esquerdo pega/solta, direito gira.

const MARGEM := 12.0
const ESPACO_ENTRE := 22.0
const TOPO := 34.0

var cena: Node  # bairro_cena: mochila, outra_grade(), foco, cursor, na_mao, itens


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


## Tamanho da casa: as duas grades lado a lado cabem na tela.
func casa() -> float:
	var colunas: int = cena.mochila.largura
	var linhas: int = cena.mochila.altura
	var outra: RefCounted = cena.outra_grade()
	if outra != null:
		colunas += outra.largura
		linhas = maxi(linhas, outra.altura)
	var largura_livre := size.x - MARGEM * 2.0 - (ESPACO_ENTRE if outra != null else 0.0)
	var altura_livre := size.y - TOPO - 56.0
	return floorf(minf(minf(largura_livre / colunas, altura_livre / linhas), 40.0))


func origem_de(qual: String) -> Vector2:
	if qual == "outra":
		return Vector2(MARGEM + cena.mochila.largura * casa() + ESPACO_ENTRE, TOPO)
	return Vector2(MARGEM, TOPO)


func _gui_input(evento: InputEvent) -> void:
	if cena == null:
		return
	if evento is InputEventMouseMotion or (evento is InputEventMouseButton and evento.pressed):
		for qual in (["mochila", "outra"] if cena.outra_grade() != null else ["mochila"]):
			var g: RefCounted = cena.mochila if qual == "mochila" else cena.outra_grade()
			var local: Vector2 = (evento.position - origem_de(qual)) / casa()
			if local.x >= 0 and local.y >= 0 and local.x < g.largura and local.y < g.altura:
				cena.apontar(qual, Vector2i(int(local.x), int(local.y)))
	if evento is InputEventMouseButton and evento.pressed:
		if evento.button_index == MOUSE_BUTTON_LEFT:
			cena.pegar_ou_soltar()
		elif evento.button_index == MOUSE_BUTTON_RIGHT:
			cena.girar_na_mao()
		accept_event()


func _draw() -> void:
	if cena == null:
		return
	var fonte := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.05, 0.04, 0.88))
	var c := casa()
	_grade(fonte, "mochila", "MOCHILA  %.1f kg" % (cena.mochila.peso_g() / 1000.0), c)
	if cena.outra_grade() != null:
		_grade(fonte, "outra", cena.nome_da_outra(), c)
	# O item na mão flutua sobre o cursor.
	var g: RefCounted = cena.grade_aberta()
	var o := origem_de(cena.foco if cena.outra_grade() != null else "mochila")
	var cur: Vector2i = cena.cursor
	if cena.na_mao.is_empty():
		draw_rect(Rect2(o + Vector2(cur) * c, Vector2(c, c)), Color(1, 0.85, 0.3), false, 2.0)
	else:
		var m: Dictionary = cena.na_mao
		var cabe: bool = g.cabe(cur.x, cur.y, int(m["w"]), int(m["h"]))
		var r := Rect2(o + Vector2(cur) * c, Vector2(int(m["w"]), int(m["h"])) * c)
		_item(fonte, r, m, 0.75)
		draw_rect(r, Color(0.3, 1, 0.3) if cabe else Color(1, 0.25, 0.25), false, 3.0)
	# Rodapé: o que está no cursor e os controles.
	var embaixo: Dictionary = g.em(cur.x, cur.y)
	var info := ""
	if not cena.na_mao.is_empty():
		info = "Na mão: %s x%d" % [cena.itens[cena.na_mao["item"]]["nome"], int(cena.na_mao["quantidade"])]
	elif not embaixo.is_empty():
		var d: Dictionary = cena.itens[embaixo["item"]]
		info = "%s x%d · %.1f kg%s" % [d["nome"], int(embaixo["quantidade"]), int(d["peso_g"]) * int(embaixo["quantidade"]) / 1000.0, " · frágil" if d["fragil"] else ""]
	draw_string(fonte, Vector2(MARGEM, size.y - 38), info, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 12, Color(0.95, 0.92, 0.7))
	draw_string(fonte, Vector2(MARGEM, size.y - 22), "Setas/mouse: mover · Espaço/clique: pegar e soltar · R/botão direito: girar · O: organizar · B: bolso · I: fechar", HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 10, Color(0.75, 0.75, 0.7))
	if cena.outra_grade() != null:
		draw_string(fonte, Vector2(MARGEM, size.y - 8), "Passe da borda (ou Tab) para o %s." % cena.nome_da_outra().to_lower(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 10, Color(0.75, 0.75, 0.7))


func _grade(fonte: Font, qual: String, titulo: String, c: float) -> void:
	var g: RefCounted = cena.mochila if qual == "mochila" else cena.outra_grade()
	var o := origem_de(qual)
	var em_foco: bool = cena.foco == qual or cena.outra_grade() == null
	draw_string(fonte, o + Vector2(0, -8), titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.9, 0.75) if em_foco else Color(0.6, 0.6, 0.55))
	draw_rect(Rect2(o - Vector2(3, 3), Vector2(g.largura, g.altura) * c + Vector2(6, 6)), Color(0.22, 0.2, 0.16))
	for y in g.altura:
		for x in g.largura:
			draw_rect(Rect2(o + Vector2(x, y) * c + Vector2(1, 1), Vector2(c - 2, c - 2)), Color(0.1, 0.12, 0.1))
	for e in g.entradas:
		_item(fonte, Rect2(o + Vector2(e["x"], e["y"]) * c, Vector2(e["w"], e["h"]) * c), e, 1.0)


## Um item no formato: bloco na cor dele, nome e a quantidade no canto (como na maleta).
func _item(fonte: Font, r: Rect2, e: Dictionary, alfa: float) -> void:
	var d: Dictionary = cena.itens[e["item"]]
	var cor := Color(str(d["cor"]))
	var dentro := r.grow(-2.0)
	draw_rect(dentro, Color(cor.r * 0.55, cor.g * 0.55, cor.b * 0.55, alfa))
	draw_rect(dentro.grow(-3.0), Color(cor.r, cor.g, cor.b, alfa))
	draw_rect(dentro, Color(0, 0, 0, alfa), false, 1.0)
	var claro := cor.get_luminance() > 0.55
	var tinta := Color(0.08, 0.08, 0.08, alfa) if claro else Color(0.97, 0.95, 0.9, alfa)
	var tamanho := 11 if d.has("arma") else 9
	draw_string(fonte, dentro.position + Vector2(4, 12), str(d["nome"]), HORIZONTAL_ALIGNMENT_LEFT, dentro.size.x - 6, tamanho, tinta)
	if int(e["quantidade"]) > 1:
		var q := str(int(e["quantidade"]))
		var w := fonte.get_string_size(q, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(fonte, dentro.end - Vector2(w + 3, 3), q, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.95, 0.4, alfa))
	if d.has("arma"):
		var municao: int = cena.arsenal.municao.get(d["arma"], 0)
		var cap: int = int(cena.arsenal.arma_de(d["arma"])["capacidade"])
		draw_string(fonte, Vector2(dentro.position.x + 4, dentro.end.y - 4), "%d/%d" % [municao, cap], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.95, 0.4, alfa))
