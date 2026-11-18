extends Control
## Tela das habilidades (H): as árvores, a experiência de cada uma, os pontos livres e as
## habilidades com o nível. Números 1 a 9 aprendem (na ordem da lista).

var cena: Node  # bairro_cena: habilidades


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if cena == null:
		return
	var h: RefCounted = cena.habilidades
	var fonte := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.08, 0.9))
	draw_string(fonte, Vector2(14, 20), "HABILIDADES · pontos usados %d de %d · número aprende · H fecha" % [h.pontos_gastos(), int(h._cfg["teto_de_pontos"])], HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 12, Color(0.95, 0.9, 0.75))
	var y := 44.0
	var i := 1
	for a in h.arvores():
		var xp_por_ponto := int(h._cfg["xp_por_ponto"])
		draw_string(fonte, Vector2(14, y), "%s · experiência %d (próximo ponto em %d) · pontos livres: %d" % [a["nome"], int(h.xp[a["id"]]), xp_por_ponto - int(h.xp[a["id"]]) % xp_por_ponto, h.pontos_livres(a["id"])], HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 12, Color(0.85, 0.8, 0.6))
		y += 18
		for hab in a["habilidades"]:
			var nivel: int = h.niveis[hab["id"]]
			var pode: bool = h.pode_aprender(hab["id"])["ok"]
			var cor := Color(0.95, 0.95, 0.9) if pode else (Color(0.6, 0.8, 0.6) if nivel > 0 else Color(0.6, 0.6, 0.6))
			draw_string(fonte, Vector2(24, y), "%d) %s %s · %s" % [i, hab["nome"], "●".repeat(nivel) + "○".repeat(h.nivel_maximo(hab["id"]) - nivel), hab["descricao"]], HORIZONTAL_ALIGNMENT_LEFT, size.x - 40, 11, cor)
			y += 16
			i += 1
		y += 6
