extends Node3D
## Um bairro do mapa real em 3D cinza (docs/07, "Como um bairro é montado"):
##   terreno com o relevo importado (com colisão), ruas e calçadas que acompanham o chão,
##   prédios nos lotes gerados (core/cidade/lotes.gd), mata nos morros, marcos e saídas.
## Os dados vêm de game/data/cidade/<id>.json; o sorteio, do rng do mundo (mesma semente,
## mesmo bairro).

const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Terreno := preload("res://core/cidade/terreno.gd")
const Lotes := preload("res://core/cidade/lotes.gd")
const Materiais := preload("res://presentation/ps1/materiais.gd")
const Blocos := preload("res://presentation/greybox/blocos.gd")

const ALTURA_ANDAR := 3.0
const PASSO_DAS_RUAS := 2.0
const ACIMA_DO_CHAO_RUA := 0.08
const ACIMA_DO_CHAO_CALCADA := 0.05
const DISTANCIA_ENTRE_ARVORES := 3.0
const CORES_PREDIOS := [Color(0.62, 0.58, 0.5), Color(0.5, 0.55, 0.58), Color(0.66, 0.52, 0.45),
	Color(0.55, 0.6, 0.5), Color(0.48, 0.48, 0.52), Color(0.64, 0.6, 0.42), Color(0.7, 0.66, 0.6)]
const COR_TERRENO := Color(0.32, 0.36, 0.26)
const COR_RUA := Color(0.22, 0.22, 0.24)
const COR_CALCADA := Color(0.5, 0.49, 0.46)
const COR_ESCADA := Color(0.45, 0.4, 0.34)
## Chão grande e inclinado entorta demais com a textura afim do PS1: no chão, só um pouco.
const AFIM_DO_CHAO := 0.25

var dados: Dictionary = {}
var terreno: RefCounted
var lotes: Array[Dictionary] = []
var predios: Array[StaticBody3D] = []
var arvores: MultiMeshInstance3D
var saidas: Array[Dictionary] = []
var chao: StaticBody3D
## Para onde o caçador olha ao chegar (o sentido da rua da chegada).
var giro_chegada: float = 0.0


## Monta o bairro. Pode ser chamado sem estar na árvore (testes).
func montar(id_bairro: String, semente: int) -> void:
	name = "Bairro_" + id_bairro
	dados = Catalogo.carregar_bairro_real(id_bairro)["dados"]
	terreno = Terreno.new(dados["relevo"])
	var rng := Rng.new(semente)
	var cfg: Dictionary = Catalogo.carregar_config_lotes()["dados"]
	lotes = Lotes.gerar(dados, cfg, rng)
	_montar_terreno()
	for rua in dados["ruas"]:
		_montar_rua(rua, float(cfg["calcada"]))
	for lote in lotes:
		_montar_lote(lote)
	_montar_mata(rng.stream("mata:%s" % id_bairro), cfg)
	for marco in dados["marcos"]:
		_montar_marco(marco)
	for s in dados["saidas"]:
		var p := Vector2(float(s["posicao"][0]), float(s["posicao"][1]))
		var ponto := Vector3(p.x, terreno.altura(p.x, p.y), p.y)
		saidas.append({"rua": s["rua"], "para": s["para"], "ponto": ponto})
		Blocos.bloco(self, Vector3(0.2, 2.5, 0.2), ponto + Vector3(0, 1.25, 0), Color(0.85, 0.7, 0.3), 1.0, false)


## Onde o caçador começa: no meio do trecho de rua comum mais baixo do bairro (no plano,
## não no meio de uma ladeira). Guarda em giro_chegada o sentido da rua.
func chegada() -> Vector3:
	var melhor_ponto := Vector2.ZERO
	var melhor_direcao := Vector2.UP
	var mais_baixo := INF
	# Primeiro só ruas comuns com trechos de pelo menos 4 m; se o bairro não tiver
	# (morro só de escadarias), qualquer caminho serve.
	for exigente in [true, false]:
		if mais_baixo < INF:
			break
		for rua in dados["ruas"]:
			if exigente and rua["tipo"] in ["steps", "footway", "pedestrian"]:
				continue
			for i in rua["pontos"].size() - 1:
				var a := _v2(rua["pontos"][i])
				var b := _v2(rua["pontos"][i + 1])
				if exigente and a.distance_to(b) < 4.0:
					continue
				var meio := (a + b) / 2.0
				var h: float = terreno.altura(meio.x, meio.y)
				if h < mais_baixo:
					mais_baixo = h
					melhor_ponto = meio
					melhor_direcao = (b - a).normalized()
	giro_chegada = atan2(-melhor_direcao.x, -melhor_direcao.y)
	return Vector3(melhor_ponto.x, mais_baixo + 0.3, melhor_ponto.y)


