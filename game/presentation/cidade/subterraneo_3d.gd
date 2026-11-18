extends Node3D
## As galerias em 3D (rede de core/cidade/subterraneo.gd): piso, teto e paredes no contorno
## do traçado (com colisão), água até o joelho, escada de ferro embaixo de cada bueiro e a
## tampa do bueiro na rua. Sem luz: só a lanterna. O nó fica na profundidade das galerias;
## as tampas sobem até a rua.

const Materiais := preload("res://presentation/ps1/materiais.gd")
const Blocos := preload("res://presentation/greybox/blocos.gd")

## Altura das tampas acima do chão (logo acima da faixa da rua).
const ALTURA_DA_TAMPA := 0.12
## Quanto a água sobe da maré baixa à alta (metros).
const SUBIDA_DA_AGUA := 0.7

var galerias: Dictionary = {}
var profundidade: float = 0.0
## Bueiros na rua (y = 0).
var bueiros: Array[Vector3] = []
## A lâmina d'água (sobe com a maré) e a altura dela na maré baixa.
var agua: Node3D
var agua_baixa: float = 0.0


## rede: saída de Sub.gerar_rede; area: retângulo (x, z) que o piso e o teto cobrem.
func montar(rede: Dictionary, cfg: Dictionary, area: Rect2) -> void:
	name = "Subterraneo"
	galerias = rede
	profundidade = cfg["profundidade"]
	position.y = -profundidade
	var altura: float = cfg["altura"]
	if rede["corredores"].is_empty():
		return
	var tamanho := Vector3(area.size.x, 0.5, area.size.y)
	var centro := Vector3(area.get_center().x, 0.0, area.get_center().y)
	Blocos.bloco(self, tamanho, centro + Vector3(0, -0.25, 0), Color(0.18, 0.2, 0.16), tamanho.x / 6.0)
	Blocos.bloco(self, tamanho, centro + Vector3(0, altura + 0.25, 0), Color(0.16, 0.16, 0.15), tamanho.x / 6.0)
	agua_baixa = cfg["agua"]
	agua = Blocos.bloco(self, Vector3(tamanho.x, 0.02, tamanho.z), centro + Vector3(0, agua_baixa, 0),
		Color(0.1, 0.16, 0.13), tamanho.x / 6.0, false)
	_montar_paredes(rede["paredes"], altura)
	for p in rede["bueiros"]:
		bueiros.append(Vector3(p.x, 0.0, p.y))
		Blocos.bloco(self, Vector3(0.9, 0.02, 0.9), Vector3(p.x, profundidade + ALTURA_DA_TAMPA, p.y), Color(0.1, 0.1, 0.1), 1.0, false)
		# Escada de ferro: degraus do piso ao teto, embaixo do bueiro.
		for degrau in int(altura / 0.4):
			Blocos.bloco(self, Vector3(0.5, 0.05, 0.08), Vector3(p.x, 0.4 + degrau * 0.4, p.y), Color(0.42, 0.3, 0.2), 1.0, false)


## A água sobe com a maré: fracao 0 (baixa-mar) a 1 (preamar), até a cintura.
func nivel_da_agua(fracao: float) -> void:
	if agua:
		agua.position.y = agua_baixa + fracao * SUBIDA_DA_AGUA


## Paredes: um quadrado de pé por trecho do contorno, dos dois lados, numa malha só.
func _montar_paredes(paredes: Array, altura: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for parede in paredes:
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
	add_child(corpo)
