extends RefCounted
## Gerador de lotes de um bairro do mapa real (docs/07, "Como um bairro é montado", passo 2).
## Anda por cada rua e põe lotes dos dois lados, de frente para ela, com medidas do kit da
## zona (game/data/config/lotes.json). Um lote só fica se estiver todo dentro do bairro,
## longe das ruas (pista + calçada) e sem encostar em outro lote. O sorteio vem do rng do
## mundo (stream "lotes:<bairro>"): mesma semente, mesmos lotes.
##
## Lote: {"id", "centro": Vector2 (x, z), "giro" (rotação em y), "frente", "fundo",
##        "tipo": "predio" | "vazio" | "mata", "andares", "rua": osm da rua da frente}

const TIPO_PREDIO := "predio"
const TIPO_VAZIO := "vazio"
const TIPO_MATA := "mata"


static func gerar(bairro: Dictionary, config: Dictionary, rng: RefCounted) -> Array[Dictionary]:
	var gerador: RandomNumberGenerator = rng.stream("lotes:%s" % bairro["id"])
	var kit: Dictionary = config["zonas"].get(bairro["zona"], config["zonas"]["padrao"])
	var limite := _pontos(bairro["limite"])
	var ruas: Array = bairro["ruas"]
	var sem_lotes: Array = kit.get("sem_lotes", config["sem_lotes"])
	var lotes: Array[Dictionary] = []
	for rua in ruas:
		if rua["tipo"] in sem_lotes:
			continue
		var pontos := _pontos(rua["pontos"])
		var recuo_total: float = float(rua["largura"]) / 2.0 + float(config["calcada"]) + float(config["recuo"])
		for s in pontos.size() - 1:
			var a := pontos[s]
			var b := pontos[s + 1]
			var comprimento := a.distance_to(b)
			if comprimento < 0.01:
				continue
			var u := (b - a) / comprimento
			var v := Vector2(-u.y, u.x)
			for lado in [-1.0, 1.0]:
				var t := gerador.randf_range(0.0, float(config["espaco_entre_lotes"]) * 2.0)
				while true:
					var frente := gerador.randf_range(kit["frente"][0], kit["frente"][1])
					var fundo := gerador.randf_range(kit["fundo"][0], kit["fundo"][1])
					if t + frente > comprimento:
						break
					var centro: Vector2 = a + u * (t + frente / 2.0) + v * lado * (recuo_total + fundo / 2.0)
					var lote := {"centro": centro, "eixo": u, "frente": frente, "fundo": fundo}
					if _cabe(lote, limite, ruas, lotes, config, sem_lotes):
						lote["id"] = lotes.size()
						lote["giro"] = atan2(-u.y, u.x)
						lote["rua"] = rua["osm"]
						var sorteio := gerador.randf()
						if sorteio < float(kit["chance_mata"]):
							lote["tipo"] = TIPO_MATA
						elif sorteio < float(kit["chance_mata"]) + float(kit["chance_vazio"]):
							lote["tipo"] = TIPO_VAZIO
						else:
							lote["tipo"] = TIPO_PREDIO
						lote["andares"] = gerador.randi_range(int(kit["andares"][0]), int(kit["andares"][1]))
						lotes.append(lote)
					t += frente + float(config["espaco_entre_lotes"])
	return lotes


## Os 4 cantos do lote, em ordem.
static func cantos(lote: Dictionary) -> PackedVector2Array:
	var u: Vector2 = lote["eixo"]
	var v := Vector2(-u.y, u.x)
	var c: Vector2 = lote["centro"]
	var hf: float = float(lote["frente"]) / 2.0
	var hd: float = float(lote["fundo"]) / 2.0
	return PackedVector2Array([c - u * hf - v * hd, c + u * hf - v * hd, c + u * hf + v * hd, c - u * hf + v * hd])


static func _cabe(lote: Dictionary, limite: PackedVector2Array, ruas: Array, outros: Array[Dictionary], config: Dictionary, sem_lotes: Array) -> bool:
	var meus := cantos(lote)
	for p in meus:
		if not Geometry2D.is_point_in_polygon(p, limite):
			return false
	for rua in ruas:
		# Rua comum: pista + calçada (o lote é posto um pouco além, pelo recuo).
		# Escadaria, trilha e afins não têm calçada: só uma folga para passar.
		var folga: float = float(rua["largura"]) / 2.0 + float(config["calcada"]) - 0.01
		if rua["tipo"] in sem_lotes:
			folga = float(rua["largura"]) / 2.0 + float(config["folga_das_ruas"])
		var pontos := _pontos(rua["pontos"])
		for s in pontos.size() - 1:
			if distancia_segmento_poligono(pontos[s], pontos[s + 1], meus) < folga:
				return false
	var espaco: float = float(config["espaco_entre_lotes"]) / 2.0
	for outro in outros:
		if Vector2(lote["centro"]).distance_to(outro["centro"]) > float(lote["frente"]) + float(lote["fundo"]) + float(outro["frente"]) + float(outro["fundo"]):
			continue
		if Geometry2D.intersect_polygons(_inflar(meus, espaco), _inflar(cantos(outro), espaco)).size() > 0:
			return false
	return true


## Menor distância entre o segmento a-b e um polígono convexo (0 se encostam ou cruzam).
static func distancia_segmento_poligono(a: Vector2, b: Vector2, poligono: PackedVector2Array) -> float:
	if Geometry2D.is_point_in_polygon(a, poligono) or Geometry2D.is_point_in_polygon(b, poligono):
		return 0.0
	var menor := INF
	var n := poligono.size()
	for i in n:
		var c := poligono[i]
		var d := poligono[(i + 1) % n]
		if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
			return 0.0
		menor = minf(menor, c.distance_to(Geometry2D.get_closest_point_to_segment(c, a, b)))
		menor = minf(menor, a.distance_to(Geometry2D.get_closest_point_to_segment(a, c, d)))
		menor = minf(menor, b.distance_to(Geometry2D.get_closest_point_to_segment(b, c, d)))
	return menor


static func _inflar(poligono: PackedVector2Array, quanto: float) -> PackedVector2Array:
	if quanto <= 0.0:
		return poligono
	var crescido := Geometry2D.offset_polygon(poligono, quanto)
	return crescido[0] if crescido.size() > 0 else poligono


static func _pontos(lista: Array) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	for p in lista:
		pontos.append(Vector2(float(p[0]), float(p[1])))
	return pontos
