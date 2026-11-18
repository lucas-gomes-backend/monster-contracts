extends Node3D
## Um bairro do mapa real em 3D cinza (docs/07, "Como um bairro é montado"):
##   chão plano (decisão: a cidade é plana, o clima vem da névoa), ruas e calçadas,
##   prédios nos lotes gerados (core/cidade/lotes.gd), mata nos morros, marcos e saídas,
##   e o subterrâneo embaixo das ruas (core/cidade/subterraneo.gd), com bueiros.
## Os dados vêm de game/data/cidade/<id>.json; o sorteio, do rng do mundo (mesma semente,
## mesmo bairro).

const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Lotes := preload("res://core/cidade/lotes.gd")
const Sub := preload("res://core/cidade/subterraneo.gd")
const Materiais := preload("res://presentation/ps1/materiais.gd")
const Blocos := preload("res://presentation/greybox/blocos.gd")

const ALTURA_ANDAR := 3.0
## Rua, calçada e chão em alturas bem separadas: com poucos centímetros, de longe a placa
## de vídeo não decide qual fica na frente e o chão pisca.
const ACIMA_DO_CHAO_RUA := 0.1
const ACIMA_DO_CHAO_CALCADA := 0.05
const MARGEM_DO_CHAO := 20.0
## A chegada fica pelo menos isto longe da borda do bairro.
const LONGE_DA_BORDA := 6.0
const DISTANCIA_ENTRE_ARVORES := 3.0
const CAMINHOS := ["steps", "footway", "pedestrian"]
const CORES_PREDIOS := [Color(0.62, 0.58, 0.5), Color(0.5, 0.55, 0.58), Color(0.66, 0.52, 0.45),
	Color(0.55, 0.6, 0.5), Color(0.48, 0.48, 0.52), Color(0.64, 0.6, 0.42), Color(0.7, 0.66, 0.6)]
const COR_TERRENO := Color(0.32, 0.36, 0.26)
const COR_RUA := Color(0.22, 0.22, 0.24)
const COR_CALCADA := Color(0.5, 0.49, 0.46)
const COR_ESCADA := Color(0.45, 0.4, 0.34)
const LARGURA_DA_BORDA := 0.35
const COR_DA_BORDA := Color(0.95, 0.85, 0.45)
## Chão grande entorta demais com a textura afim do PS1: no chão, só um pouco.
const AFIM_DO_CHAO := 0.25

var dados: Dictionary = {}
var lotes: Array[Dictionary] = []
var predios: Array[StaticBody3D] = []
var arvores: MultiMeshInstance3D
var saidas: Array[Dictionary] = []
var chao: StaticBody3D
## Para onde o caçador olha ao chegar (o sentido da rua da chegada).
var giro_chegada: float = 0.0
## Subterrâneo: o nó, a geração do núcleo, a profundidade e os bueiros (na rua).
var subterraneo: Node3D
var galerias: Dictionary = {}
var profundidade: float = 0.0
var bueiros: Array[Vector3] = []
## Linha no chão em volta do bairro (a borda, como em Final Fantasy XII).
var borda: MeshInstance3D
var _tampas: Array[Node3D] = []
var _rng: RefCounted


## Monta o bairro. Pode ser chamado sem estar na árvore (testes).
## opcoes: "chao" (chão próprio; a cidade usa um chão só para todos) e "subterraneo"
## (as galerias; a cidade só monta as do bairro onde o caçador está). Os dois: sim.
func montar(id_bairro: String, semente: int, opcoes: Dictionary = {}) -> void:
	name = "Bairro_" + id_bairro
	dados = Catalogo.carregar_bairro_real(id_bairro)["dados"]
	var rng := Rng.new(semente)
	_rng = rng
	var cfg: Dictionary = Catalogo.carregar_config_lotes()["dados"]
	lotes = Lotes.gerar(dados, cfg, rng)
	if opcoes.get("chao", true):
		_montar_chao()
	for rua in dados["ruas"]:
		_montar_rua(rua, float(cfg["calcada"]))
	for lote in lotes:
		_montar_lote(lote)
	_montar_mata(rng.stream("mata:%s" % id_bairro), cfg)
	for marco in dados["marcos"]:
		_montar_marco(marco)
	_montar_borda()
	if opcoes.get("subterraneo", true):
		montar_subterraneo()
	for s in dados["saidas"]:
		var ponto := Vector3(float(s["posicao"][0]), 0.0, float(s["posicao"][1]))
		saidas.append({"rua": s["rua"], "para": s["para"], "ponto": ponto})
		Blocos.bloco(self, Vector3(0.2, 2.5, 0.2), ponto + Vector3(0, 1.25, 0), Color(0.85, 0.7, 0.3), 1.0, false)


