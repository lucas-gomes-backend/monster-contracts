extends "res://tests/framework/test_case.gd"
## Fase 3: os bairros do mapa real (game/data/cidade, gerados por tools/cidade/importar.py)
## chegam ao jogo válidos. Os testes da importação em si ficam em tools/cidade/testes.

const Catalogo := preload("res://core/dados/catalogo.gd")


func test_cidade_os_bairros_do_portao_foram_importados() -> void:
	var ids := Catalogo.bairros_reais()
	assert_has(ids, "valongo")
	assert_has(ids, "monte_serrat")


func test_cidade_todo_bairro_importado_passa_no_esquema() -> void:
	for id in Catalogo.bairros_reais():
		var r := Catalogo.carregar_bairro_real(id)
		assert_eq(r["erros"].size(), 0, "%s: %s" % [id, r["erros"]])


func test_cidade_bairro_tem_ruas_saidas_e_tamanho_de_bairro_reduzido() -> void:
	for id in Catalogo.bairros_reais():
		var b: Dictionary = Catalogo.carregar_bairro_real(id)["dados"]
		assert_gte(b["ruas"].size(), 1, "%s tem ruas" % id)
		assert_gte(b["saidas"].size(), 1, "%s liga com algum vizinho" % id)
		var caixa: Array = b["caixa"]
		var lado := maxf(float(caixa[2]) - float(caixa[0]), float(caixa[3]) - float(caixa[1]))
		assert_true(lado > 100.0 and lado < 1000.0, "%s: %.0f m de lado no jogo" % [id, lado])


func test_cidade_relevo_tem_uma_altura_por_ponto_da_grade_e_cobre_o_bairro() -> void:
	for id in Catalogo.bairros_reais():
		var b: Dictionary = Catalogo.carregar_bairro_real(id)["dados"]
		var r: Dictionary = b["relevo"]
		assert_eq(r["alturas"].size(), int(r["colunas"]) * int(r["linhas"]), id)
		var caixa: Array = b["caixa"]
		assert_true(float(r["origem"][0]) <= float(caixa[0]) and float(r["origem"][1]) <= float(caixa[1]), "%s: a grade começa antes do bairro" % id)
		assert_true(float(r["origem"][0]) + (int(r["colunas"]) - 1) * float(r["passo"]) >= float(caixa[2]), "%s: cobre até o leste" % id)
		assert_true(float(r["origem"][1]) + (int(r["linhas"]) - 1) * float(r["passo"]) >= float(caixa[3]), "%s: cobre até o sul" % id)
