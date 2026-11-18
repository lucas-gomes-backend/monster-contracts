extends Control
## Mapa de viagem rápida (só dentro do carro): os pontos dos bairros carregados num mapa
## simples, com o número, o tempo e a gasolina de cada viagem. Número ou clique no ponto viaja.
## O mapa é desenhado num quadro que recorta o que passa da borda (no zoom perto, as regiões
## de fora vazavam por cima da lista de destinos).

const Lotes := preload("res://core/cidade/lotes.gd")

var cena: Node  # bairro_cena: destinos_de_viagem(), viajar(), carro, carregados
var _pontos_na_tela: Array = []  # em coordenadas desta tela
## Perto: enquadra as regiões liberadas; longe: a cidade inteira. Roda do mouse ou Z troca.
var perto := false
var _regioes_na_tela: Array = []  # [{"id", "nome", "poligono"}] em coordenadas do quadro
var quadro: Control


func _ready() -> void:
	quadro = Control.new()
	quadro.name = "Quadro"
	quadro.clip_contents = true
	quadro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(quadro)
	quadro.draw.connect(_desenhar_mapa)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()
		quadro.queue_redraw()


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		perto = evento.button_index == MOUSE_BUTTON_WHEEL_UP
		accept_event()
	elif evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		if not quadro.get_rect().has_point(evento.position):
			return
		for i in _pontos_na_tela.size():
			if evento.position.distance_to(_pontos_na_tela[i]) <= 10.0:
				cena.viajar(i)
				accept_event()
				return
		var no_quadro: Vector2 = evento.position - quadro.position
		for r in _regioes_na_tela:
			if not cena.progresso.liberada(r["id"]) and Geometry2D.is_point_in_polygon(no_quadro, r["poligono"]):
				cena._avisar("%s: região bloqueada." % r["nome"])
				accept_event()
				return


## A área que o mapa mostra (perto: as regiões liberadas; longe: a cidade toda), o quadro
## na tela e a escala.
func enquadrar() -> Dictionary:
	var destinos: Array = cena.destinos_de_viagem()
	var carro := Vector2(cena.carro.position.x, cena.carro.position.z)
	var area := Rect2(carro, Vector2.ZERO)
	for d in destinos:
		area = area.expand(d["ponto"])
	for r in cena.mapa_geral:
		if perto and not cena.progresso.liberada(r["id"]):
			continue
		for q in r["limite"]:
			area = area.expand(Vector2(float(q[0]), float(q[1])))
	area = area.grow(20.0)
	var mapa := Rect2(Vector2(12, 30), Vector2(340, maxf(size.y - 42, 1.0)))
	var escala := minf(mapa.size.x / maxf(area.size.x, 1.0), mapa.size.y / maxf(area.size.y, 1.0))
	return {"destinos": destinos, "carro": carro, "area": area, "mapa": mapa, "escala": escala,
		"folga": (mapa.size - area.size * escala) / 2.0}


## Põe o quadro no retângulo do mapa (muda com o tamanho da tela). Devolve o enquadramento.
func ajustar_quadro() -> Dictionary:
	var e := enquadrar()
	quadro.position = e["mapa"].position
	quadro.size = e["mapa"].size
	return e


## Cabeçalho e lista de destinos (fora do quadro do mapa).
func _draw() -> void:
	if cena == null or cena.carro == null:
		return
	var fonte := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.08, 0.92))
	draw_string(fonte, Vector2(12, 18), "MAPA DE VIAGEM · gasolina: %.1f L · número ou clique para ir · roda/Z: %s · M fecha" % [cena.carro.litros, "cidade inteira" if perto else "aproximar"], HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 11, Color(0.95, 0.9, 0.75))
	var destinos: Array = ajustar_quadro()["destinos"]
	for i in destinos.size():
		var d: Dictionary = destinos[i]
		var cabe: bool = float(d["litros"]) <= cena.carro.litros
		var tecla := str(i + 1) if i < 9 else ("0" if i == 9 else "·")
		var y := 40.0 + i * 21.0
		draw_string(fonte, Vector2(364, y), "%s) %s" % [tecla, d["nome"]], HORIZONTAL_ALIGNMENT_LEFT, size.x - 374, 11, Color(0.95, 0.92, 0.85) if cabe else Color(0.6, 0.5, 0.5))
		draw_string(fonte, Vector2(380, y + 10), "%d min · %.1f L%s" % [int(d["minutos"]), float(d["litros"]), "" if cabe else " · falta gasolina"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.7, 0.7, 0.65))


