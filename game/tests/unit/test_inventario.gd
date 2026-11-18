extends "res://tests/framework/test_case.gd"
## Fase 4: mochila em grade e porta-malas (core/inventario/grade.gd, docs/08).

const Grade := preload("res://core/inventario/grade.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")


func _itens() -> Dictionary:
	return Catalogo.carregar_itens()["dados"]


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_inventario()["dados"]


func _grade(l: int = 6, a: int = 4) -> RefCounted:
	return Grade.new(l, a, _itens())


func test_itens_e_inventario_validos_e_conteudo_inicial_existe() -> void:
	assert_eq(Catalogo.carregar_itens()["erros"], [] as Array[String])
	assert_eq(Catalogo.carregar_config_inventario()["erros"], [] as Array[String])
	var itens := _itens()
	for lista in ["mochila_inicial", "porta_malas_inicial"]:
		for c in _cfg()[lista]:
			assert_true(itens.has(c["item"]), "%s existe" % c["item"])
	for arma in _cfg()["municao_das_armas"]:
		assert_true(itens.has(_cfg()["municao_das_armas"][arma]))


func test_cada_item_ocupa_o_formato_e_nao_sobrepoe() -> void:
	var g := _grade()
	assert_gt_zero(g.colocar("correntes", 0, 0, false, 1))
	assert_eq(g.colocar("sal_grosso", 1, 1, false, 1), 0, "em cima das correntes, não")
	assert_gt_zero(g.colocar("sal_grosso", 2, 0, false, 1))
	assert_eq(g.colocar("agua_benta", 5, 3, false, 1), 0, "1x2 não cabe na última linha")
	assert_gt_zero(g.colocar("agua_benta", 4, 3, true, 1), "deitada cabe")


func assert_gt_zero(n: int, msg: String = "") -> void:
	assert_true(n > 0, msg)


func test_adicionar_empilha_e_procura_lugar() -> void:
	var g := _grade()
	assert_eq(g.adicionar("cartucho_de_sal", 20), 0)
	assert_eq(g.quantidade("cartucho_de_sal"), 20)
	assert_eq(g.entradas.size(), 3, "pilhas de 8: 8 + 8 + 4")
	g.adicionar("cartucho_de_sal", 3)
	assert_eq(g.entradas.size(), 3, "completou a pilha que tinha espaço")


func test_grade_cheia_devolve_o_que_nao_coube() -> void:
	var g := _grade(2, 2)
	assert_eq(g.adicionar("correntes", 2), 1, "só cabe uma")


func test_retirar_tira_das_pilhas_e_some_com_a_vazia() -> void:
	var g := _grade()
	g.adicionar("bala_38", 14)
	assert_eq(g.retirar("bala_38", 5), 5)
	assert_eq(g.quantidade("bala_38"), 9)
	assert_eq(g.retirar("bala_38", 50), 9)
	assert_eq(g.entradas.size(), 0)


func test_mover_e_girar_respeitam_a_grade() -> void:
	var g := _grade()
	var n: int = g.colocar("oferenda_fumo_e_cachaca", 0, 0, false, 1)
	assert_true(g.mover(n, 5, 0, true), "em pé na última coluna")
	assert_false(g.mover(n, 5, 3), "deitada não cabe ali")
	assert_eq(g.em(5, 1)["item"], "oferenda_fumo_e_cachaca")


func test_peso_deixa_lento_e_cansado() -> void:
	var leve := Grade.efeito_do_peso(1000, _cfg()["peso"])
	assert_eq(leve["velocidade"], 1.0)
	var pesado := Grade.efeito_do_peso(int(_cfg()["peso"]["pesado_a_partir_g"]) + 5000, _cfg()["peso"])
	assert_almost_eq(pesado["velocidade"], float(_cfg()["peso"]["velocidade_no_pesado"]), 0.001)
	assert_true(pesado["folego"] < 1.0)
	var meio := Grade.efeito_do_peso((int(_cfg()["peso"]["leve_ate_g"]) + int(_cfg()["peso"]["pesado_a_partir_g"])) / 2, _cfg()["peso"])
	assert_true(meio["velocidade"] < 1.0 and meio["velocidade"] > pesado["velocidade"])


func test_frageis_podem_quebrar_e_o_resto_nao() -> void:
	var g := _grade()
	g.adicionar("agua_benta", 1)
	g.adicionar("correntes", 1)
	var quebrados: Array[String] = g.quebrar_frageis(1.0, Rng.new(1).stream("x"))
	assert_eq(quebrados, ["agua_benta"] as Array[String])
	assert_eq(g.quantidade("correntes"), 1)
	assert_eq(g.quebrar_frageis(0.0, Rng.new(1).stream("x")).size(), 0)


# --- Na cidade ---

