extends "res://tests/framework/test_case.gd"
## Fase 4: dinheiro, reputação, 3 níveis de qualidade, motel e carro fixo (docs/08).

const Progresso := preload("res://core/progressao/progresso.gd")
const Arsenal := preload("res://core/confronto/arsenal.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_progressao()["dados"]


func _p() -> RefCounted:
	return Progresso.new(_cfg())


func _melhoria(id: String) -> Dictionary:
	for m in _cfg()["melhorias"]:
		if m["id"] == id:
			return m
	return {}


func test_progressao_config_e_valida_e_a_loja_vende_itens_que_existem() -> void:
	assert_eq(Catalogo.carregar_config_progressao()["erros"], [] as Array[String])
	var itens: Dictionary = Catalogo.carregar_itens()["dados"]
	for o in _cfg()["loja"]:
		assert_true(itens.has(o["item"]), o["item"])
	assert_eq(_cfg()["qualidade"]["niveis"].size(), 3, "3 níveis no corte vertical")


func test_comeca_com_dinheiro_e_desconhecido() -> void:
	var p := _p()
	assert_eq(p.dinheiro, int(_cfg()["dinheiro_inicial"]))
	assert_eq(p.nivel_de_reputacao(), "Desconhecido")


func test_gastar_sem_ter_nao_deixa_e_tudo_vai_para_o_extrato() -> void:
	var p := _p()
	assert_false(p.gastar(p.dinheiro + 1, "algo caro"))
	assert_true(p.gastar(100, "velas"))
	p.ganhar(50, "bico")
	assert_eq(p.extrato, [{"valor": -100, "motivo": "velas"}, {"valor": 50, "motivo": "bico"}] as Array[Dictionary])


func test_caso_resolvido_no_prazo_paga_com_bonus_e_sobe_a_reputacao() -> void:
	var p := _p()
	var antes: int = p.dinheiro
	var r: Dictionary = p.fechar_caso({"resolucao": "banir", "sucesso": true, "recompensa": 600}, {"recompensa": 600})
	assert_eq(r["dinheiro"], 600 + 120 + 90)
	assert_eq(p.dinheiro, antes + 810)
	assert_eq(p.reputacao, 10 + 3 + 3)


func test_fora_do_prazo_sem_pagamento_e_inocente_derruba_a_reputacao() -> void:
	var p := _p()
	p.reputacao = 30
	var r: Dictionary = p.fechar_caso({"resolucao": "matar", "sucesso": true, "recompensa": 0, "inocente_prejudicado": "npc_3"}, {"recompensa": 600})
	assert_eq(r["dinheiro"], 0)
	assert_eq(p.reputacao, 30 + 10 - 15)
	var q := _p()
	q.fechar_caso({"resolucao": "abandonar"}, {"recompensa": 600})
	assert_eq(q.reputacao, 0, "não fica negativa")


func test_reputacao_sobe_de_nivel() -> void:
	var p := _p()
	for i in 2:
		p.fechar_caso({"resolucao": "banir", "sucesso": true, "recompensa": 100}, {"recompensa": 100})
	assert_eq(p.nivel_de_reputacao(), "Conhecido")


func test_melhoria_exige_dinheiro_reputacao_e_o_nivel_anterior() -> void:
	var p := _p()
	assert_eq(p.pode_comprar(_melhoria("espingarda_profissional"))["motivo"], "precisa do nível anterior")
	assert_true(p.comprar_melhoria(_melhoria("espingarda_comum"))["ok"])
	assert_eq(p.nome_da_qualidade("espingarda_de_sal"), "Comum")
	p.ganhar(5000, "teste")
	assert_has(p.pode_comprar(_melhoria("espingarda_profissional"))["motivo"], "reputação")
	p.reputacao = 60
	assert_true(p.comprar_melhoria(_melhoria("espingarda_profissional"))["ok"])
	assert_eq(p.pode_comprar(_melhoria("espingarda_profissional"))["motivo"], "já tem")


func test_qualidade_melhor_mira_melhor_e_recarrega_mais_rapido() -> void:
	var p := _p()
	var improvisada: Dictionary = p.multiplicadores_da_arma("espingarda_de_sal")
	p.qualidade["espingarda_de_sal"] = 3
	var profissional: Dictionary = p.multiplicadores_da_arma("espingarda_de_sal")
	assert_true(profissional["dispersao"] < improvisada["dispersao"])
	assert_true(profissional["recarga"] < improvisada["recarga"])
	var a := Arsenal.new(Catalogo.carregar_config_armas()["dados"], Rng.new(1).stream("armas"))
	a.qualidade["espingarda_de_sal"] = profissional
	a.disparar(Vector3.FORWARD, Vector3.ZERO, 0.0)
	a.recarregar()
	assert_almost_eq(a.recarregando, 2.5 * float(profissional["recarga"]), 0.001)


# --- Na cidade ---

func _cena() -> Node3D:
	var cena := Cena.new()
	cena.montar("valongo", 1)
	return cena


func test_mochila_melhor_fica_maior_e_guarda_o_que_tinha() -> void:
	var cena := _cena()
	var tinha: int = cena.mochila.entradas.size()
	cena.progresso.ganhar(5000, "teste")
	cena.progresso.reputacao = 20
	assert_true(cena.progresso.comprar_melhoria(_melhoria("mochila_profissional"))["ok"])
	cena._aplicar_qualidade()
	assert_eq(Vector2i(cena.mochila.largura, cena.mochila.altura), Vector2i(9, 6))
	assert_eq(cena.mochila.entradas.size(), tinha)
	cena.free()


func _cena_na_arvore() -> Node3D:
	var cena := _cena()
	(Engine.get_main_loop() as SceneTree).root.add_child(cena)
	return cena


func _soltar(cena: Node3D) -> void:
	cena.get_parent().remove_child(cena)
	cena.free()


func test_entrar_dirigir_gastar_gasolina_e_sair() -> void:
	var cena := _cena_na_arvore()
	assert_true(cena.entrar_no_carro())
	assert_true(cena.dirigindo)
	assert_false(cena.cacador.visible)
	var antes: Vector3 = cena.carro.position
	var litros: float = cena.carro.litros
	cena.carro.dirigir(Vector2(0, 1), 0.0)
	cena.carro.velocidade = 10.0
	cena.carro.litros = litros
	var andou: float = 0.0
	for i in 30:
		andou += cena.carro.dirigir(Vector2(0, 1), 0.1)
	assert_true(andou > 5.0, "andou %.1f m" % andou)
	assert_true(cena.carro.litros < litros, "gastou gasolina")
	cena.sair_do_carro()
	assert_false(cena.dirigindo)
	assert_true(cena.cacador.visible)
	assert_true(cena.carro.position.distance_to(antes) > 1.0)
	_soltar(cena)


func test_sem_gasolina_nao_anda() -> void:
	var cena := _cena_na_arvore()
	cena.entrar_no_carro()
	cena.carro.litros = 0.0
	var andou: float = 0.0
	for i in 20:
		andou += cena.carro.dirigir(Vector2(0, 1), 0.1)
	assert_almost_eq(andou, 0.0, 0.01)
	_soltar(cena)


func _no_motel(cena: Node3D) -> void:
	var porta: Vector2 = cena.porta_do_motel()
	cena.cacador.position = Vector3(porta.x, 0.3, porta.y)


func test_motel_fica_no_centro_e_abre_o_menu_perto_da_porta() -> void:
	var cena := _cena()
	assert_ne(cena.porta_do_motel(), Vector2.INF, "o motel do Centro está carregado")
	assert_false(cena.abrir_motel(), "longe, não abre")
	_no_motel(cena)
	assert_true(cena.abrir_motel())
	assert_true(cena.motel_tela.visible)
	cena.fechar_motel()
	cena.free()


func test_descansar_passa_o_tempo_cura_um_grau_e_cobra_a_diaria() -> void:
	var cena := _cena()
	_no_motel(cena)
	cena.ferimentos.receber("perna_direita", "grave")
	cena.medo.valor = 50.0
	var minuto: int = cena.minuto
	var dinheiro: int = cena.progresso.dinheiro
	assert_true(cena.descansar())
	assert_eq(cena.minuto - minuto, int(_cfg()["motel"]["horas_de_sono"]) * 60)
	assert_eq(cena.ferimentos.texto(), "perna direita (leve)")
	assert_eq(cena.medo.valor, 0.0)
	assert_eq(cena.progresso.dinheiro, dinheiro - int(_cfg()["motel"]["diaria"]))
	cena.progresso.dinheiro = 0
	assert_false(cena.descansar(), "sem dinheiro, sem quarto")
	cena.free()


func test_encomenda_chega_na_guarda_do_motel_e_cobra() -> void:
	var cena := _cena()
	_no_motel(cena)
	cena.abrir_motel()
	cena.escolher_no_motel(2)
	assert_eq(cena.menu_do_motel, "suprimentos")
	var dinheiro: int = cena.progresso.dinheiro
	cena.escolher_no_motel(0)
	assert_eq(cena.guarda_do_motel.quantidade("cartucho_de_sal"), 8)
	assert_eq(cena.progresso.dinheiro, dinheiro - int(_cfg()["loja"][0]["preco"]))
	cena.free()


func test_no_motel_a_mochila_abre_ao_lado_da_guarda() -> void:
	var cena := _cena()
	_no_motel(cena)
	cena.abrir_motel()
	cena.escolher_no_motel(1)
	assert_true(cena.mochila_tela.visible)
	assert_eq(cena.outra_grade(), cena.guarda_do_motel)
	assert_eq(cena.nome_da_outra(), "MOTEL")
	cena.fechar_mochila()
	cena.free()


func test_abastecer_so_com_o_carro_perto_do_motel() -> void:
	var cena := _cena()
	_no_motel(cena)
	cena.carro.litros = 5.0
	assert_false(cena.abastecer(), "o carro ficou longe")
	var porta: Vector2 = cena.porta_do_motel()
	cena.carro.position = Vector3(porta.x + 3.0, 0.05, porta.y)
	var dinheiro: int = cena.progresso.dinheiro
	assert_true(cena.abastecer())
	assert_almost_eq(cena.carro.litros, float(_cfg()["carro"]["tanque_litros"]), 0.01)
	assert_eq(cena.progresso.dinheiro, dinheiro - 35 * int(_cfg()["carro"]["preco_do_litro"]))
	cena.free()


func test_hud_mostra_dinheiro_e_reputacao() -> void:
	var cena := _cena()
	assert_has(cena.texto_do_hud(), "R$ %d · Desconhecido" % int(_cfg()["dinheiro_inicial"]))
	cena.free()


# --- Viagem rápida no carro ---

func test_mapa_de_viagem_so_abre_dentro_do_carro() -> void:
	var cena := _cena()
	assert_false(cena.abrir_mapa_de_viagem())
	assert_false(cena.viagem_tela.visible)
	cena.entrar_no_carro()
	assert_true(cena.abrir_mapa_de_viagem())
	assert_true(cena.viagem_tela.visible)
	cena.free()


func test_zoom_do_mapa_de_viagem_fica_dentro_do_quadro() -> void:
	var cena := _cena_na_arvore()
	cena.entrar_no_carro()
	cena.abrir_mapa_de_viagem()
	var tela: Control = cena.viagem_tela
	tela.perto = false
	var longe: Rect2 = tela.enquadrar()["area"]
	tela.perto = true
	var e: Dictionary = tela.enquadrar()
	assert_true(e["area"].get_area() < longe.get_area(), "perto mostra menos que a cidade inteira")
	tela.ajustar_quadro()
	assert_true(tela.quadro.clip_contents, "o quadro corta o que passa da borda")
	var r: Rect2 = tela.quadro.get_rect()
	assert_eq(r, e["mapa"], "o quadro é o retângulo do mapa")
	assert_true(r.end.x <= 364.0, "o mapa não invade a lista de destinos")
	cena.fechar_mapa_de_viagem()
	_soltar(cena)


func test_destinos_sao_os_bairros_carregados_e_os_pontos_chave() -> void:
	var cena := _cena()
	cena.entrar_no_carro()
	var nomes: Array = cena.destinos_de_viagem().map(func(d): return d["nome"])
	assert_has(nomes, "Centro")
	assert_has(nomes, "Motel Estrela do Porto (Centro)")
	var unicos := {}
	for n in nomes:
		unicos[n] = true
	assert_eq(unicos.size(), nomes.size(), "nenhum nome repetido")
	for d in cena.destinos_de_viagem():
		assert_true(int(d["minutos"]) >= 1 and float(d["litros"]) >= 0.0)
	cena.free()


func test_viajar_leva_o_carro_passa_o_tempo_e_gasta_gasolina() -> void:
	var cena := _cena()
	cena.entrar_no_carro()
	var destinos: Array = cena.destinos_de_viagem()
	var i := -1
	for j in destinos.size():
		if destinos[j]["nome"] == "Motel Estrela do Porto (Centro)":
			i = j
	var d: Dictionary = destinos[i]
	var minuto: int = cena.minuto
	var litros: float = cena.carro.litros
	assert_true(cena.viajar(i))
	assert_almost_eq(Vector2(cena.carro.position.x, cena.carro.position.z).distance_to(d["ponto"]), 0.0, 0.01)
	assert_eq(cena.minuto - minuto, int(d["minutos"]))
	assert_almost_eq(cena.carro.litros, litros - float(d["litros"]), 0.001)
	assert_eq(str(cena.bairro.dados["id"]), "centro", "chegou no Centro")
	assert_false(cena.viagem_tela.visible)
	cena.free()


func test_sem_gasolina_para_a_viagem_nao_vai() -> void:
	var cena := _cena()
	cena.entrar_no_carro()
	cena.carro.litros = 0.0
	var antes: Vector3 = cena.carro.position
	var longe := -1
	var destinos: Array = cena.destinos_de_viagem()
	for j in destinos.size():
		if float(destinos[j]["litros"]) > 0.0:
			longe = j
	assert_false(cena.viajar(longe))
	assert_eq(cena.carro.position, antes)
	cena.free()


func test_mapa_geral_tem_todas_as_regioes_e_as_liberadas_existem() -> void:
	var r: Dictionary = Catalogo.carregar_mapa_geral()
	assert_eq(r["erros"], [] as Array[String])
	var ids: Array = r["dados"]["regioes"].map(func(x): return x["id"])
	assert_gte(ids.size(), 10, "a cidade inteira, não só o corte vertical")
	for id in _cfg()["regioes_liberadas"]:
		assert_has(ids, id)
	for id in Catalogo.bairros_reais():
		assert_has(ids, id, "todo bairro jogável aparece no mapa geral")


func test_regiao_bloqueada_nao_vira_destino_de_viagem() -> void:
	var cena := Cena.new()
	cena.montar("centro", 1)
	cena.entrar_no_carro()
	var bloqueados: Array = cena.carregados.keys().filter(func(i): return not cena.progresso.liberada(i))
	assert_false(bloqueados.is_empty(), "do Centro, algum vizinho carregado está bloqueado")
	for d in cena.destinos_de_viagem():
		assert_true(cena.progresso.liberada(d["bairro"]), "%s é de região liberada" % d["nome"])
	cena.progresso.regioes_liberadas.append(bloqueados[0])
	var bairros: Array = cena.destinos_de_viagem().map(func(d): return d["bairro"])
	assert_has(bairros, bloqueados[0], "liberou, vira destino")
	cena.free()
