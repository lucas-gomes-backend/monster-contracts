extends Control
## Tela do ritual (docs/06): a lista de rituais para escolher, ou o passo atual com a barra do
## teste de reflexo (janela e marcador) ou as palavras para escolher.

var cena: Node  # bairro_cena: ritual, rituais, tempo do passo, medo, ferimentos


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if cena == null:
		return
	var fonte := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
	var linhas: Array = []
	if cena.ritual == null:
		linhas.append("Qual ritual? (tecla do número, Esc cancela)")
		for i in cena.rituais.size():
			var r: Dictionary = cena.rituais[i]
			var materiais: Array = []
			for m in r["materiais"]:
				materiais.append("%s x%d" % [str(m["item"]).replace("_", " "), int(m["quantidade"])])
			linhas.append("%d) %s  [%s]" % [i + 1, r["nome"], ", ".join(materiais) if not materiais.is_empty() else "sem materiais"])
		_escrever(fonte, linhas)
		return
	var ritual: RefCounted = cena.ritual
	var p: Dictionary = ritual.passo_atual()
	linhas.append("%s: passo %d de %d" % [ritual.def["nome"], ritual.passo + 1, ritual.def["passos"].size()])
	linhas.append(str(p.get("texto", "")))
	if p.get("tipo", "") == "palavra":
		for i in p["opcoes"].size():
			linhas.append("%d) %s" % [i + 1, p["opcoes"][i]])
		_escrever(fonte, linhas)
		return
	linhas.append("Espaço: aperte na faixa clara" if p["tipo"] == "apertar" else "Espaço: segure e solte na faixa clara")
	_escrever(fonte, linhas)
	var tremor: float = cena.medo.tremor()
	var dificuldade: float = cena.ferimentos.modificadores()["ritual"]
	var barra := Rect2(Vector2(20, size.y - 34), Vector2(size.x - 40, 14))
	draw_rect(barra, Color(0.15, 0.13, 0.1))
	var largura: float = ritual.largura(tremor, dificuldade)
	var meio: float = ritual.centro_em(cena.tempo_do_passo, tremor)
	draw_rect(Rect2(barra.position + Vector2(barra.size.x * (meio - largura / 2.0), 0), Vector2(barra.size.x * largura, barra.size.y)), Color(0.95, 0.9, 0.6))
	var x: float = barra.position.x + barra.size.x * ritual.marcador(cena.tempo_do_passo)
	draw_rect(Rect2(Vector2(x - 2, barra.position.y - 4), Vector2(4, barra.size.y + 8)), Color(0.8, 0.15, 0.1))


func _escrever(fonte: Font, linhas: Array) -> void:
	for i in linhas.size():
		draw_string(fonte, Vector2(14, 22 + i * 16), str(linhas[i]), HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 12, Color(0.95, 0.92, 0.85))
