extends "res://tests/framework/test_case.gd"
## Portão da Fase 1 (docs/11): pelo menos 95% das sementes geram um caso JUSTO, isto é,
## que o solucionador automático consegue resolver como um iniciante (docs/04, passo 8).
## A métrica entra no portão de 95% (record_metric).

const Gerador := preload("res://core/casos/gerador_casos.gd")

const CASOS_POR_LOTE := 100


func test_casos_gerados_passam_na_validacao() -> void:
	var validos := 0
	var por_especie := {}
	for semente in range(1, CASOS_POR_LOTE + 1):
		var caso := Gerador.gerar(semente)
		if caso.get("valido", false) and caso["validacao"]["valido"]:
			validos += 1
			var especie: String = caso["verdade"]["especie"]
			por_especie[especie] = int(por_especie.get(especie, 0)) + 1
	record_metric("casos_validos", float(validos) / CASOS_POR_LOTE)
	# Variedade: o lote não pode virar sempre a mesma espécie.
	assert_gte(por_especie.size(), 3, "pelo menos 3 espécies no lote: %s" % str(por_especie))
