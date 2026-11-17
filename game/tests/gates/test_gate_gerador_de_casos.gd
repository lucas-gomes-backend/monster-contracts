extends "res://tests/framework/test_case.gd"
## Portão da Fase 1 (docs/11): pelo menos 95% dos casos gerados precisam
## passar na validação do solucionador automático (docs/04).
##
## Enquanto o gerador não existe, o teste é pulado. Quando existir, o corpo fica
## parecido com isto:
##
##   var total := 100
##   var validos := 0
##   for semente in total:
##       var caso := GeradorDeCasos.gerar(semente)
##       if Solucionador.validar(caso).valido:
##           validos += 1
##   record_metric("casos_validos", float(validos) / total)

const CASOS_POR_LOTE := 100


func test_casos_gerados_passam_na_validacao() -> void:
	skip("o gerador de casos chega na Fase 1")


func test_matriz_de_distincao_das_criaturas() -> void:
	skip("as fichas de criaturas chegam na Fase 1")