func _montar_terreno() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var t: RefCounted = terreno
	for j in t.linhas - 1:
		for i in t.colunas - 1:
			var a: Vector3 = t.vertice(i, j)
			var b: Vector3 = t.vertice(i + 1, j)
			var c: Vector3 = t.vertice(i + 1, j + 1)
			var d: Vector3 = t.vertice(i, j + 1)
			for v in [a, b, c, a, c, d]:
				st.set_uv(Vector2(v.x, v.z) / 8.0)
				st.add_vertex(v)
	st.generate_normals()
	var malha := st.commit()
	var visual := MeshInstance3D.new()
	visual.name = "Terreno"
	visual.mesh = malha
	visual.material_override = Materiais.objeto(COR_TERRENO, 1.0, AFIM_DO_CHAO)
	chao = StaticBody3D.new()
	chao.name = "Chao"
	var forma := CollisionShape3D.new()
	forma.shape = malha.create_trimesh_shape()
	chao.add_child(forma)
	chao.add_child(visual)
	add_child(chao)


## Faixa que acompanha o chão: a linha é cortada em pedaços de PASSO_DAS_RUAS.
func _faixa(pontos: Array, largura: float, acima: float, cor: Color, nome: String) -> void:
	var linha: Array[Vector2] = []
	for i in pontos.size() - 1:
		var a := _v2(pontos[i])
		var b := _v2(pontos[i + 1])
		var partes := maxi(1, int(ceil(a.distance_to(b) / PASSO_DAS_RUAS)))
		for k in partes:
			linha.append(a.lerp(b, float(k) / partes))
	linha.append(_v2(pontos[-1]))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var meia := largura / 2.0
	for i in linha.size() - 1:
		var a: Vector2 = linha[i]
		var b: Vector2 = linha[i + 1]
		var lado := (b - a).normalized().orthogonal() * meia
		var cantos := [a + lado, a - lado, b - lado, b + lado]
		var v3: Array[Vector3] = []
		for c in cantos:
			v3.append(Vector3(c.x, terreno.altura(c.x, c.y) + acima, c.y))
		# Mesma volta dos triângulos do terreno: a face fica para cima.
		for idx in [0, 2, 1, 0, 3, 2]:
			st.set_uv(Vector2(v3[idx].x, v3[idx].z) / 4.0)
			st.add_vertex(v3[idx])
	st.generate_normals()
	var visual := MeshInstance3D.new()
	visual.name = nome
	visual.mesh = st.commit()
	visual.material_override = Materiais.objeto(cor, 1.0, AFIM_DO_CHAO)
	add_child(visual)


func _montar_rua(rua: Dictionary, calcada: float) -> void:
	var largura: float = rua["largura"]
	if rua["tipo"] in ["steps", "footway", "pedestrian"]:
		_faixa(rua["pontos"], largura, ACIMA_DO_CHAO_RUA, COR_ESCADA, "Caminho_%d" % int(rua["osm"]))
		return
	_faixa(rua["pontos"], largura + calcada * 2.0, ACIMA_DO_CHAO_CALCADA, COR_CALCADA, "Calcada_%d" % int(rua["osm"]))
	_faixa(rua["pontos"], largura, ACIMA_DO_CHAO_RUA, COR_RUA, "Rua_%d" % int(rua["osm"]))


