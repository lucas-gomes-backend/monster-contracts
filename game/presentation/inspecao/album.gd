extends RefCounted
## Fotos tiradas pelo caçador (docs/05, "Fotografar"): o filme é limitado e cada foto
## guarda quais marcas saíram nela. Uma marca fotografada fica registrada mesmo depois
## que a pista some (a ligação com o caderno vem na tarefa "ligar o núcleo às cenas").

var filme: int
var fotos: Array[Dictionary] = []


func _init(tamanho_do_filme: int) -> void:
	filme = tamanho_do_filme


func restantes() -> int:
	return filme - fotos.size()


## Tira uma foto. Devolve a foto ({"numero", "marcas", "imagem"}) ou {} se o filme acabou.
func fotografar(marcas: Array, imagem: Image = null) -> Dictionary:
	if restantes() <= 0:
		return {}
	var unicas: Array[String] = []
	for marca in marcas:
		if not unicas.has(marca):
			unicas.append(marca)
	unicas.sort()
	var foto := {"numero": fotos.size() + 1, "marcas": unicas, "imagem": imagem}
	fotos.append(foto)
	return foto


## Todas as marcas que aparecem em alguma foto, sem repetir, em ordem.
func marcas_registradas() -> Array[String]:
	var todas: Array[String] = []
	for foto in fotos:
		for marca in foto["marcas"]:
			if not todas.has(marca):
				todas.append(marca)
	todas.sort()
	return todas
