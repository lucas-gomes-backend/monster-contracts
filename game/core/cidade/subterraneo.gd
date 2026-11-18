extends RefCounted
## Subterrâneo dos bairros do mapa real (docs/07, "Esgotos e subterrâneo"): galerias que
## seguem as ruas comuns, juntas num traçado só, e bueiros ao longo delas. Vários bairros
## vizinhos podem formar uma rede só (gerar_rede): o esgoto liga um ao outro por baixo.
##
## Cada trecho de rua vira um corredor (retângulo da largura da galeria, com as pontas
## estendidas para cobrir as curvas). As paredes são as bordas dos corredores menos o que
## fica dentro de outro corredor: assim cruzamentos e curvas ficam abertos e só o contorno
## de fora vira parede. Os bueiros são sorteados pelo rng do mundo (stream
## "subterraneo:<bairro>"), a cada distancia_entre_bueiros metros de galeria.
##
## {"corredores": [PackedVector2Array], "paredes": [PackedVector2Array], "bueiros": [Vector2]}


static func gerar(bairro: Dictionary, cfg: Dictionary, rng: RefCounted) -> Dictionary:
	return gerar_rede([bairro], cfg, rng)


## Uma rede só para vários bairros vizinhos: as galerias das ruas que cruzam a divisa
## continuam do outro lado, sem parede no meio (o esgoto liga os bairros por baixo).
## Os bueiros de cada bairro vêm do stream dele, então não mudam com os vizinhos.
## Além das chaves acima: "corredores_de" e "bueiros_de" (o bairro de cada um).
static func gerar_rede(bairros: Array, cfg: Dictionary, rng: RefCounted) -> Dictionary:
	var meia: float = float(cfg["largura"]) / 2.0
	var corredores: Array[PackedVector2Array] = []
	var corredores_de: Array[String] = []
	var eixos_por_bairro := {}  # id -> [[a, b], ...], para os bueiros
	for bairro in bairros:
		var eixos: Array = []
		for rua in bairro["ruas"]:
			if rua["tipo"] in cfg["ruas_sem_galeria"]:
				continue
			var p := _pontos(rua["pontos"])
			for i in p.size() - 1:
				if p[i].distance_to(p[i + 1]) < 0.05:
					continue
				corredores.append(retangulo(p[i], p[i + 1], meia))
				corredores_de.append(str(bairro["id"]))
				eixos.append([p[i], p[i + 1]])
		eixos_por_bairro[bairro["id"]] = eixos

	var caixas: Array[Rect2] = []
	for c in corredores:
		caixas.append(_caixa(c))
	var paredes: Array[PackedVector2Array] = []
	for i in corredores.size():
		var c := corredores[i]
		for k in 4:
			var pedacos: Array = [PackedVector2Array([c[k], c[(k + 1) % 4]])]
			var caixa_aresta := _caixa(pedacos[0]).grow(0.01)
			for j in corredores.size():
				if j == i or not caixas[j].intersects(caixa_aresta):
					continue
				var sobra: Array = []
				for pedaco in pedacos:
					sobra.append_array(Geometry2D.clip_polyline_with_polygon(pedaco, corredores[j]))
				pedacos = sobra
				if pedacos.is_empty():
					break
			for pedaco in pedacos:
				if pedaco.size() >= 2 and pedaco[0].distance_to(pedaco[-1]) > 0.05 and _separa(pedaco, corredores):
					paredes.append(pedaco)

	var bueiros: Array[Vector2] = []
	var bueiros_de: Array[String] = []
	for bairro in bairros:
		for ponto in _bueiros(bairro, eixos_por_bairro[bairro["id"]], cfg, rng):
			bueiros.append(ponto)
			bueiros_de.append(str(bairro["id"]))
	return {"corredores": corredores, "corredores_de": corredores_de, "paredes": paredes,
		"bueiros": bueiros, "bueiros_de": bueiros_de}


