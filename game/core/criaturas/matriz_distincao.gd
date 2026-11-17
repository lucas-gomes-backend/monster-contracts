extends RefCounted
## Matriz de distinção (docs/03-sistema-de-criaturas.md): garante que a dedução é justa.
##
## Para cada par de espécies que podem aparecer no mesmo tipo de bairro (coringas aparecem
## em todos), exige:
##   1. pelo menos MINIMO_MARCAS marcas que uma tem e a outra não;
##   2. pelo menos uma dessas marcas detectável com o equipamento inicial.

const MINIMO_MARCAS := 2
const DETECCAO_INICIAL := ["olho_nu", "entrevista", "pesquisa"]
const CORINGA := "coringa"


## Devolve a lista de problemas. Vazia = todas as espécies são distinguíveis.
static func analisar(criaturas: Dictionary) -> Array[String]:
	var problemas: Array[String] = []
	var ids := criaturas.keys()
	ids.sort()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: Dictionary = criaturas[ids[i]]
			var b: Dictionary = criaturas[ids[j]]
			if not podem_se_encontrar(a, b):
				continue
			var problema := comparar(a, b)
			if not problema.is_empty():
				problemas.append(problema)
	return problemas


## Duas espécies se encontram se alguma é coringa ou se dividem um tipo de bairro.
static func podem_se_encontrar(a: Dictionary, b: Dictionary) -> bool:
	var bairros_a: Array = a.get("bairros", [])
	var bairros_b: Array = b.get("bairros", [])
	if CORINGA in bairros_a or CORINGA in bairros_b:
		return true
	for bairro in bairros_a:
		if bairro in bairros_b:
			return true
	return false


## Devolve "" se o par é distinguível, ou a descrição do problema.
static func comparar(a: Dictionary, b: Dictionary) -> String:
	var marcas_a := _marcas(a)
	var marcas_b := _marcas(b)
	var distintivas := {}
	for tag in marcas_a:
		if not marcas_b.has(tag):
			distintivas[tag] = marcas_a[tag]
	for tag in marcas_b:
		if not marcas_a.has(tag):
			distintivas[tag] = marcas_b[tag]

	var par := "%s x %s" % [a.get("id", "?"), b.get("id", "?")]
	if distintivas.size() < MINIMO_MARCAS:
		return "%s: só %d marca(s) distintiva(s), precisa de %d" % [par, distintivas.size(), MINIMO_MARCAS]
	for tag in distintivas:
		if distintivas[tag] in DETECCAO_INICIAL:
			return ""
	return "%s: nenhuma marca distintiva é detectável com o equipamento inicial" % par


static func _marcas(ficha: Dictionary) -> Dictionary:
	var resultado := {}
	for marca in ficha.get("marcas", []):
		resultado[marca["tag"]] = marca["detectar"]
	return resultado
