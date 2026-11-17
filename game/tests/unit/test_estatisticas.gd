extends "res://tests/framework/test_case.gd"
## Estatísticas do lote (core/casos/estatisticas.gd) e a referência de 20 sementes
## (game/tests/baselines/lote.json, rules/criterios-de-fase.md, C3).
##
## A referência é um detector de mudança: como o gerador é determinístico, qualquer
## mudança no comportamento muda estes números. Se a mudança foi de propósito, regrave com
## .\tools\lote.ps1 -AtualizarReferencia e explique no commit.

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Estatisticas := preload("res://core/casos/estatisticas.gd")

const REFERENCIA := "res://tests/baselines/lote.json"


func test_estatisticas_motivo_sem_especie_e_sem_numero() -> void:
	assert_eq(Estatisticas.resumir_motivo("corpo_seco descartada por só 1 evidência(s)"), "<espécie> descartada por só N evidência(s)")
	assert_eq(Estatisticas.resumir_motivo("a espécie verdadeira (mula_sem_cabeca) foi descartada pelas evidências"), "a espécie verdadeira (<espécie>) foi descartada pelas evidências")
	assert_eq(Estatisticas.resumir_motivo("sobraram 2 candidatas: a, b"), "sobraram N candidatas")


func test_estatisticas_contam_o_que_o_lote_tem() -> void:
	var casos: Array = []
	for semente in [1, 2, 3]:
		casos.append(Gerador.gerar(semente))
	casos.append({"valido": false, "descartes": [{"tentativa": 0, "motivos": ["sem incidente na pré-simulação"]}]})
	var r := Estatisticas.resumir(casos)
	assert_eq(r["casos"], 4, "total")
	assert_eq(r["validos"], 3, "válidos")
	assert_almost_eq(r["taxa_validos"], 0.75, 0.0001, "taxa")
	var soma_especies := 0
	for especie in r["especies"]:
		soma_especies += int(r["especies"][especie])
	assert_eq(soma_especies, 3, "uma espécie por caso válido")
	assert_gte(int(r["descartes"].get("sem incidente na pré-simulação", 0)), 1, "descarte contado")


func test_estatisticas_batem_com_a_referencia_de_20_sementes() -> void:
	var referencia: Variant = JSON.parse_string(FileAccess.get_file_as_string(REFERENCIA))
	assert_true(referencia is Dictionary, "referência legível")
	if not referencia is Dictionary:
		return
	var casos: Array = []
	for semente in range(1, 21):
		casos.append(Gerador.gerar(semente))
	var atual: Dictionary = JSON.parse_string(JSON.stringify(Estatisticas.resumir(casos)))
	var chaves: Array = referencia.keys()
	chaves.sort()
	for chave in chaves:
		if atual.get(chave) != referencia[chave]:
			fail("'%s' mudou: era %s, agora %s (se foi de propósito: .\\tools\\lote.ps1 -AtualizarReferencia)" % [chave, JSON.stringify(referencia[chave]), JSON.stringify(atual.get(chave))])
