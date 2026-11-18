extends "res://tests/framework/test_case.gd"
## Fase 4: 3 árvores de habilidades humanas, pela prática e com teto (docs/12, Parte A).

const Habilidades := preload("res://core/progressao/habilidades.gd")
const Ritual := preload("res://core/confronto/ritual.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_habilidades()["dados"]


func _h() -> RefCounted:
	return Habilidades.new(_cfg())


## Dá experiência até ter n pontos livres na árvore.
func _pontos(h: RefCounted, acao: String, n: int) -> void:
	var arvore: String = _cfg()["xp"][acao]["arvore"]
	while h.pontos_livres(arvore) < n:
		h.praticar(acao)


func test_habilidades_config_e_valida_com_3_arvores_e_acoes_de_arvores_que_existem() -> void:
	assert_eq(Catalogo.carregar_config_habilidades()["erros"], [] as Array[String])
	var arvores: Array = _cfg()["arvores"].map(func(a): return a["id"])
	assert_eq(arvores.size(), 3)
	for acao in _cfg()["xp"]:
		assert_has(arvores, _cfg()["xp"][acao]["arvore"])


func test_praticar_da_experiencia_e_vira_ponto() -> void:
	var h := _h()
	assert_eq(h.pontos_livres("combate"), 0)
	var ganhou := false
	for i in 5:
		ganhou = h.praticar("acerto") or ganhou
	assert_true(ganhou, "5 acertos de 2 xp = 1 ponto")
	assert_eq(h.pontos_livres("combate"), 1)
	assert_eq(h.pontos_livres("ocultismo"), 0, "cada árvore pela sua prática")


func test_sem_ponto_nao_aprende_e_com_ponto_aprende() -> void:
	var h := _h()
	assert_false(h.aprender("pontaria")["ok"])
	_pontos(h, "acerto", 1)
	assert_true(h.aprender("pontaria")["ok"])
	assert_eq(h.niveis["pontaria"], 1)
	assert_almost_eq(h.efeito("dispersao"), 0.85, 0.001)


func test_nivel_maximo_e_teto_total() -> void:
	var h := _h()
	_pontos(h, "acerto", 9)
	assert_true(h.aprender("pontaria")["ok"])
	assert_true(h.aprender("pontaria")["ok"])
	assert_eq(h.aprender("pontaria")["motivo"], "já está no máximo")
	_pontos(h, "passo_de_ritual", 9)
	_pontos(h, "golpe_recebido", 9)
	var aprendidas := 2
	for id in ["recarga_rapida", "sangue_frio", "maos_firmes", "concentracao", "palavras_certas", "primeiros_socorros", "resistencia", "folego"]:
		for k in 2:
			if h.aprender(id)["ok"]:
				aprendidas += 1
	assert_eq(aprendidas, int(_cfg()["teto_de_pontos"]), "não dá para maximizar tudo")
	assert_has(h.pode_aprender("folego")["motivo"] + h.pode_aprender("resistencia")["motivo"], "teto")


func test_efeitos_somam_quantidades_e_multiplicam_o_resto() -> void:
	var h := _h()
	assert_eq(h.efeito("perdoa_palavra"), 0.0)
	assert_eq(h.efeito("medo"), 1.0)
	_pontos(h, "passo_de_ritual", 1)
	h.aprender("palavras_certas")
	assert_eq(h.efeito("perdoa_palavra"), 1.0)


func test_ritual_perdoa_uma_palavra_errada() -> void:
	var cfg: Dictionary = Catalogo.carregar_config_rituais()["dados"]
	var def: Dictionary = cfg["rituais"][0]
	var r := Ritual.new(def, cfg, Rng.new(1).stream("r"))
	r.perdoes = 1
	r.tentar(r.centro, 0.0, 0.0)
	r.tentar(r.centro, 0.0, 0.0)
	var certa: int = def["passos"][2]["certa"]
	assert_false(r.escolher((certa + 1) % 3))
	assert_eq(r.situacao, Ritual.ANDANDO, "a primeira errada passa")
	assert_false(r.escolher((certa + 1) % 3))
	assert_eq(r.situacao, Ritual.FALHOU, "a segunda não")


# --- Na cidade ---

func _cena() -> Node3D:
	var cena := Cena.new()
	cena.montar("valongo", 1)
	return cena


func _indice(cena: Node3D, id: String) -> int:
	var i := 0
	for a in cena.habilidades.arvores():
		for h in a["habilidades"]:
			if h["id"] == id:
				return i
			i += 1
	return -1


func test_pontaria_e_recarga_rapida_mexem_no_arsenal() -> void:
	var cena := _cena()
	_pontos(cena.habilidades, "acerto", 2)
	assert_true(cena.aprender_habilidade(_indice(cena, "pontaria"))["ok"])
	assert_true(cena.aprender_habilidade(_indice(cena, "recarga_rapida"))["ok"])
	assert_almost_eq(float(cena.arsenal.habilidade["dispersao"]), 0.85, 0.001)
	cena.arsenal.municao["espingarda_de_sal"] = 0
	cena.recarregar_da_mochila()
	var esperado: float = 2.5 * float(cena.arsenal.qualidade["espingarda_de_sal"]["recarga"]) * 0.85
	assert_almost_eq(cena.arsenal.recarregando, esperado, 0.001)
	cena.free()


func test_sangue_frio_segura_o_medo() -> void:
	var calmo := _cena()
	var normal := _cena()
	_pontos(calmo.habilidades, "acerto", 1)
	calmo.aprender_habilidade(_indice(calmo, "sangue_frio"))
	for c in [calmo, normal]:
		c.zona = "esgoto"
		c.cacador.lanterna.visible = false
		c.passar_tempo(30.0)
	assert_true(calmo.medo.valor < normal.medo.valor)
	calmo.free()
	normal.free()


func test_primeiros_socorros_trata_um_grau_a_mais_e_resistencia_segura_o_critico() -> void:
	var cena := _cena()
	_pontos(cena.habilidades, "golpe_recebido", 2)
	cena.aprender_habilidade(_indice(cena, "primeiros_socorros"))
	cena.aprender_habilidade(_indice(cena, "resistencia"))
	cena.ferimentos.receber("tronco", "critico")
	assert_almost_eq(cena.ferimentos.tempo_ate_morrer(), 90.0 * 1.5, 0.01)
	var i := -1
	for j in cena.bolsos.itens.size():
		if cena.bolsos.itens[j]["item"] == "bandagem":
			i = j
	cena.usar_bolso(i)
	assert_eq(cena.ferimentos.texto(), "tronco (leve)", "crítico -> leve com uma bandagem")
	cena.free()


func test_concentracao_e_maos_firmes_facilitam_o_ritual() -> void:
	var cena := _cena()
	cena.trazer_criatura("corpo_seco")
	cena.criatura.position = cena.cacador.position + Vector3(1.5, -cena.cacador.position.y, 0)
	cena.criatura.estado.estado = "contida"
	cena.criatura.estado.restante = 999.0
	_pontos(cena.habilidades, "passo_de_ritual", 2)
	cena.aprender_habilidade(_indice(cena, "maos_firmes"))
	cena.aprender_habilidade(_indice(cena, "concentracao"))
	cena.abrir_rituais()
	assert_true(cena.comecar_ritual(0))
	var base: Dictionary = Catalogo.carregar_config_rituais()["dados"]
	var normal := Ritual.new(base["rituais"][0], base, Rng.new(1).stream("r"))
	assert_true(cena.ritual.largura(0.0) > normal.largura(0.0), "faixa maior")
	assert_true(cena.ritual.marcador(0.5) < normal.marcador(0.5), "marcador mais lento")
	cena.free()


func test_acertar_tiro_e_levar_golpe_dao_experiencia() -> void:
	var cena := _cena()
	cena.trazer_criatura("lobisomem_br")
	for i in 60:
		cena.passar_tempo(0.1)
	assert_true(int(cena.habilidades.xp["sobrevivencia"]) > 0, "levar golpe ensina")
	cena.free()
