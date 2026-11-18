extends Node3D
## Uma pista no mundo 3D: uma marca (game/data/textos/marcas.json) com forma, cor e
## se dá para pegar e girar na mão ou só examinar no lugar (pegadas, sangue no chão).

const Materiais := preload("res://presentation/ps1/materiais.gd")

var marca: String = ""
## Id da pista no caso (core/casos), para anotar no caderno ao examinar ou fotografar.
var pista_id: String = ""
var texto: String = ""
var pegavel: bool = false
var malha: Mesh


## Monta a pista a partir de uma entrada de game/data/greybox/*.json.
func montar(dados: Dictionary, textos_marcas: Dictionary) -> void:
	marca = dados["marca"]
	name = "Pista_" + marca
	pegavel = dados["pegavel"]
	texto = textos_marcas.get(marca, {}).get("pista", marca)
	var p: Array = dados["posicao"]
	position = Vector3(p[0], p[1], p[2])
	var t: Array = dados["tamanho"]
	var tamanho := Vector3(t[0], t[1], t[2])
	match dados["forma"]:
		"plano":
			var plano := PlaneMesh.new()
			plano.size = Vector2(tamanho.x, tamanho.z)
			malha = plano
		"esfera":
			var esfera := SphereMesh.new()
			esfera.radius = tamanho.x
			esfera.height = tamanho.y * 2.0
			esfera.radial_segments = 6
			esfera.rings = 3
			malha = esfera
		_:
			var caixa := BoxMesh.new()
			caixa.size = tamanho
			malha = caixa
	var visual := MeshInstance3D.new()
	visual.mesh = malha
	visual.material_override = Materiais.objeto(Color.html(dados["cor"]))
	add_child(visual)


## Some do mundo enquanto está na mão do caçador, e volta quando ele solta.
func na_mao(segurando: bool) -> void:
	visible = not segurando
