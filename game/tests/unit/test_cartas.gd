extends "res://tests/framework/test_case.gd"
## Fase 4: cartas e presentes depois do caso (core/casos/cartas.gd, docs/04).

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Cartas := preload("res://core/casos/cartas.gd")
const Regras := preload("res://core/investigacao/regras_de_campo.gd")
const Sessao := preload("res://core/investigacao/sessao.gd")
const Interpretador := preload("res://ui/texto/interpretador.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")

static var _casos: Dictionary = {}


func _caso(especie: String, id_bairro: String = "paqueta", estrutura: String = "") -> Dictionary:
	var chave := "%s|%s|%s" % [especie, id_bairro, estrutura]
	if not _casos.has(chave):
		_casos[chave] = {}
		for semente in range(1, 80):
			var caso := Gerador.gerar(semente, id_bairro)
			if caso["verdade"]["especie"] == especie and (estrutura.is_empty() or caso["estrutura"] == estrutura):
				_casos[chave] = caso
				break
	return _casos[chave]


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_testes()["dados"]


func _criaturas() -> Dictionary:
	return Catalogo.carregar_criaturas()["criaturas"]


func _cartas(caso: Dictionary, resolucao: String, especie: String, alvo: String = "") -> Array[Dictionary]:
	var desfecho := Regras.decidir(resolucao, especie, alvo, caso, _criaturas(), _cfg(), int(caso["contrato"]["minuto"]))
	assert_true(desfecho["ok"], str(desfecho.get("erro", "")))
	return Cartas.gerar(caso, desfecho, _criaturas(), Catalogo.carregar_bairro(caso["bairro"])["dados"],
		Catalogo.carregar_textos_cartas()["dados"], _cfg()["resolucoes_que_encerram_os_ataques"])


func _situacoes(cartas: Array[Dictionary]) -> Array:
	var lista: Array = []
	for c in cartas:
		if not c["situacao"] in lista:
			lista.append(c["situacao"])
	return lista


func _nome(caso: Dictionary, id: String) -> String:
	for npc in caso["npcs"]:
		if npc["id"] == id:
			return "%s %s" % [npc["nome"], npc["sobrenome"]]
	return ""


func test_cartas_config_e_valida() -> void:
	assert_eq(Catalogo.carregar_textos_cartas()["erros"], [] as Array[String])


func test_caso_resolvido_o_cliente_agradece_pelo_nome_e_sem_lacunas() -> void:
	var caso := _caso("corpo_seco")
	var cartas := _cartas(caso, "banir", "corpo_seco")
	assert_eq(_situacoes(cartas), ["pessoas_salvas"])
	var do_cliente: Array = cartas.filter(func(c): return c["de"] == "cliente")
	assert_eq(do_cliente.size(), 1, "o cliente escreve")
	assert_eq(do_cliente[0]["remetente"], caso["contrato"]["cliente"])
	var texto: String = do_cliente[0]["texto"]
	assert_true(_nome(caso, caso["contrato"]["cliente"]) in texto, "assina com o nome: %s" % texto)
	for c in cartas:
		assert_false("{" in c["texto"], "tudo preenchido: %s" % c["texto"])


func test_testemunhas_que_escrevem_viram_algum_ataque() -> void:
	var caso := _caso("corpo_seco")
	var ataques := {}
	for a in caso["registro"].buscar("criatura.ataque", caso["verdade"]["instancia"]):
		ataques[int(a["id"])] = true
	for c in _cartas(caso, "banir", "corpo_seco"):
		if c["de"] != "testemunha":
			continue
		var viu := false
		for npc in caso["npcs"]:
			if npc["id"] == c["remetente"]:
				for m in npc["memorias"]:
					viu = viu or ataques.has(int(m["evento_origem"]))
		assert_true(viu, "%s viu um ataque" % c["remetente"])