## Onde o caçador começa: no meio do trecho de rua comum mais comprido, bem dentro do
## bairro (num morro só de escadarias, no caminho mais comprido). Guarda em giro_chegada
## o sentido da rua.
func chegada() -> Vector3:
	var limite := Lotes._pontos(dados["limite"])
	var melhor: Array = []
	var maior := -1.0
	# Primeiro só ruas comuns e longe da borda (rua que corre pela divisa deixaria o caçador
	# em cima da linha); depois, qualquer caminho dentro do bairro.
	for exigente in [true, false]:
		if maior >= 0.0:
			break
		for rua in dados["ruas"]:
			if exigente and rua["tipo"] in CAMINHOS:
				continue
			for i in rua["pontos"].size() - 1:
				var a := _v2(rua["pontos"][i])
				var b := _v2(rua["pontos"][i + 1])
				var meio := (a + b) / 2.0
				if not Geometry2D.is_point_in_polygon(meio, limite):
					continue
				if exigente and _distancia_da_borda(meio, limite) < LONGE_DA_BORDA:
					continue
				if a.distance_to(b) > maior:
					maior = a.distance_to(b)
					melhor = [a, b]
	if melhor.is_empty():
		var c: Array = dados["ruas"][0]["pontos"]
		melhor = [_v2(c[0]), _v2(c[1])]
	var meio: Vector2 = (melhor[0] + melhor[1]) / 2.0
	var direcao: Vector2 = (melhor[1] - melhor[0]).normalized()
	giro_chegada = atan2(-direcao.x, -direcao.y)
	return Vector3(meio.x, 0.3, meio.y)


static func _distancia_da_borda(p: Vector2, limite: PackedVector2Array) -> float:
	var menor := INF
	for k in limite.size():
		var q := Geometry2D.get_closest_point_to_segment(p, limite[k], limite[(k + 1) % limite.size()])
		menor = minf(menor, p.distance_to(q))
	return menor


func _montar_chao() -> void:
	var caixa: Array = dados["caixa"]
	var tamanho := Vector3(float(caixa[2]) - float(caixa[0]) + MARGEM_DO_CHAO * 2.0, 1.0,
		float(caixa[3]) - float(caixa[1]) + MARGEM_DO_CHAO * 2.0)
	var centro := Vector3((float(caixa[0]) + float(caixa[2])) / 2.0, -0.5, (float(caixa[1]) + float(caixa[3])) / 2.0)
	var malha := BoxMesh.new()
	malha.size = tamanho
	var visual := MeshInstance3D.new()
	visual.name = "Chao"
	visual.mesh = malha
	visual.material_override = Materiais.objeto(COR_TERRENO, tamanho.x / 8.0, AFIM_DO_CHAO)
	chao = StaticBody3D.new()
	chao.name = "Chao"
	chao.position = centro
	var forma := BoxShape3D.new()
	forma.size = tamanho
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	chao.add_child(colisao)
	chao.add_child(visual)
	add_child(chao)


