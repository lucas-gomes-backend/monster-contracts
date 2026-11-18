extends Node3D
## Uma pessoa do caso parada no mundo cinza: corpo em cápsula, cor tirada do id (sem
## sorteio) e o id do NPC do núcleo, para a conversa saber com quem está falando.

const Materiais := preload("res://presentation/ps1/materiais.gd")

const ALTURA := 1.7
const CORES := [Color(0.45, 0.35, 0.55), Color(0.3, 0.45, 0.4), Color(0.55, 0.4, 0.3), Color(0.35, 0.4, 0.55)]

var npc_id: String = ""
var nome: String = ""


## cor: a do corpo; sem ela, uma das CORES pelo id (policiais usam o azul da farda).
func montar(id: String, nome_completo: String, cor: Variant = null) -> void:
	npc_id = id
	nome = nome_completo
	name = "Morador_" + id
	var corpo := MeshInstance3D.new()
	var capsula := CapsuleMesh.new()
	capsula.height = ALTURA
	capsula.radius = 0.28
	capsula.radial_segments = 8
	capsula.rings = 2
	corpo.mesh = capsula
	corpo.position.y = ALTURA / 2.0
	corpo.material_override = Materiais.objeto(cor if cor is Color else CORES[id.hash() % CORES.size()])
	add_child(corpo)
	var cabeca := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(0.3, 0.3, 0.3)
	cabeca.mesh = caixa
	cabeca.position.y = ALTURA + 0.1
	cabeca.material_override = Materiais.objeto(Color(0.75, 0.6, 0.5))
	add_child(cabeca)


## Ponto para onde se olha ao conversar (a altura do rosto).
func ponto_de_conversa() -> Vector3:
	return position + Vector3(0, ALTURA - 0.1, 0)
