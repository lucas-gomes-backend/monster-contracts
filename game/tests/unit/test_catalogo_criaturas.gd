extends "res://tests/framework/test_case.gd"
## O conteúdo de criaturas em res://data/creatures (docs/03).

const Catalogo := preload("res://core/dados/catalogo.gd")

## Criaturas do corte vertical (docs/11-roadmap.md, Fase 1).
const CORTE_VERTICAL := ["lobisomem_br", "curupira", "corpo_seco", "mula_sem_cabeca", "golpe_humano"]


func test_catalogo_todas_as_fichas_passam_no_esquema() -> void:
	var resultado := Catalogo.carregar_criaturas()
	for erro in resultado["erros"]:
		fail(erro)


func test_catalogo_tem_as_criaturas_do_corte_vertical() -> void:
	var criaturas: Dictionary = Catalogo.carregar_criaturas()["criaturas"]
	for id in CORTE_VERTICAL:
		assert_has(criaturas, id, "ficha do corte vertical")


func test_catalogo_marcas_nao_se_repetem_dentro_da_ficha() -> void:
	var criaturas: Dictionary = Catalogo.carregar_criaturas()["criaturas"]
	for id in criaturas:
		var vistas := {}
		for marca in criaturas[id]["marcas"]:
			if vistas.has(marca["tag"]):
				fail("%s: marca repetida %s" % [id, marca["tag"]])
			vistas[marca["tag"]] = true


func test_catalogo_toda_resolucao_tem_como_acontecer() -> void:
	# Curar, banir, apaziguar e prender precisam de uma fraqueza com o efeito certo.
	var efeito_por_resolucao := {"curar": "cura", "banir": "bane", "apaziguar": "apazigua", "prender": "prende"}
	var criaturas: Dictionary = Catalogo.carregar_criaturas()["criaturas"]
	for id in criaturas:
		var efeitos := {}
		for fraqueza in criaturas[id]["fraquezas"]:
			for efeito in fraqueza["efeito"]:
				efeitos[efeito] = true
		for resolucao in criaturas[id]["resolucoes"]:
			if efeito_por_resolucao.has(resolucao) and not efeitos.has(efeito_por_resolucao[resolucao]):
				fail("%s: resolução \"%s\" sem fraqueza com efeito \"%s\"" % [id, resolucao, efeito_por_resolucao[resolucao]])


func test_catalogo_arquivo_quebrado_e_reportado() -> void:
	var resultado := Catalogo.carregar_criaturas("res://pasta_que_nao_existe", "res://esquema_que_nao_existe.json")
	assert_eq(resultado["erros"].size(), 1, "esquema ausente vira erro, não silêncio")
