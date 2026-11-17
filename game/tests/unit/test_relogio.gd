extends "res://tests/framework/test_case.gd"
## Relógio do mundo (core/tempo/relogio.gd). Obrigatório: tempo errado quebra o determinismo.

const OBRIGATORIO := true
const Relogio := preload("res://core/tempo/relogio.gd")


func test_relogio_epoca_e_quinta_1970_01_01() -> void:
	var d: Dictionary = Relogio.new(0).data()
	assert_eq([d["ano"], d["mes"], d["dia"], d["nome_dia"]], [1970, 1, 1, "quinta"])


func test_relogio_dias_da_semana_de_datas_conhecidas() -> void:
	assert_eq(Relogio.de_data(2000, 1, 1).data()["nome_dia"], "sabado", "2000-01-01")
	assert_eq(Relogio.de_data(2024, 2, 29).data()["nome_dia"], "quinta", "2024-02-29 (ano bissexto)")
	assert_eq(Relogio.de_data(1908, 6, 18).data()["nome_dia"], "quinta", "chegada do Kasato Maru")


func test_relogio_ida_e_volta_de_datas_nao_perde_dias() -> void:
	# Percorre ~150 anos de 37 em 37 dias: data -> dias -> data precisa bater sempre.
	var dia := Relogio.dias_de_civil(1900, 1, 1)
	var fim := Relogio.dias_de_civil(2050, 12, 31)
	var erros := 0
	while dia <= fim:
		var c: Dictionary = Relogio.civil_de_dias(dia)
		if Relogio.dias_de_civil(c["ano"], c["mes"], c["dia"]) != dia:
			erros += 1
		dia += 37
	assert_eq(erros, 0)


func test_relogio_avancar_vira_o_dia_e_o_mes() -> void:
	var r := Relogio.de_data(2026, 1, 31, 23, 30)
	r.avancar(45)
	var d: Dictionary = r.data()
	assert_eq([d["mes"], d["dia"], d["hora"], d["minuto"]], [2, 1, 0, 15])


func test_relogio_avancar_negativo_e_recusado_e_nao_muda_nada() -> void:
	var r := Relogio.new(1000)
	assert_false(r.avancar(-1), "avanço negativo recusado")
	assert_eq(r.minutos(), 1000, "relógio intacto")


func test_relogio_noite_vai_das_18h_as_6h() -> void:
	assert_true(Relogio.de_data(2026, 3, 10, 23, 0).eh_noite(), "23h")
	assert_true(Relogio.de_data(2026, 3, 10, 5, 59).eh_noite(), "5h59")
	assert_false(Relogio.de_data(2026, 3, 10, 12, 0).eh_noite(), "meio-dia")


func test_relogio_noite_de_quinta_para_sexta() -> void:
	# 2015-11-12 foi quinta; 2015-11-13, sexta.
	assert_true(Relogio.de_data(2015, 11, 12, 23, 0).noite_entre("quinta", "sexta"), "quinta 23h")
	assert_true(Relogio.de_data(2015, 11, 13, 3, 0).noite_entre("quinta", "sexta"), "sexta 3h")
	assert_false(Relogio.de_data(2015, 11, 13, 23, 0).noite_entre("quinta", "sexta"), "sexta 23h")
	assert_false(Relogio.de_data(2015, 11, 12, 12, 0).noite_entre("quinta", "sexta"), "quinta meio-dia")


func test_relogio_sexta_feira_13_e_datas() -> void:
	assert_true(Relogio.de_data(2015, 11, 13, 20, 0).eh_sexta_feira_13(), "2015-11-13")
	assert_false(Relogio.de_data(2015, 12, 13).eh_sexta_feira_13(), "2015-12-13 foi domingo")
	assert_true(Relogio.de_data(2026, 11, 2).eh_data(11, 2), "Finados")


func test_relogio_fases_da_lua_em_datas_conhecidas() -> void:
	# Horário de Santos (UTC-3).
	assert_eq(Relogio.de_data(2000, 1, 6, 15, 14).fase_lua(), "nova", "lua nova de referência")
	assert_eq(Relogio.de_data(2000, 1, 21, 1, 40).fase_lua(), "cheia", "eclipse lunar de 2000-01-21")
	assert_eq(Relogio.de_data(2024, 1, 25, 14, 54).fase_lua(), "cheia", "lua cheia de 2024-01-25")
	assert_eq(Relogio.de_data(2000, 1, 13, 12, 0).fase_lua(), "crescente", "uma semana depois da nova")
	assert_eq(Relogio.de_data(2000, 1, 28, 12, 0).fase_lua(), "minguante", "uma semana depois da cheia")
