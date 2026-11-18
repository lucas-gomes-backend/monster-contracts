extends RefCounted
## Altura do terreno de um bairro do mapa real, a partir da grade de relevo importada
## (game/data/cidade/<id>.json, "relevo"). Interpolação bilinear; fora da grade, a borda.

var origem := Vector2.ZERO
var passo: float = 1.0
var colunas: int = 0
var linhas: int = 0
var alturas := PackedFloat32Array()


func _init(relevo: Dictionary) -> void:
	origem = Vector2(float(relevo["origem"][0]), float(relevo["origem"][1]))
	passo = float(relevo["passo"])
	colunas = int(relevo["colunas"])
	linhas = int(relevo["linhas"])
	for valor in relevo["alturas"]:
		alturas.append(float(valor))


## Altura no ponto da grade (i, j), presa às bordas.
func no_ponto(i: int, j: int) -> float:
	i = clampi(i, 0, colunas - 1)
	j = clampi(j, 0, linhas - 1)
	return alturas[j * colunas + i]


## Altura do terreno em (x, z), em metros do jogo.
func altura(x: float, z: float) -> float:
	var gx := clampf((x - origem.x) / passo, 0.0, float(colunas - 1))
	var gz := clampf((z - origem.y) / passo, 0.0, float(linhas - 1))
	var i := int(floor(gx))
	var j := int(floor(gz))
	var fx := gx - i
	var fz := gz - j
	var topo := lerpf(no_ponto(i, j), no_ponto(i + 1, j), fx)
	var base := lerpf(no_ponto(i, j + 1), no_ponto(i + 1, j + 1), fx)
	return lerpf(topo, base, fz)


## Posição do ponto (i, j) da grade no mundo, com a altura.
func vertice(i: int, j: int) -> Vector3:
	return Vector3(origem.x + i * passo, no_ponto(i, j), origem.y + j * passo)
