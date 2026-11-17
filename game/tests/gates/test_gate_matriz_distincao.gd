extends "res://tests/framework/test_case.gd"
## Portão da Fase 1: todas as espécies do catálogo são distinguíveis entre si
## (docs/03, "Matriz de distinção"). Obrigatório: é a garantia de dedução justa.

const OBRIGATORIO := true
const Catalogo := preload("res://core/dados/catalogo.gd")
const Matriz := preload("res://core/criaturas/matriz_distincao.gd")


func test_matriz_todas_as_especies_do_catalogo_sao_distinguiveis() -> void:
	var criaturas: Dictionary = Catalogo.carregar_criaturas()["criaturas"]
	assert_gte(criaturas.size(), 2, "precisa de pelo menos 2 espécies para comparar")
	for problema in Matriz.analisar(criaturas):
		fail(problema)