## Faixa plana ao longo de uma linha (rua, calçada, caminho, trilho).
func _faixa(pontos: Array, largura: float, acima: float, cor: Color, nome: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var meia := largura / 2.0
	for i in pontos.size() - 1:
		var a := _v2(pontos[i])
		var b := _v2(pontos[i + 1])
		if a.distance_to(b) < 0.01:
			continue
		var lado := (b - a).normalized().orthogonal() * meia
		var cantos := [a + lado, a - lado, b - lado, b + lado]
		# Volta dos triângulos com a face para cima.
		for idx in [0, 2, 1, 0, 3, 2]:
			var c: Vector2 = cantos[idx]
			st.set_normal(Vector3.UP)
			st.set_uv(c / 4.0)
			st.add_vertex(Vector3(c.x, acima, c.y))
	var visual := MeshInstance3D.new()
	visual.name = nome
	visual.mesh = st.commit()
	visual.material_override = Materiais.objeto(cor, 1.0, AFIM_DO_CHAO)
	add_child(visual)


func _montar_rua(rua: Dictionary, calcada: float) -> void:
	var largura: float = rua["largura"]
	if rua["tipo"] in CAMINHOS:
		_faixa(rua["pontos"], largura, ACIMA_DO_CHAO_RUA, COR_ESCADA, "Caminho_%d" % int(rua["osm"]))
		return
	_faixa(rua["pontos"], largura + calcada * 2.0, ACIMA_DO_CHAO_CALCADA, COR_CALCADA, "Calcada_%d" % int(rua["osm"]))
	_faixa(rua["pontos"], largura, ACIMA_DO_CHAO_RUA, COR_RUA, "Rua_%d" % int(rua["osm"]))


func _montar_lote(lote: Dictionary) -> void:
	if lote["tipo"] != Lotes.TIPO_PREDIO:
		return
	var altura: float = int(lote["andares"]) * ALTURA_ANDAR
	var centro: Vector2 = lote["centro"]
	var cor: Color = CORES_PREDIOS[int(lote["id"]) % CORES_PREDIOS.size()]
	var corpo: Node3D = Blocos.bloco(self, Vector3(lote["frente"], altura, lote["fundo"]),
		Vector3(centro.x, altura / 2.0, centro.y), cor, 2.0)
	corpo.name = "Predio_%d" % int(lote["id"])
	corpo.rotation.y = float(lote["giro"])
	predios.append(corpo)


## Árvores (cones baixos, uma malha só) nos lotes de mata e no que sobra do morro.
func _montar_mata(gerador: RandomNumberGenerator, cfg: Dictionary) -> void:
	var pontos: Array[Vector3] = []
	for lote in lotes:
		if lote["tipo"] == Lotes.TIPO_MATA:
			var c: Vector2 = lote["centro"]
			pontos.append(Vector3(c.x, 0.0, c.y))
	if dados["zona"] == "morros":
		var limite := Lotes._pontos(dados["limite"])
		var caixa: Array = dados["caixa"]
		var x := float(caixa[0])
		while x <= float(caixa[2]):
			var z := float(caixa[1])
			while z <= float(caixa[3]):
				var p := Vector2(x + gerador.randf_range(-1.0, 1.0), z + gerador.randf_range(-1.0, 1.0))
				if Geometry2D.is_point_in_polygon(p, limite) and _livre_para_arvore(p, float(cfg["calcada"])):
					pontos.append(Vector3(p.x, 0.0, p.y))
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
	match marco["tipo"]:
		"natural=peak":
			# A capela no alto do morro (Igreja do Monte Serrat) e uma cruz.
			Blocos.bloco(self, Vector3(6, 5, 9), Vector3(p.x, 2.5, p.y), Color(0.85, 0.82, 0.74), 2.0)
			Blocos.bloco(self, Vector3(0.3, 3, 0.3), Vector3(p.x, 6.5, p.y - 3.0), Color(0.9, 0.9, 0.9), 1.0, false)
		"railway=funicular":
			if marco.has("pontos"):
				_faixa(marco["pontos"], 1.6, 0.06, Color(0.3, 0.25, 0.2), "Bondinho")
		_:
			Blocos.bloco(self, Vector3(1.2, 2.4, 1.2), Vector3(p.x, 1.2, p.y), Color(0.75, 0.68, 0.55), 1.0)


## As galerias embaixo das ruas: piso, teto e paredes no contorno do traçado, água até o
## joelho e um bueiro na rua para cada ponto de descida. Sem luz: só a lanterna.
func montar_subterraneo() -> void:
	if subterraneo != null:
		return
	var cfg: Dictionary = Catalogo.carregar_config_subterraneo()["dados"]
	galerias = Sub.gerar(dados, cfg, _rng)
	profundidade = cfg["profundidade"]
	var altura: float = cfg["altura"]
	subterraneo = Node3D.new()
	subterraneo.name = "Subterraneo"
	subterraneo.position.y = -profundidade
	add_child(subterraneo)
	if galerias["corredores"].is_empty():
		return
	var caixa: Array = dados["caixa"]
	var tamanho := Vector3(float(caixa[2]) - float(caixa[0]) + 20.0, 0.5, float(caixa[3]) - float(caixa[1]) + 20.0)
	var centro := Vector3((float(caixa[0]) + float(caixa[2])) / 2.0, 0.0, (float(caixa[1]) + float(caixa[3])) / 2.0)
	Blocos.bloco(subterraneo, tamanho, centro + Vector3(0, -0.25, 0), Color(0.18, 0.2, 0.16), tamanho.x / 6.0)
	Blocos.bloco(subterraneo, tamanho, centro + Vector3(0, altura + 0.25, 0), Color(0.16, 0.16, 0.15), tamanho.x / 6.0)
	Blocos.bloco(subterraneo, Vector3(tamanho.x, 0.02, tamanho.z), centro + Vector3(0, float(cfg["agua"]), 0),
		Color(0.1, 0.16, 0.13), tamanho.x / 6.0, false)
	# Paredes: um quadrado de pé por trecho do contorno, dos dois lados, numa malha só.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for parede in galerias["paredes"]:
		for i in parede.size() - 1:
			var a: Vector2 = parede[i]
			var b: Vector2 = parede[i + 1]
			var v := [Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(b.x, altura, b.y), Vector3(a.x, altura, a.y)]
			var u := a.distance_to(b) / 2.0
			var uvs := [Vector2(0, 0), Vector2(u, 0), Vector2(u, altura / 2.0), Vector2(0, altura / 2.0)]
			for idx in [0, 1, 2, 0, 2, 3, 0, 2, 1, 0, 3, 2]:
				st.set_uv(uvs[idx])
				st.add_vertex(v[idx])
	st.generate_normals()
	var malha := st.commit()
	var visual := MeshInstance3D.new()
	visual.name = "Paredes"
	visual.mesh = malha
	visual.material_override = Materiais.objeto(Color(0.3, 0.31, 0.27), 1.0)
	var corpo := StaticBody3D.new()
	corpo.name = "Paredes"
	var forma := ConcavePolygonShape3D.new()
	forma.set_faces(malha.get_faces())
	forma.backface_collision = true
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	corpo.add_child(colisao)
	corpo.add_child(visual)
	subterraneo.add_child(corpo)
	for p in galerias["bueiros"]:
		var em_cima := Vector3(p.x, 0.0, p.y)
		bueiros.append(em_cima)
		_tampas.append(Blocos.bloco(self, Vector3(0.9, 0.02, 0.9), em_cima + Vector3(0, ACIMA_DO_CHAO_RUA + 0.02, 0), Color(0.1, 0.1, 0.1), 1.0, false))
		# Escada de ferro: degraus do piso ao teto, embaixo do bueiro.
		for degrau in int(altura / 0.4):
			Blocos.bloco(subterraneo, Vector3(0.5, 0.05, 0.08), Vector3(p.x, 0.4 + degrau * 0.4, p.y), Color(0.42, 0.3, 0.2), 1.0, false)


## Tira as galerias e os bueiros (o bairro deixou de ser o atual).
func remover_subterraneo() -> void:
	if subterraneo == null:
		return
	subterraneo.queue_free()
	subterraneo = null
	for tampa in _tampas:
		tampa.queue_free()
	_tampas.clear()
	bueiros.clear()
	galerias = {}


## A linha em volta do bairro, um pouco acima da rua. Começa escondida.
func _montar_borda() -> void:
	var anel: Array = dados["limite"].duplicate()
	anel.append(dados["limite"][0])
	var antes := get_child_count()
	_faixa(anel, LARGURA_DA_BORDA, ACIMA_DO_CHAO_RUA + 0.03, COR_DA_BORDA, "Borda")
	borda = get_child(antes)
	borda.material_override = Materiais.objeto(COR_DA_BORDA, 1.0, 0.0)
	borda.visible = false


static func _v2(p: Array) -> Vector2:
	return Vector2(float(p[0]), float(p[1]))
