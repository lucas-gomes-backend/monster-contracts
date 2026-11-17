extends "res://tests/framework/test_case.gd"
## Matriz de distinção com fichas de exemplo (core/criaturas/matriz_distincao.gd).

const Matriz := preload("res://core/criaturas/matriz_distincao.gd")


func _ficha(id: String, bairros: Array, marcas: Array) -> Dictionary:
	var lista := []
	for m in marcas:
		lista.append({"tag": m[0], "detectar": m[1]})
	return {"id": id, "bairros": bairros, "marcas": lista}


func test_matriz_especies_parecidas_demais_sao_apontadas() -> void:
	var a := _ficha("a", ["mata"], [["pegada", "olho_nu"], ["pelo", "olho_nu"]])
	var b := _ficha("b", ["mata"], [["pegada", "olho_nu"], ["pelo", "olho_nu"], ["uivo", "entrevista"]])
	assert_eq(Matriz.analisar({"a": a, "b": b}).size(), 1, "só 1 marca distintiva")


func test_matriz_distincao_so_com_equipamento_avancado_e_apontada() -> void:
	var a := _ficha("a", ["mata"], [["pegada", "olho_nu"], ["dna_x", "laboratorio"]])
	var b := _ficha("b", ["mata"], [["pegada", "olho_nu"], ["dna_y", "laboratorio"]])
	assert_eq(Matriz.analisar({"a": a, "b": b}).size(), 1)


func test_matriz_especies_bem_diferentes_passam() -> void:
	var a := _ficha("a", ["mata"], [["pegada", "olho_nu"], ["assobio", "entrevista"]])
	var b := _ficha("b", ["mata"], [["casco", "olho_nu"], ["relincho", "entrevista"]])
	assert_eq(Matriz.analisar({"a": a, "b": b}).size(), 0)


func test_matriz_bairros_diferentes_nao_sao_comparados() -> void:
	var a := _ficha("a", ["mata"], [["pegada", "olho_nu"]])
	var b := _ficha("b", ["orla"], [["pegada", "olho_nu"]])
	assert_eq(Matriz.analisar({"a": a, "b": b}).size(), 0)


func test_matriz_coringa_e_comparada_com_todos() -> void:
	var a := _ficha("a", ["mata"], [["pegada", "olho_nu"]])
	var b := _ficha("b", ["coringa"], [["pegada", "olho_nu"]])
	assert_eq(Matriz.analisar({"a": a, "b": b}).size(), 1)
