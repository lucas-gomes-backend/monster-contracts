extends "res://tests/framework/test_case.gd"
## Fase 5: estrutura "criatura errada" (docs/04) com o Saci só na fofoca: o cliente e quem
## viu alguma coisa culpam o Saci, mas as pistas são todas da criatura de verdade. Prender
## ou matar o Saci fere um inocente.

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Sessao := preload("res://core/investigacao/sessao.gd")
const Progresso := preload("res://core/progressao/progresso.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")

static var _caso: Dictionary = {}


func _caso_errada() -> Dictionary:
	if _caso.is_empty():
		for s in range(1, 200):
			var c := Gerador.gerar(s, "valongo")
			if c.get("valido", false) and c["estrutura"] == "criatura_errada":
				_caso = c
				break
	return _caso


func _sessao() -> RefCounted:
	var caso := Gerador.gerar(int(_caso_errada()["semente"]), "valongo")
	return Sessao.new(caso, Catalogo.carregar_criaturas()["criaturas"], Catalogo.carregar_bairro("valongo")["dados"], Catalogo.carregar_config_investigacao()["dados"])


func test_saci_e_valido_inofensivo_e_distinguivel() -> void:
	var r: Dictionary = Catalogo.carregar_criaturas()
	assert_eq(r["erros"], [] as Array[String])
	assert_eq(int(r["criaturas"]["saci"]["perigo"]), 0, "nunca faz mal")


func test_o_saci_nunca_e_o_culpado() -> void:
	for id in ["valongo", "centro"]:
		for s in range(1, 40):
			var c := Gerador.gerar(s, id)
			if c.get("valido", false):
				assert_ne(c["verdade"]["especie"], "saci", "%s semente %d" % [id, s])


func test_criatura_errada_culpa_o_saci_so_na_fofoca() -> void:
	var caso := _caso_errada()
	assert_false(caso.is_empty(), "o Valongo gera criatura errada")
	assert_eq(caso["verdade"]["criatura_acusada"], "saci")
	assert_eq(caso["contrato"]["acusa"], "saci", "o cliente jura que é o Saci")
	assert_ne(caso["verdade"]["especie"], "saci")
	var culpam := 0
	for dep in caso["depoimentos"]:
		if dep["interpretacao"] == "saci-pererê":
			culpam += 1
	assert_gte(culpam, 1, "alguém do bairro culpa o Saci")
	var tags_saci := {}
	for m in Catalogo.carregar_criaturas()["criaturas"]["saci"]["marcas"]:
		tags_saci[m["tag"]] = true
	for p in caso["pistas"]:
		assert_false(tags_saci.has(p.get("tag", "")), "as pistas são da criatura de verdade, não do Saci")


func test_no_paqueta_sem_area_verde_nao_tem_criatura_errada() -> void:
	for s in range(1, 30):
		var c := Gerador.gerar(s)
		if c.get("valido", false):
			assert_ne(c["estrutura"], "criatura_errada", "semente %d" % s)


func test_prender_o_saci_fere_um_inocente_e_resolver_a_verdadeira_funciona() -> void:
	var errado := _sessao()
	var r: Dictionary = errado.agir("prender", "saci")
	assert_true(r["ok"])
	assert_false(r["sucesso"])
	assert_true(r["criatura_inocente"])
	var p := Progresso.new(Catalogo.carregar_config_progressao()["dados"])
	p.fechar_caso(r, errado.caso["contrato"])
	assert_has(" ".join(p.fechar_caso(r, errado.caso["contrato"])["linhas"]), "inocente")
	var certo := _sessao()
	var especie: String = certo.caso["verdade"]["especie"]
	var ok: Dictionary = certo.agir(Catalogo.carregar_criaturas()["criaturas"][especie]["resolucoes"][0], especie, str(certo.caso["verdade"]["hospedeiro"]))
	assert_true(ok["sucesso"])
	assert_false(ok["criatura_inocente"])