static func _bueiros(bairro: Dictionary, eixos: Array, cfg: Dictionary, rng: RefCounted) -> Array[Vector2]:
	var gerador: RandomNumberGenerator = rng.stream("subterraneo:%s" % bairro["id"])
	var limite := _pontos(bairro["limite"])
	var bueiros: Array[Vector2] = []
	var minimo: float = cfg["distancia_entre_bueiros"][0]
	var maximo: float = cfg["distancia_entre_bueiros"][1]
	var falta := gerador.randf_range(minimo, maximo) / 2.0
	for eixo in eixos:
		var a: Vector2 = eixo[0]
		var b: Vector2 = eixo[1]
		var andado := 0.0
		var comprimento := a.distance_to(b)
		while andado + falta <= comprimento:
			andado += falta
			var ponto := a.lerp(b, andado / comprimento)
			if Geometry2D.is_point_in_polygon(ponto, limite):
				bueiros.append(ponto)
			falta = gerador.randf_range(minimo, maximo)
		falta -= comprimento - andado
	# Todo bairro com galeria tem pelo menos um jeito de descer.
	if bueiros.is_empty() and not eixos.is_empty():
		for eixo in eixos:
			var meio: Vector2 = (eixo[0] + eixo[1]) / 2.0
			if Geometry2D.is_point_in_polygon(meio, limite):
				bueiros.append(meio)
				break
	return bueiros


## Corredores ligados entre si (se sobrepõem): grupos de índices. Serve para conferir se
## dá para ir de um bairro a outro por baixo da terra.
static func grupos_ligados(corredores: Array) -> Array:
	var n := corredores.size()
	var grupo := []
	grupo.resize(n)
	grupo.fill(-1)
	var caixas: Array[Rect2] = []
	for c in corredores:
		caixas.append(_caixa(c).grow(0.01))
	var grupos: Array = []
	for inicio in n:
		if grupo[inicio] >= 0:
			continue
		var atual: Array = [inicio]
		grupo[inicio] = grupos.size()
		var fila: Array = [inicio]
		while not fila.is_empty():
			var i: int = fila.pop_back()
			for j in n:
				if grupo[j] >= 0 or not caixas[i].intersects(caixas[j]):
					continue
				if Geometry2D.intersect_polygons(corredores[i], corredores[j]).size() > 0:
					grupo[j] = grupos.size()
					atual.append(j)
					fila.append(j)
		grupos.append(atual)
	return grupos


## Retângulo de largura 2*meia em volta do segmento a-b, com as pontas estendidas em meia.
static func retangulo(a: Vector2, b: Vector2, meia: float) -> PackedVector2Array:
	var u := (b - a).normalized()
	var v := Vector2(-u.y, u.x) * meia
	var a2 := a - u * meia
	var b2 := b + u * meia
	return PackedVector2Array([a2 - v, b2 - v, b2 + v, a2 + v])


## O ponto está dentro de algum corredor?
static func dentro_da_galeria(ponto: Vector2, corredores: Array) -> bool:
	for c in corredores:
		if Geometry2D.is_point_in_polygon(ponto, c):
			return true
	return false


## Parede de verdade: galeria de um lado e terra do outro. O recorte deixa às vezes
## sobras de centímetros (arredondamento) com galeria dos dois lados; essas saem.
static func _separa(pedaco: PackedVector2Array, corredores: Array) -> bool:
	var a := pedaco[0]
	var b := pedaco[-1]
	var meio := (a + b) / 2.0
	var normal := (b - a).normalized().orthogonal() * 0.05
	return dentro_da_galeria(meio + normal, corredores) != dentro_da_galeria(meio - normal, corredores)


static func _caixa(pontos: PackedVector2Array) -> Rect2:
	var caixa := Rect2(pontos[0], Vector2.ZERO)
	for p in pontos:
		caixa = caixa.expand(p)
	return caixa


static func _pontos(lista: Array) -> PackedVector2Array:
	var pontos := PackedVector2Array()
	for p in lista:
		pontos.append(Vector2(float(p[0]), float(p[1])))
	return pontos
