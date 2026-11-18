extends Control
## Tela da negociação (docs/06): a fala da criatura, a paciência dela e as ofertas (1 a 5).

var cena: Node  # bairro_cena: negociacao


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if cena == null or cena.negociacao == null:
		return
	var n: RefCounted = cena.negociacao
	var fonte := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.05, 0.02, 0.75))
	var linhas: Array = ["%s (paciência: %s)" % [n.ficha["nome"], "●".repeat(maxi(n.paciencia, 0))], "\"%s\"" % n.ultima_fala, ""]
	var ofertas: Array = n.ofertas()
	for i in ofertas.size():
		linhas.append("%d) %s" % [i + 1, ofertas[i]["texto"]])
	linhas.append("Esc: parar de conversar")
	for i in linhas.size():
		draw_string(fonte, Vector2(14, 20 + i * 16), str(linhas[i]), HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 12, Color(0.92, 0.95, 0.85))
