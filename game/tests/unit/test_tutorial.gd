extends "res://tests/framework/test_case.gd"
## Fase 4: caso tutorial com mentor aleatório (core/investigacao/tutorial.gd, docs/02).

const Tutorial := preload("res://core/investigacao/tutorial.gd")
const Gerador := preload("res://core/casos/gerador_casos.gd")
const Sessao := preload("res://core/investigacao/sessao.gd")
const Regras := preload("res://core/investigacao/regras_de_campo.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Jogo := preload("res://ui/jogo.gd")


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_tutorial()["dados"]


func _sessao() -> RefCounted:
	var caso := Gerador.gerar(Tutorial.semente_do_caso(_cfg()))
	return Sessao.new(caso, Catalogo.carregar_criaturas()["criaturas"], Catalogo.carregar_bairro(caso["bairro"])["dados"], Catalogo.carregar_config_investigacao()["dados"])


func test_tutorial_config_e_valida_e_o_teste_ensinado_funciona_na_especie() -> void:
	assert_eq(Catalogo.carregar_config_tutorial()["erros"], [] as Array[String])
	var ficha: Dictionary = Catalogo.carregar_criaturas()["criaturas"][_cfg()["especie"]]
	var teste: Dictionary = {}
	for t in Catalogo.carregar_config_testes()["dados"]["testes"]:
		if t["id"] == _cfg()["teste"]:
			teste = t
	assert_false(teste.is_empty(), "o teste existe")
	var caso := Gerador.gerar(Tutorial.semente_do_caso(_cfg()))
	assert_true(Regras.positivo(teste, ficha, caso["verdade"], caso["verdade"]["locais"][0]), "no lugar certo, o teste dá positivo")


func test_caso_do_tutorial_e_caca_simples_justa_da_especie() -> void:
	var caso := Gerador.gerar(Tutorial.semente_do_caso(_cfg()))
	assert_true(caso["valido"])
	assert_eq(caso["estrutura"], "caca_simples")
	assert_eq(caso["verdade"]["especie"], _cfg()["especie"])


func test_mentor_aleatorio_pela_semente() -> void:
	var pop: Dictionary = Catalogo.carregar_config_populacao()["dados"]
	var a := Tutorial.gerar_mentor(5, _cfg(), pop)
	assert_eq(a, Tutorial.gerar_mentor(5, _cfg(), pop), "mesma semente, mesmo mentor")
	assert_true(int(a["idade"]) >= 58 and int(a["idade"]) <= 74, "veterano")
	assert_has(a["apresentacao"], a["nome"])
	var nomes := {}
	for s in 30:
		nomes[Tutorial.gerar_mentor(s, _cfg(), pop)["nome"]] = true
	assert_gte(nomes.size(), 10, "mentores variados")


func test_o_mentor_acompanha_cada_passo_ate_o_fim() -> void:
	var s := _sessao()
	var passo := func() -> String: return Tutorial.passo_atual(_cfg(), s)["id"]
	assert_eq(passo.call(), "ir_ao_local")
	# chegar: vai até o lugar sem anotar (como no 3D); no caderno, "ir" já anota.
	s.chegar(Tutorial.ultimo_ataque(s.caso))
	assert_eq(passo.call(), "anotar_pista")
	var pistas: Array = s.pistas_no_local()
	assert_false(pistas.is_empty(), "o lugar do ataque tem pistas")
	s.examinar_pista(pistas[0]["id"])
	assert_eq(passo.call(), "ouvir_testemunha")
	var falou := false
	for local in s.locais():
		s.ir(local)
		for npc in s.pessoas_aqui():
			if s.entrevistar(npc).get("ok", false):
				falou = true
				break
		if falou:
			break
	assert_true(falou, "alguém para conversar")
	assert_eq(passo.call(), "ligar")
	var fonte: String = s.caderno.pistas()[0]["id"]
	s.caderno.ligar(fonte, s.caderno.vocabulario()[0])
	assert_eq(passo.call(), "teste_de_campo")
	s.aplicar_teste(_cfg()["teste"], Tutorial.ultimo_ataque(s.caso))
	assert_eq(passo.call(), "agir")
	s.agir("banir", _cfg()["especie"])
	assert_eq(passo.call(), "fim")


func test_o_mentor_nunca_diz_qual_e_a_criatura() -> void:
	var s := _sessao()
	var ficha: Dictionary = Catalogo.carregar_criaturas()["criaturas"][_cfg()["especie"]]
	for p in _cfg()["passos"]:
		var fala := Tutorial.fala(p, s, _cfg(), "Linha de sal").to_lower()
		assert_false(str(ficha["nome"]).to_lower() in fala, "passo %s" % p["id"])
		assert_false("corpo" in fala and "seco" in fala, "passo %s" % p["id"])


func test_janela_do_caso_mostra_o_mentor_no_tutorial() -> void:
	var jogo := Jogo.new()
	jogo.montar()
	jogo.comecar_tutorial()
	assert_true(jogo._mentor_painel.visible)
	assert_has(jogo._mentor_texto.text, "Objetivo: Vá ao lugar do ataque")
	assert_has(jogo._diario.get_parsed_text(), "[MENTOR] %s" % jogo.mentor["nome"])
	jogo.sessao.ir(Tutorial.ultimo_ataque(jogo.sessao.caso))
	jogo.atualizar()
	# No caderno, ir ao lugar já anota as pistas: o mentor pula para a próxima lição.
	assert_has(jogo._mentor_texto.text, "Objetivo: Converse com alguém", "o mentor acompanhou")
	assert_has(jogo._diario.get_parsed_text(), "Agora gente.")
	jogo.free()


func test_fora_do_tutorial_nao_tem_mentor() -> void:
	var jogo := Jogo.new()
	jogo.montar()
	jogo.novo_caso(3)
	assert_false(jogo._mentor_painel.visible)
	jogo.free()
