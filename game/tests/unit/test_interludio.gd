extends "res://tests/framework/test_case.gd"
## Fase 4: interlúdio com pulo de tempo curto, médio e longo (docs/02, "Interlúdio").

const Interludio := preload("res://core/progressao/interludio.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_progressao()["dados"]


func _pulo(id: String) -> Dictionary:
	for p in Interludio.pulos(_cfg()):
		if p["id"] == id:
			return p
	return {}


func test_tres_pulos_cada_vez_mais_longos_que_curam_e_treinam_mais() -> void:
	var c := Interludio.efeito(_pulo("curto"), _cfg())
	var m := Interludio.efeito(_pulo("medio"), _cfg())
	var l := Interludio.efeito(_pulo("longo"), _cfg())
	assert_true(c["dias"] < m["dias"] and m["dias"] < l["dias"])
	assert_true(c["cura_graus"] < m["cura_graus"], "o curto quase não sara")
	assert_true(c["treino_xp"] < m["treino_xp"] and m["treino_xp"] < l["treino_xp"])
	assert_true(c["custo"] < m["custo"] and m["custo"] < l["custo"], "mais dias, mais diárias")


func test_idade_conta_os_anos_vividos() -> void:
	assert_eq(Interludio.idade(20, 0), 20)
	assert_eq(Interludio.idade(20, 364), 20)
	assert_eq(Interludio.idade(20, 365), 21)


# --- Na cidade (motel) ---

func _cena() -> Node3D:
	var cena := Cena.new()
	cena.montar("valongo", 1)
	return cena


func test_pulo_medio_sara_treina_passa_o_tempo_e_cobra() -> void:
	var cena := _cena()
	cena.ferimentos.receber("perna_direita", "critico")
	cena.medo.valor = 60.0
	var minuto: int = cena.minuto
	var dinheiro: int = cena.progresso.dinheiro
	var e := Interludio.efeito(_pulo("medio"), _cfg())
	assert_true(cena.pular_o_tempo("medio", "ocultismo"))
	assert_eq(cena.minuto - minuto, int(e["minutos"]))
	assert_eq(cena.ferimentos.texto(), "nenhum", "três semanas saram um crítico")
	assert_eq(cena.medo.valor, 0.0)
	assert_eq(int(cena.habilidades.xp["ocultismo"]), int(e["treino_xp"]))
	assert_eq(int(cena.habilidades.xp["combate"]), 0, "só a árvore escolhida")
	assert_eq(cena.progresso.dinheiro, dinheiro - int(e["custo"]))
	cena.free()


func test_pulo_curto_nao_sara_tudo() -> void:
	var cena := _cena()
	cena.ferimentos.receber("tronco", "critico")
	cena.pular_o_tempo("curto", "combate")
	assert_eq(cena.ferimentos.texto(), "tronco (grave)")
	cena.free()


func test_pulo_longo_envelhece() -> void:
	var cena := _cena()
	cena.progresso.ganhar(10000, "teste")
	var idade: int = cena.progresso.idade()
	for i in 4:
		assert_true(cena.pular_o_tempo("longo", "sobrevivencia"))
	assert_eq(cena.progresso.idade(), idade + 1, "480 dias: um ano a mais")
	assert_has(cena.texto_do_hud(), "%d anos" % (idade + 1))
	assert_eq(cena.progresso.interludios, 4)
	cena.free()


func test_sem_dinheiro_para_as_diarias_nao_pula() -> void:
	var cena := _cena()
	cena.progresso.dinheiro = 10
	var minuto: int = cena.minuto
	assert_false(cena.pular_o_tempo("longo", "combate"))
	assert_eq(cena.minuto, minuto)
	cena.free()


func test_motel_oferece_os_pulos_com_a_arvore_para_treinar() -> void:
	var cena := _cena()
	var porta: Vector2 = cena.porta_do_motel()
	cena.cacador.position = Vector3(porta.x, 0.3, porta.y)
	cena.abrir_motel()
	var principal: Array = cena.opcoes_do_motel()
	var i := principal.map(func(o): return o["acao"]).find("interludio")
	assert_true(i >= 0, "o motel tem o interlúdio")
	cena.escolher_no_motel(i)
	var opcoes: Array = cena.opcoes_do_motel()
	assert_eq(opcoes.size(), 9, "3 pulos x 3 árvores, nas teclas 1 a 9")
	var minuto: int = cena.minuto
	cena.escolher_no_motel(0)
	assert_true(cena.minuto > minuto, "o tempo passou")
	assert_false(cena.motel_tela.visible, "o menu fecha depois do pulo")
	cena.free()
