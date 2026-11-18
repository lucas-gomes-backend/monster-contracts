extends "res://tests/framework/test_case.gd"
## Fase 4: a condição Sensitivo (core/condicoes, docs/12 Parte B).

const Condicao := preload("res://core/condicoes/condicao.gd")
const Psicometria := preload("res://core/condicoes/psicometria.gd")
const Gerador := preload("res://core/casos/gerador_casos.gd")
const Sessao := preload("res://core/investigacao/sessao.gd")
const Interpretador := preload("res://ui/texto/interpretador.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_condicoes()["dados"]


func _sensitivo() -> RefCounted:
	var c := Condicao.new(_cfg())
	c.adquirir("sensitivo")
	return c


func _ficha(id: String) -> Dictionary:
	return Catalogo.carregar_criaturas()["criaturas"][id]


func test_condicoes_config_e_valida() -> void:
	assert_eq(Catalogo.carregar_config_condicoes()["erros"], [] as Array[String])


func test_uma_condicao_por_vez() -> void:
	var c := Condicao.new(_cfg())
	assert_false(c.tem())
	assert_true(c.adquirir("sensitivo")["ok"])
	var de_novo: Dictionary = c.adquirir("sensitivo")
	assert_false(de_novo["ok"])
	assert_has(de_novo["motivo"], "uma condição por vez")


func test_sente_a_presenca_de_entidade_nao_de_corpo_e_so_no_alcance() -> void:
	var c := _sensitivo()
	var alcance: float = _cfg()["sensitivo"]["estagios"][0]["alcance_da_presenca"]
	assert_true(c.sente(_ficha("curupira"), alcance - 1.0), "o Curupira é entidade")
	assert_false(c.sente(_ficha("curupira"), alcance + 1.0), "longe demais")
	assert_false(c.sente(_ficha("corpo_seco"), 2.0), "corpo-seco é corpo")
	assert_false(Condicao.new(_cfg()).sente(_ficha("curupira"), 2.0), "sem o dom, nada")


func test_estagio_sobe_com_o_uso_e_aumenta_o_alcance() -> void:
	var c := _sensitivo()
	assert_eq(c.estagio()["nome"], "Recente")
	var subiu := false
	for i in int(_cfg()["sensitivo"]["estagios"][1]["a_partir_de_usos"]):
		subiu = c.usar_poder() or subiu
	assert_true(subiu)
	assert_eq(c.estagio()["nome"], "Controlado")
	assert_true(c.sente(_ficha("curupira"), float(_cfg()["sensitivo"]["estagios"][0]["alcance_da_presenca"]) + 5.0))


func test_espiritos_cansam_protecao_corta_e_sem_eles_descansa() -> void:
	var a := _sensitivo()
	var b := _sensitivo()
	a.passar(5.0, 2, false)
	b.passar(5.0, 2, true)
	assert_true(a.exaustao > 0.0)
	assert_almost_eq(b.exaustao, a.exaustao / 2.0, 0.001, "figa e arruda cortam pela metade")
	var antes: float = a.exaustao
	a.passar(5.0, 0, false)
	assert_true(a.exaustao < antes)


func test_no_maximo_algo_toma_o_corpo_por_um_tempo() -> void:
	var c := _sensitivo()
	var comecou := false
	for i in 200:
		if c.passar(0.5, 3, false):
			comecou = true
			break
	assert_true(comecou)
	assert_true(c.possuido())
	assert_almost_eq(c.exaustao, float(_cfg()["sensitivo"]["exaustao_depois_da_possessao"]), 0.001)
	c.passar(float(_cfg()["sensitivo"]["possessao_segundos"]) + 0.1, 0, false)
	assert_false(c.possuido(), "passa")


# --- Psicometria no caderno ---

func _sessao(semente: int = 1) -> RefCounted:
	var caso := Gerador.gerar(semente)
	return Sessao.new(caso, Catalogo.carregar_criaturas()["criaturas"], Catalogo.carregar_bairro(caso["bairro"])["dados"], Catalogo.carregar_config_investigacao()["dados"])


func _anotar_uma_marca(s: RefCounted) -> Dictionary:
	for p in s.caso["pistas"]:
		if p["tipo"] == "marca":
			s.caderno.anotar_pista(p)
			return p
	return {}


func test_so_o_sensitivo_toca_e_a_visao_e_vaga() -> void:
	var s := _sessao()
	var p := _anotar_uma_marca(s)
	assert_false(p.is_empty())
	assert_false(s.tocar(p["id"])["ok"], "sem o dom, nada")
	s.sensitivo = true
	var minuto: int = s.minuto
	var r: Dictionary = s.tocar(p["id"])
	assert_true(r["ok"])
	var o: Dictionary = Psicometria.observavel(s.caso, p, Catalogo.carregar_criaturas()["criaturas"], Catalogo.carregar_config_casos()["dados"])
	assert_has(r["visao"], str(o["som"]), "ouve o som")
	assert_false(str(o["forma"]) in r["visao"], "não vê a forma (não dá a resposta)")
	assert_eq(s.minuto - minuto, 20)
	assert_false(s.tocar(p["id"])["ok"], "cada pista uma vez")


func test_comando_tocar_no_jogo_em_texto() -> void:
	var s := _sessao()
	_anotar_uma_marca(s)
	s.sensitivo = true
	var jogo := Interpretador.new(s, Catalogo.carregar_criaturas()["criaturas"], Catalogo.carregar_textos_marcas()["dados"])
	assert_has(jogo.executar("tocar p1"), "Você ouve")


# --- Na cidade ---

func _cena() -> Node3D:
	var cena := Cena.new()
	cena.montar("valongo", 1)
	return cena


func _na_benzedeira(cena: Node3D) -> void:
	for b in cena.populacoes:
		for ponto in cena.populacoes[b].pontos_chave:
			if ponto["tipo"] == "benzedeira":
				cena.cacador.position = Vector3(ponto["porta"].x, 0.3, ponto["porta"].y)
				return


func test_benzedeira_abre_os_olhos_depois_de_avisar() -> void:
	var cena := _cena()
	assert_false(cena.abrir_benzedeira(), "longe")
	_na_benzedeira(cena)
	assert_true(cena.abrir_benzedeira())
	cena.escolher_no_motel(0)
	assert_eq(cena.menu_do_motel, "benzedeira_aviso", "avisa antes")
	assert_false(cena.condicao.tem())
	cena.escolher_no_motel(0)
	assert_true(cena.condicao.sensitivo())
	cena.abrir_benzedeira()
	var textos: Array = cena.opcoes_do_motel().map(func(o): return o["texto"])
	for t in textos:
		assert_false("Sensitivo" in t, "não oferece de novo")
	cena.free()


func test_so_o_sensitivo_ve_os_espiritos_e_eles_incomodam() -> void:
	var cena := _cena()
	for i in 20:
		cena.passar_tempo(0.5)
	assert_true(cena.espiritos == null or not cena.espiritos.visible, "sem o dom, não há espíritos")
	cena.condicao.adquirir("sensitivo")
	for i in 60:
		cena.passar_tempo(0.5)
	assert_true(cena.espiritos.visible)
	assert_eq(cena.espiritos.espiritos.size(), int(_cfg()["sensitivo"]["estagios"][0]["espiritos"]))
	assert_true(cena.condicao.exaustao > 0.0, "cansa")
	assert_true(cena.medo.valor > 0.0, "assusta")
	cena.free()


func test_circulo_de_sal_segura_os_espiritos() -> void:
	var cena := _cena()
	cena.condicao.adquirir("sensitivo")
	cena.usar_bolso(0)
	for i in 80:
		cena.passar_tempo(0.5)
	assert_eq(cena.condicao.exaustao, 0.0, "dentro do sal, eles não alcançam")
	cena.free()


func test_sente_o_curupira_sem_dizer_o_que_e_e_nao_sente_o_corpo_seco() -> void:
	var cena := _cena()
	cena.condicao.adquirir("sensitivo")
	cena.trazer_criatura("curupira")
	assert_has(cena.texto_da_presenca(), "Presença")
	assert_has(cena.texto_do_hud(), "Sensitivo (Recente)")
	assert_false("Curupira" in cena.texto_do_hud())
	cena.trazer_criatura("corpo_seco")
	assert_eq(cena.texto_da_presenca(), "")
	cena.free()


func test_possessao_trava_o_cacador_e_descanso_tira_a_exaustao() -> void:
	var cena := _cena()
	cena.condicao.adquirir("sensitivo")
	cena.condicao.exaustao = float(_cfg()["sensitivo"]["exaustao_maxima"]) - 0.01
	# Os espíritos nascem longe e levam uns segundos para chegar.
	for i in 400:
		cena.passar_tempo(0.1)
		if cena.condicao.possuido():
			break
	assert_true(cena.condicao.possuido(), "os espíritos levaram ao máximo")
	assert_true(cena.cacador.bloqueado)
	for i in 60:
		cena.passar_tempo(0.1)
	assert_false(cena.condicao.possuido())
	assert_false(cena.cacador.bloqueado, "volta a si")
	var porta: Vector2 = cena.porta_do_motel()
	cena.cacador.position = Vector3(porta.x, 0.3, porta.y)
	cena.descansar()
	assert_eq(cena.condicao.exaustao, 0.0)
	cena.free()
