extends Control
## Mapa de viagem rápida (só dentro do carro): os pontos dos bairros carregados num mapa
## simples, com o número, o tempo e a gasolina de cada viagem. Número ou clique no ponto viaja.

const Lotes := preload("res://core/cidade/lotes.gd")

var cena: Node  # bairro_cena: destinos_de_viagem(), viajar(), carro, carregados
var _pontos_na_tela: Array = []


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		for i in _pontos_na_tela.size():
			if evento.position.distance_to(_pontos_na_tela[i]) <= 10.0:
				cena.viajar(i)
				accept_event()
				return


func _draw() -> void:
	if cena == null or cena.carro == null:
		return
	var fonte := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.08, 0.92))
	draw_string(fonte, Vector2(12, 18), "MAPA DE VIAGEM · gasolina: %.1f L · número ou clique para ir · M fecha" % cena.carro.litros, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 12, Color(0.95, 0.9, 0.75))
	var destinos: Array = cena.destinos_de_viagem()
	var carro := Vector2(cena.carro.position.x, cena.carro.position.z)
	var area := Rect2(carro, Vector2.ZERO)
	for d in destinos:
		area = area.expand(d["ponto"])
	for id in cena.carregados:
		for q in cena.carregados[id].dados["limite"]:
			area = area.expand(Vector2(float(q[0]), float(q[1])))
	area = area.grow(20.0)
	var mapa := Rect2(Vector2(12, 30), Vector2(300, size.y - 42))
	var escala := minf(mapa.size.x / maxf(area.size.x, 1.0), mapa.size.y / maxf(area.size.y, 1.0))
	var folga := (mapa.size - area.size * escala) / 2.0
	var para_tela := func(p: Vector2) -> Vector2:
		return mapa.position + folga + (p - area.position) * escala
	draw_rect(mapa, Color(0.2, 0.22, 0.2))
	# A cidade de verdade (como no minimapa): prédios e ruas dos bairros carregados.
	for id in cena.carregados:
		var bairro: Node3D = cena.carregados[id]
		for lote in bairro.lotes:
			if lote["tipo"] == Lotes.TIPO_PREDIO:
				var cantos := PackedVector2Array()
				for q in Lotes.cantos(lote):
					cantos.append(para_tela.call(q))
				draw_colored_polygon(cantos, Color(0.4, 0.43, 0.48))
		for rua in bairro.dados["ruas"]:
			var linha := PackedVector2Array()
			for q in Lotes._pontos(rua["pontos"]):
				linha.append(para_tela.call(q))
			var caminho: bool = rua["tipo"] in ["steps", "footway", "pedestrian"]
			draw_polyline(linha, Color(0.6, 0.5, 0.4) if caminho else Color(0.78, 0.78, 0.74), maxf(1.0, float(rua["largura"]) * escala))
	# Contorno dos bairros carregados.
	for id in cena.carregados:
		var limite: Array = cena.carregados[id].dados["limite"]
		var linha := PackedVector2Array()
		for q in limite:
			linha.append(para_tela.call(Vector2(float(q[0]), float(q[1]))))
		if linha.size() > 1:
			linha.append(linha[0])
			draw_polyline(linha, Color(0.95, 0.85, 0.45), 1.5)
	_pontos_na_tela.clear()
	for i in destinos.size():
		var d: Dictionary = destinos[i]
		var p: Vector2 = para_tela.call(d["ponto"])
		_pontos_na_tela.append(p)
		var cabe: bool = float(d["litros"]) <= cena.carro.litros
		draw_circle(p, 7.0, Color(0.9, 0.75, 0.3) if cabe else Color(0.5, 0.3, 0.3))
		var tecla := str(i + 1) if i < 9 else ("0" if i == 9 else "·")
		draw_string(fonte, p + Vector2(-3, 4), tecla, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.1, 0.08, 0.05))
		var y := 40.0 + i * 21.0
		draw_string(fonte, Vector2(326, y), "%s) %s" % [tecla, d["nome"]], HORIZONTAL_ALIGNMENT_LEFT, size.x - 336, 11, Color(0.95, 0.92, 0.85) if cabe else Color(0.6, 0.5, 0.5))
		draw_string(fonte, Vector2(344, y + 10), "%d min · %.1f L%s" % [int(d["minutos"]), float(d["litros"]), "" if cabe else " · falta gasolina"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.7, 0.7, 0.65))
	var c: Vector2 = para_tela.call(carro)
	draw_circle(c, 5.0, Color(0.85, 0.2, 0.15))
	draw_string(fonte, c + Vector2(7, 4), "carro", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.5, 0.45))
