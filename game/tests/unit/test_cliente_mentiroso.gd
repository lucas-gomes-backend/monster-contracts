extends "res://tests/framework/test_case.gd"
## Fase 5: estrutura "cliente mentiroso" (docs/04): quem contrata é o culpado humano e
## esconde o crime. No fim, o caçador expõe o cliente (reputação, sem pagamento, cartas de
## ameaça) ou fica quieto (recebe, e o crime continua).

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Sessao := preload("res://core/investigacao/sessao.gd")
const Progresso := preload("res://core/progressao/progresso.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")

static var _caso: Dictionary = {}


## O primeiro caso de cliente mentiroso no Valongo (que tem área verde para o crime).
func _caso_mentiroso() -> Dictionary:
	if _caso.is_empty():
		for s in range(1, 200):
			var c := Gerador.gerar(s, "valongo")
			if c.get("valido", false) and c["estrutura"] == "cliente_mentiroso":
				_caso = c
				break
	return _caso


func _sessao() -> RefCounted:
	var caso := Gerador.gerar(int(_caso_mentiroso()["semente"]), "valongo")
	return Sessao.new(caso, Catalogo.carregar_criaturas()["criaturas"], Catalogo.carregar_bairro("valongo")["dados"], Catalogo.carregar_config_investigacao()["dados"])


func test_cliente_mentiroso_nasce_e_o_cliente_e_o_culpado() -> void:
	var caso := _caso_mentiroso()
	assert_false(caso.is_empty(), "o Valongo gera cliente mentiroso")
	assert_eq(caso["contrato"]["cliente"], caso["verdade"]["culpado"], "quem contrata cometeu o crime")
	assert_eq(caso["contrato"]["esconde"], "crime")
	assert_true(caso["verdade"]["cliente_mentiroso"])


func test_no_paqueta_sem_crime_possivel_nao_tem_cliente_mentiroso() -> void:
	for s in range(1, 30):
		var c := Gerador.gerar(s)
		if c.get("valido", false):
			assert_ne(c["estrutura"], "cliente_mentiroso", "semente %d" % s)


func test_expor_o_cliente_culpado_sobe_a_reputacao_sem_pagamento() -> void:
	var s := _sessao()
	var especie: String = s.caso["verdade"]["especie"]
	var resolucao: String = Catalogo.carregar_criaturas()["criaturas"][especie]["resolucoes"][0]
	var r: Dictionary = s.agir(resolucao, especie, "", true)
	assert_true(r["ok"])
	assert_true(r["cliente_exposto"])
	assert_eq(r["recompensa"], 0, "o cliente exposto não paga")
	assert_eq(r["inocente_prejudicado"], "", "o cliente era culpado")
	var p := Progresso.new(Catalogo.carregar_config_progressao()["dados"])
	var calado := Progresso.new(Catalogo.carregar_config_progressao()["dados"])
	var fechado := p.fechar_caso(r, s.caso["contrato"])
	var sem_expor := r.duplicate()
	sem_expor["cliente_exposto"] = false
	calado.fechar_caso(sem_expor, s.caso["contrato"])
	assert_true(p.reputacao > calado.reputacao, "expor dá mais reputação que calar")
	assert_has(" ".join(fechado["linhas"]), "expôs o cliente")
	var situacoes: Array = s.cartas().map(func(c): return c["situacao"])
	assert_has(situacoes, "cliente_exposto", "chegam ameaças e cartas de advogado")


func test_calar_recebe_e_o_crime_continua() -> void:
	var s := _sessao()
	var especie: String = s.caso["verdade"]["especie"]
	var resolucao: String = Catalogo.carregar_criaturas()["criaturas"][especie]["resolucoes"][0]
	var r: Dictionary = s.agir(resolucao, especie)
	assert_false(r["cliente_exposto"])
	assert_true(r["crime_continua"])
	if r["sucesso"]:
		assert_true(int(r["recompensa"]) > 0, "ficar quieto: o cliente paga")


func test_expor_um_cliente_inocente_e_prejudicar_um_inocente() -> void:
	for s in range(1, 20):
		var caso := Gerador.gerar(s, "valongo")
		if not caso.get("valido", false) or caso["estrutura"] == "cliente_mentiroso":
			continue
		var sessao := Sessao.new(caso, Catalogo.carregar_criaturas()["criaturas"], Catalogo.carregar_bairro("valongo")["dados"], Catalogo.carregar_config_investigacao()["dados"])
		var especie: String = caso["verdade"]["especie"]
		var r: Dictionary = sessao.agir(Catalogo.carregar_criaturas()["criaturas"][especie]["resolucoes"][0], especie, str(caso["verdade"]["hospedeiro"]), true)
		assert_true(r["ok"], str(r.get("erro", "")))
		assert_false(r["cliente_exposto"])
		assert_eq(r["inocente_prejudicado"], caso["contrato"]["cliente"])
		return
	assert_true(false, "nenhum caso comum no Valongo")