func _cena() -> Node3D:
	var cena := Cena.new()
	cena.montar("valongo", 1)
	return cena


func test_cidade_comeca_com_mochila_porta_malas_e_carro_perto() -> void:
	var cena := _cena()
	assert_eq(cena.mochila.quantidade("cartucho_de_sal"), 8)
	assert_true(cena.porta_malas.quantidade("correntes") > 0)
	assert_true(cena.perto_do_carro(), "o carro está do lado")
	cena.cacador.position += Vector3(30, 0, 0)
	assert_false(cena.perto_do_carro())
	cena.free()


func test_abrir_a_mochila_leva_tempo_e_trava_o_cacador() -> void:
	var cena := _cena()
	cena.abrir_mochila()
	assert_false(cena.mochila_tela.visible, "ainda abrindo")
	assert_true(cena.cacador.bloqueado)
	cena.passar_tempo(float(_cfg()["abrir_mochila_segundos"]) + 0.1)
	assert_true(cena.mochila_tela.visible, "abriu")
	cena.fechar_mochila()
	assert_false(cena.cacador.bloqueado)
	cena.free()


func test_recarregar_gasta_a_municao_da_mochila_e_sem_ela_nao_recarrega() -> void:
	var cena := _cena()
	cena.arsenal.municao["espingarda_de_sal"] = 0
	assert_true(cena.recarregar_da_mochila())
	assert_eq(cena.mochila.quantidade("cartucho_de_sal"), 6, "tirou 2")
	cena.passar_tempo(4.0)
	assert_eq(cena.arsenal.municao["espingarda_de_sal"], 2)
	cena.mochila.retirar("cartucho_de_sal", 99)
	cena.arsenal.municao["espingarda_de_sal"] = 0
	assert_false(cena.recarregar_da_mochila(), "sem cartucho")
	cena.free()


func test_levar_do_porta_malas_para_a_mochila() -> void:
	var cena := _cena()
	cena.abrir_mochila()
	cena.passar_tempo(2.0)
	cena.trocar_grade()
	assert_eq(cena.grade_aberta(), cena.porta_malas)
	var e: Dictionary = {}
	for x in cena.porta_malas.entradas:
		if x["item"] == "correntes":
			e = x
	cena.cursor = Vector2i(e["x"], e["y"])
	cena.pegar_ou_soltar()
	assert_eq(cena.na_mao["item"], "correntes")
	cena.trocar_grade()
	assert_eq(cena.grade_aberta(), cena.mochila)
	var lugar: Dictionary = cena.mochila.achar_lugar("correntes")
	cena.cursor = Vector2i(lugar["x"], lugar["y"])
	if lugar["girado"]:
		cena.girar_na_mao()
	cena.pegar_ou_soltar()
	assert_true(cena.na_mao.is_empty())
	assert_eq(cena.mochila.quantidade("correntes"), 1)
	assert_eq(cena.porta_malas.quantidade("correntes"), 0)
	cena.free()


func test_mochila_pesada_deixa_o_cacador_lento() -> void:
	var cena := _cena()
	cena.passar_tempo(0.1)
	var antes: float = cena.cacador.modificadores["velocidade"]
	cena.mochila.adicionar("correntes", 3)
	cena.passar_tempo(0.1)
	assert_true(cena.cacador.modificadores["velocidade"] < antes)
	cena.free()


func test_por_no_bolso_passa_uma_unidade() -> void:
	var cena := _cena()
	var e: Dictionary = {}
	for x in cena.mochila.entradas:
		if x["item"] == "vela":
			e = x
	cena.cursor = Vector2i(e["x"], e["y"])
	var antes: int = cena.bolsos.quantidade("vela")
	assert_true(cena.por_no_bolso())
	assert_eq(cena.bolsos.quantidade("vela"), antes + 1)
	assert_eq(cena.mochila.quantidade("vela"), 3)
	cena.free()


func test_golpe_grave_pode_quebrar_o_que_e_fragil_na_mochila() -> void:
	var cena := _cena()
	cena._cfg_inventario["chance_de_quebrar_fragil"] = 1.0
	cena.trazer_criatura("lobisomem_br")
	cena.criatura.estado.agressividade = 3
	cena.criatura._cfg["chance_de_grave"] = 1.0
	for i in 120:
		cena.passar_tempo(0.1)
	assert_eq(cena.mochila.quantidade("agua_benta"), 0, "a água benta quebrou")
	assert_eq(cena.mochila.quantidade("vela"), 4, "vela não quebra")
	cena.free()


# --- Estilo maleta (RE4) ---