func _montar_lote(lote: Dictionary) -> void:
	if lote["tipo"] != Lotes.TIPO_PREDIO:
		return
	var cantos := Lotes.cantos(lote)
	var mais_baixo := INF
	var mais_alto := -INF
	for c in cantos:
		var h: float = terreno.altura(c.x, c.y)
		mais_baixo = minf(mais_baixo, h)
		mais_alto = maxf(mais_alto, h)
	# O prédio afunda no lado mais baixo, para não ficar flutuando na ladeira.
	var base := mais_baixo - 0.5
	var altura: float = int(lote["andares"]) * ALTURA_ANDAR + (mais_alto - base)
	var centro: Vector2 = lote["centro"]
	var cor: Color = CORES_PREDIOS[int(lote["id"]) % CORES_PREDIOS.size()]
	var corpo: Node3D = Blocos.bloco(self, Vector3(lote["frente"], altura, lote["fundo"]),
		Vector3(centro.x, base + altura / 2.0, centro.y), cor, 2.0)
	corpo.name = "Predio_%d" % int(lote["id"])
	corpo.rotation.y = float(lote["giro"])
	predios.append(corpo)


## Árvores (cones baixos, uma malha só) nos lotes de mata e no que sobra do morro.
func _montar_mata(gerador: RandomNumberGenerator, cfg: Dictionary) -> void:
	var pontos: Array[Vector3] = []
	for lote in lotes:
		if lote["tipo"] == Lotes.TIPO_MATA:
			var c: Vector2 = lote["centro"]
			pontos.append(Vector3(c.x, terreno.altura(c.x, c.y), c.y))
	if dados["zona"] == "morros":
		var limite := Lotes._pontos(dados["limite"])
		var caixa: Array = dados["caixa"]
		var x := float(caixa[0])
		while x <= float(caixa[2]):
			var z := float(caixa[1])
			while z <= float(caixa[3]):
				var p := Vector2(x + gerador.randf_range(-1.0, 1.0), z + gerador.randf_range(-1.0, 1.0))
				if Geometry2D.is_point_in_polygon(p, limite) and _livre_para_arvore(p, float(cfg["calcada"])):
					pontos.append(Vector3(p.x, terreno.altura(p.x, p.y), p.y))
				z += DISTANCIA_ENTRE_ARVORES
			x += DISTANCIA_ENTRE_ARVORES
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.3
	cone.height = 4.0
	cone.radial_segments = 5
	cone.rings = 1
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = cone
	multi.instance_count = pontos.size()
	for i in pontos.size():
		var escala := gerador.randf_range(0.7, 1.4)
		var base := Basis().scaled(Vector3(escala, escala, escala))
		multi.set_instance_transform(i, Transform3D(base, pontos[i] + Vector3(0, 2.0 * escala - 0.3, 0)))
	arvores = MultiMeshInstance3D.new()
	arvores.name = "Mata"
	arvores.multimesh = multi
	arvores.material_override = Materiais.objeto(Color(0.18, 0.3, 0.16), 1.0)
	add_child(arvores)


func _livre_para_arvore(p: Vector2, calcada: float) -> bool:
	for rua in dados["ruas"]:
		var folga: float = float(rua["largura"]) / 2.0 + calcada
		for i in rua["pontos"].size() - 1:
			var perto := Geometry2D.get_closest_point_to_segment(p, _v2(rua["pontos"][i]), _v2(rua["pontos"][i + 1]))
			if p.distance_to(perto) < folga:
				return false
	for lote in lotes:
		if Vector2(lote["centro"]).distance_to(p) < (float(lote["frente"]) + float(lote["fundo"])) / 2.0:
			return false
	return true


func _montar_marco(marco: Dictionary) -> void:
	var p := _v2(marco["posicao"])
	var chao_aqui: float = terreno.altura(p.x, p.y)
	match marco["tipo"]:
		"natural=peak":
			# A capela no topo do morro (Igreja do Monte Serrat) e uma cruz.
			Blocos.bloco(self, Vector3(6, 5, 9), Vector3(p.x, chao_aqui + 2.0, p.y), Color(0.85, 0.82, 0.74), 2.0)
			Blocos.bloco(self, Vector3(0.3, 3, 0.3), Vector3(p.x, chao_aqui + 6.0, p.y - 3.0), Color(0.9, 0.9, 0.9), 1.0, false)
		"railway=funicular":
			if marco.has("pontos"):
				_faixa(marco["pontos"], 1.6, 0.15, Color(0.3, 0.25, 0.2), "Bondinho")
		_:
			Blocos.bloco(self, Vector3(1.2, 2.4, 1.2), Vector3(p.x, chao_aqui + 1.2, p.y), Color(0.75, 0.68, 0.55), 1.0)


static func _v2(p: Array) -> Vector2:
	return Vector2(float(p[0]), float(p[1]))