func test_criatura_poupada_deixa_um_presente_estranho_na_porta() -> void:
	var caso := _caso("curupira", "valongo")
	assert_false(caso.is_empty())
	var cartas := _cartas(caso, "apaziguar", "curupira")
	assert_has(_situacoes(cartas), "criatura_poupada")
	for c in cartas:
		if c["situacao"] == "criatura_poupada":
			assert_eq(c["de"], "ninguem")
			assert_false(str(c["presente"]).is_empty(), "sempre deixa um presente")


func test_criatura_errada_o_cliente_pergunta_por_que_nao_chegou_antes() -> void:
	var caso := _caso("corpo_seco")
	var cartas := _cartas(caso, "curar", "mula_sem_cabeca", caso["npcs"][0]["id"])
	assert_has(_situacoes(cartas), "vitimas_por_demora")
	assert_false("pessoas_salvas" in _situacoes(cartas))


func test_inocente_morto_a_familia_escreve_com_raiva_e_cita_a_pessoa() -> void:
	var caso := _caso("lobisomem_br")
	var inocente := ""
	for npc in caso["npcs"]:
		if npc["id"] != caso["verdade"]["hospedeiro"] and int(npc["idade"]) >= 18:
			inocente = npc["id"]
			break
	var cartas := _cartas(caso, "matar", "lobisomem_br", inocente)
	assert_has(_situacoes(cartas), "inocente_prejudicado")
	for c in cartas:
		if c["situacao"] == "inocente_prejudicado":
			assert_eq(c["de"], "familia")
			assert_true(_nome(caso, inocente) in c["texto"], "cita quem morreu")


func test_matar_o_amaldicoado_a_familia_lembra_que_tinha_cura() -> void:
	var caso := _caso("lobisomem_br")
	var cartas := _cartas(caso, "matar", "lobisomem_br", caso["verdade"]["hospedeiro"])
	assert_has(_situacoes(cartas), "amaldicoado_morto")


func test_golpe_exposto_o_golpista_ameaca() -> void:
	var caso := _caso("golpe_humano")
	var cartas := _cartas(caso, "expor", "golpe_humano", caso["verdade"]["hospedeiro"])
	assert_has(_situacoes(cartas), "cliente_exposto")
	for c in cartas:
		if c["situacao"] == "cliente_exposto":
			assert_eq(c["remetente"], caso["verdade"]["hospedeiro"])


func test_testemunhas_nao_mandam_a_mesma_carta() -> void:
	for especie in ["corpo_seco", "lobisomem_br", "mula_sem_cabeca"]:
		var textos := {}
		for c in _cartas(_caso(especie), "prender", especie, _caso(especie)["verdade"]["hospedeiro"]) if especie != "corpo_seco" else _cartas(_caso(especie), "banir", especie):
			assert_false(textos.has(c["texto"]), "carta repetida: %s" % c["texto"])
			textos[c["texto"]] = true


func test_mesmo_caso_e_desfecho_mesmas_cartas() -> void:
	var caso := _caso("corpo_seco")
	assert_eq(_cartas(caso, "banir", "corpo_seco"), _cartas(caso, "banir", "corpo_seco"))


func test_jogo_em_texto_mostra_as_cartas_depois_de_agir() -> void:
	var caso := _caso("corpo_seco")
	var s := Sessao.new(caso, _criaturas(), Catalogo.carregar_bairro(caso["bairro"])["dados"], Catalogo.carregar_config_investigacao()["dados"])
	var jogo := Interpretador.new(s, _criaturas(), Catalogo.carregar_textos_marcas()["dados"])
	assert_has(jogo.executar("cartas"), "depois que o caso for encerrado")
	jogo.executar("agir banir corpo_seco")
	assert_has(jogo.executar("cartas"), "CARTAS E PRESENTES")
	assert_has(jogo.executar("relatorio"), "CARTAS E PRESENTES")
	assert_has(jogo.executar("cartas"), _nome(caso, caso["contrato"]["cliente"]))