func test_mochila_e_sempre_menor_que_o_porta_malas() -> void:
	var p: Dictionary = _cfg()["porta_malas"]
	for m in Catalogo.carregar_config_progressao()["dados"]["qualidade"]["mochila"]:
		assert_true(int(m[0]) <= int(p["largura"]) and int(m[1]) <= int(p["altura"]), "mochila %s não passa em nenhum lado" % str(m))
		assert_true(int(m[0]) * int(m[1]) < int(p["largura"]) * int(p["altura"]), "mochila %s tem menos casas" % str(m))


func test_armas_ocupam_espaco_na_grade() -> void:
	var itens := _itens()
	for id in Catalogo.carregar_config_armas()["dados"]["armas"].map(func(a): return a["id"]):
		if int(Catalogo.carregar_config_armas()["dados"]["armas"].filter(func(a): return a["id"] == id)[0]["capacidade"]) == 0:
			continue
		assert_true(itens.has(id), "%s é item" % id)
		assert_eq(itens[id]["arma"], id)
		assert_true(int(itens[id]["formato"][0]) * int(itens[id]["formato"][1]) >= 4, "arma de fogo é grande")


func test_organizar_junta_tudo_no_canto() -> void:
	var g := _grade(8, 5)
	g.colocar("correntes", 6, 3, false, 1)
	g.colocar("sal_grosso", 3, 2, false, 1)
	g.colocar("espingarda_de_sal", 0, 3, false, 1)
	assert_true(g.organizar())
	assert_eq(g.em(0, 0)["item"], "espingarda_de_sal", "o maior primeiro")
	assert_eq(g.quantidade("sal_grosso"), 1)
	assert_eq(g.quantidade("correntes"), 1)
	assert_eq(g.ocupado(), 10 + 4 + 1)


func test_organizar_que_nao_cabe_deixa_como_estava() -> void:
	var g := _grade(3, 2)
	g.colocar("vela", 0, 0, false, 1)
	g.colocar("correntes", 1, 0, false, 1)
	var antes: Array = g.entradas.duplicate(true)
	g._defs = g._defs.duplicate(true)
	g._defs["vela"] = g._defs["vela"].duplicate()
	g._defs["vela"]["formato"] = [2, 2]
	assert_false(g.organizar())
	assert_eq(g.entradas, antes)


func test_arma_no_porta_malas_nao_pode_ser_usada() -> void:
	var cena := _cena()
	assert_eq(cena.arsenal.equipada, "espingarda_de_sal")
	assert_true(cena.equipar("revolver"))
	var e: Dictionary = {}
	for x in cena.mochila.entradas:
		if x["item"] == "revolver":
			e = x
	cena.porta_malas.adicionar("revolver", 1)
	cena.mochila.tirar_entrada(e["n"])
	cena.fechar_mochila()
	assert_eq(cena.arsenal.equipada, "faca", "sem o revólver na mochila, fica a faca")
	assert_false(cena.equipar("revolver"))
	assert_true(cena.equipar("espingarda_de_sal"))
	cena.free()


func test_cursor_passa_da_mochila_para_o_porta_malas_lado_a_lado() -> void:
	var cena := _cena()
	cena.abrir_mochila()
	cena.passar_tempo(2.0)
	cena.cursor = Vector2i(cena.mochila.largura - 1, 2)
	cena.mover_cursor(Vector2i(1, 0))
	assert_eq(cena.foco, "outra")
	assert_eq(cena.grade_aberta(), cena.porta_malas)
	assert_eq(cena.cursor, Vector2i(0, 2))
	cena.mover_cursor(Vector2i(-1, 0))
	assert_eq(cena.foco, "mochila")
	assert_eq(cena.cursor, Vector2i(cena.mochila.largura - 1, 2))
	cena.cacador.position += Vector3(30, 0, 0)
	cena.cursor = Vector2i(cena.mochila.largura - 1, 2)
	cena.mover_cursor(Vector2i(1, 0))
	assert_eq(cena.foco, "mochila", "longe do carro, não tem porta-malas")
	cena.free()


func test_item_na_mao_nao_cabe_em_cima_de_outro() -> void:
	var cena := _cena()
	cena.abrir_mochila()
	cena.passar_tempo(2.0)
	cena.apontar("mochila", Vector2i(0, 0))
	cena.pegar_ou_soltar()
	assert_eq(cena.na_mao["item"], "espingarda_de_sal")
	var r: Dictionary = {}
	for x in cena.mochila.entradas:
		if x["item"] == "revolver":
			r = x
	cena.apontar("mochila", Vector2i(r["x"], r["y"]))
	cena.pegar_ou_soltar()
	assert_eq(cena.na_mao["item"], "espingarda_de_sal", "não soltou em cima do revólver")
	cena.fechar_mochila()
	assert_eq(cena.mochila.quantidade("espingarda_de_sal"), 1, "ao fechar, volta para a mochila")
	cena.free()