## O mapa, desenhado no quadro (coordenadas do quadro; o que passa da borda é cortado).
func _desenhar_mapa() -> void:
	if cena == null or cena.carro == null:
		return
	var q_ := quadro
	var fonte := ThemeDB.fallback_font
	var e := enquadrar()
	var destinos: Array = e["destinos"]
	var area: Rect2 = e["area"]
	var escala: float = e["escala"]
	var folga: Vector2 = e["folga"]
	var mapa := Rect2(Vector2.ZERO, e["mapa"].size)
	var para_tela := func(p: Vector2) -> Vector2:
		return folga + (p - area.position) * escala
	q_.draw_rect(mapa, Color(0.13, 0.17, 0.2))
	# Todas as regiões: as bloqueadas em cinza, com o nome; as liberadas com fundo claro.
	_regioes_na_tela.clear()
	for r in cena.mapa_geral:
		var poligono := PackedVector2Array()
		for q in r["limite"]:
			poligono.append(para_tela.call(Vector2(float(q[0]), float(q[1]))))
		var liberada: bool = cena.progresso.liberada(r["id"])
		if not Geometry2D.triangulate_polygon(poligono).is_empty():
			q_.draw_colored_polygon(poligono, Color(0.24, 0.26, 0.24) if liberada else Color(0.36, 0.36, 0.36))
		var anel := poligono.duplicate()
		anel.append(poligono[0])
		q_.draw_polyline(anel, Color(0.55, 0.55, 0.55) if not liberada else Color(0.45, 0.5, 0.42), 1.0)
		_regioes_na_tela.append({"id": r["id"], "nome": r["nome"], "poligono": poligono})
	for r in _regioes_na_tela:
		if cena.progresso.liberada(r["id"]):
			continue
		var meio := Vector2.ZERO
		for q in r["poligono"]:
			meio += q
		meio /= maxf(r["poligono"].size(), 1)
		var w := fonte.get_string_size(r["nome"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		if mapa.has_point(meio):
			q_.draw_string(fonte, meio - Vector2(w / 2.0, -3), r["nome"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.75, 0.75, 0.75))
	# A cidade de verdade (como no minimapa): prédios e ruas dos bairros carregados.
	for id in cena.carregados:
		if not cena.progresso.liberada(id):
			continue
		var bairro: Node3D = cena.carregados[id]
		for lote in bairro.lotes:
			if lote["tipo"] == Lotes.TIPO_PREDIO:
				var cantos := PackedVector2Array()
				for q in Lotes.cantos(lote):
					cantos.append(para_tela.call(q))
				q_.draw_colored_polygon(cantos, Color(0.4, 0.43, 0.48))
		for rua in bairro.dados["ruas"]:
			var linha := PackedVector2Array()
			for q in Lotes._pontos(rua["pontos"]):
				linha.append(para_tela.call(q))
			var caminho: bool = rua["tipo"] in ["steps", "footway", "pedestrian"]
			q_.draw_polyline(linha, Color(0.6, 0.5, 0.4) if caminho else Color(0.78, 0.78, 0.74), maxf(1.0, float(rua["largura"]) * escala))
	# Contorno dos bairros liberados e carregados.
	for id in cena.carregados:
		if not cena.progresso.liberada(id):
			continue
		var limite: Array = cena.carregados[id].dados["limite"]
		var linha := PackedVector2Array()
		for q in limite:
			linha.append(para_tela.call(Vector2(float(q[0]), float(q[1]))))
		if linha.size() > 1:
			linha.append(linha[0])
			q_.draw_polyline(linha, Color(0.95, 0.85, 0.45), 1.5)
	_pontos_na_tela.clear()
	for i in destinos.size():
		var d: Dictionary = destinos[i]
		var p: Vector2 = para_tela.call(d["ponto"])
		_pontos_na_tela.append(p + quadro.position)
		var cabe: bool = float(d["litros"]) <= cena.carro.litros
		q_.draw_circle(p, 7.0, Color(0.9, 0.75, 0.3) if cabe else Color(0.5, 0.3, 0.3))
		var tecla := str(i + 1) if i < 9 else ("0" if i == 9 else "·")
		q_.draw_string(fonte, p + Vector2(-3, 4), tecla, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.1, 0.08, 0.05))
	var c: Vector2 = para_tela.call(e["carro"])
	q_.draw_circle(c, 5.0, Color(0.85, 0.2, 0.15))
	q_.draw_string(fonte, c + Vector2(7, 4), "carro", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.5, 0.45))
