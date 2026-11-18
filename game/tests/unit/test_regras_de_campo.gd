extends "res://tests/framework/test_case.gd"
## Testes de campo e desfecho do caso (core/investigacao/regras_de_campo.gd, sessao.gd).

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Sessao := preload("res://core/investigacao/sessao.gd")
const Regras := preload("res://core/investigacao/regras_de_campo.gd")
const Interpretador := preload("res://ui/texto/interpretador.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Relogio := preload("res://core/tempo/relogio.gd")

const SEMENTES := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_testes()["dados"]


func _criaturas() -> Dictionary:
	return Catalogo.carregar_criaturas()["criaturas"]


func _teste(id: String) -> Dictionary:
	for t in _cfg()["testes"]:
		if t["id"] == id:
			return t
	return {}


func _sessao(caso: Dictionary) -> RefCounted:
	return Sessao.new(caso, _criaturas(), Catalogo.carregar_bairro(caso["bairro"])["dados"], Catalogo.carregar_config_investigacao()["dados"])


func _primeiro_caso(especie: String) -> Dictionary:
	for semente in range(1, 80):
		var caso := Gerador.gerar(semente)
		if caso["verdade"]["especie"] == especie:
			return caso
	return {}


func test_testes_de_campo_config_e_valida() -> void:
	assert_eq(Catalogo.carregar_config_testes()["erros"], [] as Array[String])


## Grãos e espelho: o Strigoi (Fase 5) é quem eles pegam. No corte vertical davam sempre
## negativo (docs/05: um negativo também é informação).
const GRAOS_E_ESPELHO := ["graos_na_porta", "espelho_ou_camera"]
const CORTE_VERTICAL := ["corpo_seco", "curupira", "lobisomem_br", "mula_sem_cabeca", "golpe_humano"]


func test_testes_de_campo_todo_item_existe_em_alguma_ficha() -> void:
	var itens := {}
	for ficha in _criaturas().values():
		for f in ficha["fraquezas"]:
			itens[f["item"]] = true
	for teste in _cfg()["testes"]:
		if teste.has("positivo_se"):
			continue
		for item in teste["itens"]:
			if not itens.has(item):
				fail("%s usa o item %s, que nenhuma ficha tem" % [teste["id"], item])


func test_ferimento_revelador_so_da_positivo_no_hospedeiro() -> void:
	var ferimento := _teste("ferimento_revelador")
	var conferidos := 0
	for semente in SEMENTES:
		var caso := Gerador.gerar(semente)
		var ficha: Dictionary = _criaturas()[caso["verdade"]["especie"]]
		var hospedeiro: String = caso["verdade"]["hospedeiro"]
		if hospedeiro.is_empty() or ficha["id"] == "golpe_humano":
			continue
		conferidos += 1
		assert_true(Regras.positivo(ferimento, ficha, caso["verdade"], hospedeiro), "semente %d: no hospedeiro" % semente)
		assert_false(Regras.positivo(ferimento, ficha, caso["verdade"], caso["contrato"]["cliente"]), "semente %d: no cliente" % semente)
	assert_gte(conferidos, 1, "havia casos com hospedeiro")


func test_ferimento_revelador_nao_revela_golpista() -> void:
	var caso := _primeiro_caso("golpe_humano")
	assert_false(caso.is_empty())
	if not caso.is_empty():
		assert_false(Regras.positivo(_teste("ferimento_revelador"), _criaturas()["golpe_humano"], caso["verdade"], caso["verdade"]["hospedeiro"]), "golpista não tem fraqueza que o ferimento revela")


func test_linha_de_sal_pega_o_corpo_seco_nos_lugares_dele() -> void:
	var caso := _primeiro_caso("corpo_seco")
	assert_false(caso.is_empty())
	if caso.is_empty():
		return
	var sal := _teste("linha_de_sal")
	var ficha: Dictionary = _criaturas()["corpo_seco"]
	assert_true(Regras.positivo(sal, ficha, caso["verdade"], caso["verdade"]["locais"][0]), "lugar que ele frequenta")
	assert_false(Regras.positivo(sal, ficha, caso["verdade"], "paqueta/escola"), "lugar onde ele não vai")
	assert_false(Regras.positivo(sal, _criaturas()["lobisomem_br"], caso["verdade"], caso["verdade"]["locais"][0]), "lobisomem não tem fraqueza a sal")


func test_ferimento_espera_a_noite_da_criatura_e_o_resultado_sai_de_manha() -> void:
	var ficha: Dictionary = _criaturas()["lobisomem_br"]
	var segunda := Relogio.minutos_de(2015, 11, 9, 10)
	var m := Regras.minuto_do_resultado(_teste("ferimento_revelador"), segunda, ficha, Catalogo.carregar_config_criaturas()["dados"], _cfg())
	var d := Relogio.data_de(m)
	assert_eq([d["nome_dia"], d["hora"]], ["sexta", 8], "a fera só sai na noite de quinta para sexta")


func test_teste_de_uma_noite_sai_na_manha_seguinte() -> void:
	var ficha: Dictionary = _criaturas()["corpo_seco"]
	var m := Regras.minuto_do_resultado(_teste("linha_de_sal"), Relogio.minutos_de(2015, 11, 9, 10), ficha, Catalogo.carregar_config_criaturas()["dados"], _cfg())
	assert_eq(m, Relogio.minutos_de(2015, 11, 10, 8))


func test_criatura_instintiva_nunca_percebe_o_teste() -> void:
	for n in 50:
		assert_false(Regras.percebeu(_criaturas()["lobisomem_br"], _cfg(), 1, n))


func test_desfecho_com_tudo_certo_e_sucesso_em_todo_caso_gerado() -> void:
	for semente in SEMENTES:
		var caso := Gerador.gerar(semente)
		var ficha: Dictionary = _criaturas()[caso["verdade"]["especie"]]
		var r := Regras.decidir(ficha["resolucoes"][0], ficha["id"], caso["verdade"]["hospedeiro"], caso, _criaturas(), _cfg())
		assert_true(r.get("sucesso", false), "semente %d: %s" % [semente, r.get("motivo", r.get("erro", ""))])


func test_desfecho_especie_errada_fracassa() -> void:
	var caso := _primeiro_caso("corpo_seco")
	var r := Regras.decidir("matar", "lobisomem_br", "", caso, _criaturas(), _cfg())
	assert_true(r["ok"])
	assert_false(r["sucesso"])
	assert_false(r["especie_certa"])


func test_desfecho_pessoa_errada_fracassa_e_prejudica_um_inocente() -> void:
	var caso := _primeiro_caso("lobisomem_br")
	var inocente: String = caso["contrato"]["cliente"]
	var r := Regras.decidir("prender", "lobisomem_br", inocente, caso, _criaturas(), _cfg())
	assert_false(r["sucesso"])
	assert_eq(r["inocente_prejudicado"], inocente)


func test_desfecho_matar_o_lobisomem_resolve_mas_mata_um_amaldicoado() -> void:
	var caso := _primeiro_caso("lobisomem_br")
	var r := Regras.decidir("matar", "lobisomem_br", caso["verdade"]["hospedeiro"], caso, _criaturas(), _cfg())
	assert_true(r["sucesso"])
	assert_true(r["amaldicoado_morto"], "o hospedeiro podia ter sido curado")


func test_desfecho_depois_do_prazo_resolve_mas_nao_paga() -> void:
	var caso := _primeiro_caso("lobisomem_br")
	var depois := int(caso["contrato"]["prazo_minuto"]) + 60
	var no_prazo := Regras.decidir("curar", "lobisomem_br", caso["verdade"]["hospedeiro"], caso, _criaturas(), _cfg(), int(caso["contrato"]["minuto"]))
	var atrasado := Regras.decidir("curar", "lobisomem_br", caso["verdade"]["hospedeiro"], caso, _criaturas(), _cfg(), depois)
	assert_eq(no_prazo["recompensa"], int(caso["contrato"]["recompensa"]), "no prazo, paga")
	assert_true(atrasado["sucesso"], "a criatura foi resolvida mesmo assim")
	assert_true(atrasado["prazo_estourado"])
	assert_eq(atrasado["recompensa"], 0, "o cliente desistiu")


func test_desfecho_recusa_o_que_nao_faz_sentido() -> void:
	var caso := _primeiro_caso("lobisomem_br")
	assert_false(Regras.decidir("apaziguar", "lobisomem_br", "", caso, _criaturas(), _cfg())["ok"], "lobisomem não se apazigua")
	assert_false(Regras.decidir("curar", "lobisomem_br", "", caso, _criaturas(), _cfg())["ok"], "curar precisa de quem")
	assert_false(Regras.decidir("matar", "saci", "", caso, _criaturas(), _cfg())["ok"], "espécie desconhecida")


func test_sessao_agir_encerra_o_caso_uma_vez_so() -> void:
	var caso := Gerador.gerar(5)
	var s := _sessao(caso)
	var jogo := Interpretador.new(s, _criaturas(), Catalogo.carregar_textos_marcas()["dados"])
	assert_false(s.encerrado())
	assert_has(jogo.executar("agir abandonar"), "Caso encerrado")
	assert_true(s.encerrado())
	assert_false(s.agir("matar", "corpo_seco")["ok"], "não dá para agir de novo")
	assert_has(jogo.executar("ir l1"), "já foi encerrado")
	assert_has(jogo.executar("resultado"), "A verdade")


func test_interpretador_testes_e_moradores_respondem() -> void:
	var s := _sessao(Gerador.gerar(12))
	var jogo := Interpretador.new(s, _criaturas(), Catalogo.carregar_textos_marcas()["dados"])
	for comando in ["moradores", "testes", "testar t1 m1", "testar t2 l2"]:
		var resposta := jogo.executar(comando)
		if resposta.is_empty() or resposta.begins_with("Não entendi") or resposta.begins_with("Não deu"):
			fail("comando '%s': %s" % [comando, resposta])


func test_todos_os_testes_de_campo_do_design_existem() -> void:
	var ids := []
	for t in _cfg()["testes"]:
		ids.append(t["id"])
	for id in ["graos_na_porta", "espelho_ou_camera", "linha_de_sal", "oferenda", "ferimento_revelador", "agua_benta", "medidor_emf", "camera_termica"]:
		assert_has(ids, id)


func test_graos_e_espelho_dao_negativo_para_as_criaturas_do_corte_vertical() -> void:
	var verdade := {"hospedeiro": "npc_1", "locais": ["valongo/largo"]}
	for id in GRAOS_E_ESPELHO:
		for especie in CORTE_VERTICAL:
			assert_false(Regras.positivo(_teste(id), _criaturas()[especie], verdade, "npc_1"), "%s em %s" % [id, especie])


func test_graos_e_espelho_pegam_o_strigoi_que_vive_como_morador() -> void:
	var verdade := {"hospedeiro": "npc_7", "locais": ["centro/praca_maua"]}
	for id in GRAOS_E_ESPELHO:
		assert_true(Regras.positivo(_teste(id), _criaturas()["strigoi"], verdade, "npc_7"), "%s no strigoi" % id)
		assert_false(Regras.positivo(_teste(id), _criaturas()["strigoi"], verdade, "npc_8"), "%s num inocente" % id)


func test_camera_termica_ve_o_corpo_seco_frio_so_nos_lugares_dele() -> void:
	var termica := _teste("camera_termica")
	var verdade := {"hospedeiro": "", "locais": ["valongo/largo"]}
	var c := _criaturas()
	assert_true(Regras.positivo(termica, c["corpo_seco"], verdade, "valongo/largo"), "morto-vivo não tem calor")
	assert_false(Regras.positivo(termica, c["corpo_seco"], verdade, "valongo/padaria"), "lugar onde ele não vai")
	for id in ["lobisomem_br", "mula_sem_cabeca", "curupira", "golpe_humano"]:
		assert_false(Regras.positivo(termica, c[id], verdade, "valongo/largo"), "%s tem corpo quente" % id)


func test_emf_pega_a_entidade_e_nao_o_corpo() -> void:
	var emf := _teste("medidor_emf")
	var verdade := {"hospedeiro": "", "locais": ["valongo/encosta_monte_serrat"]}
	var c := _criaturas()
	assert_true(Regras.positivo(emf, c["curupira"], verdade, "valongo/encosta_monte_serrat"), "o Curupira é entidade")
	for id in ["corpo_seco", "lobisomem_br", "mula_sem_cabeca", "golpe_humano"]:
		assert_false(Regras.positivo(emf, c[id], verdade, "valongo/encosta_monte_serrat"), "%s é corpóreo" % id)


func test_sessao_faz_os_testes_novos_e_o_tempo_anda() -> void:
	var caso := _primeiro_caso("corpo_seco")
	var s := _sessao(caso)
	var antes: int = s.minuto
	var r: Dictionary = s.aplicar_teste("camera_termica", caso["verdade"]["locais"][0])
	assert_true(r["ok"], str(r.get("erro", "")))
	assert_true(r["positivo"], "a térmica pega o corpo-seco")
	assert_true(s.minuto > antes, "esperou a hora certa")
