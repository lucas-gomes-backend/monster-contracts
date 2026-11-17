extends "res://tests/framework/test_case.gd"
## Fase 2: interface de diálogo. A conversa usa a sessão de investigação do núcleo
## (entrevistar e confrontar), e a janela só mostra as falas e as opções.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Gerador := preload("res://core/casos/gerador_casos.gd")
const Sessao := preload("res://core/investigacao/sessao.gd")
const Interpretador := preload("res://ui/texto/interpretador.gd")
const Conversa := preload("res://presentation/dialogo/conversa.gd")
const JanelaDialogo := preload("res://presentation/dialogo/janela_dialogo.gd")
const Rua := preload("res://presentation/greybox/rua.gd")


func _conversa(caso: Dictionary) -> RefCounted:
	var criaturas: Dictionary = Catalogo.carregar_criaturas()["criaturas"]
	var s := Sessao.new(caso, criaturas, Catalogo.carregar_bairro(caso["bairro"])["dados"],
		Catalogo.carregar_config_investigacao()["dados"])
	return Conversa.new(s, Interpretador.new(s, criaturas, Catalogo.carregar_textos_marcas()["dados"]))


func _ids(estado: Dictionary) -> Array:
	var ids: Array = []
	for opcao in estado["opcoes"]:
		ids.append(opcao["id"])
	return ids


## Leva o caçador até onde a pessoa está acordada, nos dias depois do contrato.
func _encontrar(s: RefCounted, npc_id: String) -> bool:
	for hora in 7 * 24:
		var m: int = int(s.caso["contrato"]["minuto"]) + hora * 60
		var p: Dictionary = s._rotina.onde_esta(s.npc(npc_id), m)
		if not p["atividade"] in ["dormindo", "transformado"] and p["local"] != "fora_do_bairro":
			s.minuto = m
			s._local_atual = p["local"]
			return true
	return false


## [caso, depoimento mentiroso, depoimento que desmente], ou [].
func _caso_com_mentira() -> Array:
	for semente in range(1, 40):
		var caso := Gerador.gerar(semente)
		for dep in caso["depoimentos"]:
			if dep["mentira"].get("tipo", "") != "onde_estava":
				continue
			for prova in caso["depoimentos"]:
				if Sessao.desmente(prova, dep):
					return [caso, dep, prova]
	return []


func test_dialogo_cliente_atende_com_opcoes_fixas() -> void:
	var c := _conversa(Gerador.gerar(12))
	var estado: Dictionary = c.abrir(c.sessao.caso["contrato"]["cliente"])
	assert_false(estado["acabou"])
	assert_eq(_ids(estado), ["contrato", "perguntar", "provas", "sair"])
	assert_false(str(estado["nome"]).is_empty(), "mostra o nome")
	assert_false(str(estado["descricao"]).begins_with(str(estado["nome"])), "a descrição não repete o nome")


func test_dialogo_quem_nao_esta_por_perto_nao_conversa() -> void:
	var c := _conversa(Gerador.gerar(12))
	var outro := ""
	for npc in c.sessao.caso["npcs"]:
		if npc["id"] != c.sessao.caso["contrato"]["cliente"]:
			outro = npc["id"]
			break
	var estado: Dictionary = c.abrir(outro)
	assert_true(estado["acabou"], "o caçador não está em lugar nenhum ainda")
	assert_eq(estado["opcoes"].size(), 0)


func test_dialogo_perguntar_entrevista_de_verdade_e_gasta_tempo() -> void:
	var c := _conversa(Gerador.gerar(12))
	var cliente: String = c.sessao.caso["contrato"]["cliente"]
	var antes: int = c.sessao.minuto
	c.abrir(cliente)
	var estado: Dictionary = c.escolher("perguntar")
	assert_true(c.sessao.minuto > antes, "o tempo passou")
	assert_has(" ".join(estado["falas"]), "minutos se passaram")
	var anotados := 0
	for fala in estado["falas"]:
		if str(fala).begins_with("[anotado]"):
			anotados += 1
	var do_cliente := 0
	for dep in c.sessao.caderno.depoimentos():
		if dep["npc"] == cliente:
			do_cliente += 1
	assert_eq(anotados, do_cliente, "cada depoimento anotado aparece na conversa")


func test_dialogo_sem_nada_no_caderno_nao_ha_prova_para_mostrar() -> void:
	var c := _conversa(Gerador.gerar(12))
	c.abrir(c.sessao.caso["contrato"]["cliente"])
	var estado: Dictionary = c.escolher("provas")
	assert_has(estado["falas"][0], "ainda não tem nada")
	assert_has(_ids(estado), "perguntar", "volta para as opções")


func test_dialogo_prova_certa_faz_a_pessoa_ceder() -> void:
	var achado := _caso_com_mentira()
	assert_false(achado.is_empty(), "cenário montado")
	if achado.is_empty():
		return
	var c := _conversa(achado[0])
	var dep: Dictionary = achado[1]
	assert_true(_encontrar(c.sessao, dep["npc"]), "achou a pessoa acordada")
	c.abrir(dep["npc"])
	c.escolher("perguntar")
	c.sessao.caderno.anotar_depoimento(achado[2])
	var provas: Dictionary = c.escolher("provas")
	assert_has(_ids(provas), "prova:" + achado[2]["id"], "o depoimento que desmente aparece como prova")
	assert_has(_ids(provas), "voltar")
	var estado: Dictionary = c.escolher("prova:" + achado[2]["id"])
	assert_false(estado["acabou"], "a conversa continua")
	assert_has(estado["falas"], "Tá bom. Eu não contei tudo.")
	assert_eq(c.sessao.suspeita, 0)


func test_dialogo_prova_errada_fecha_a_pessoa_e_ela_nao_volta_a_falar() -> void:
	var c := _conversa(Gerador.gerar(12))
	var cliente: String = c.sessao.caso["contrato"]["cliente"]
	c.abrir(cliente)
	c.escolher("perguntar")
	c.sessao.caderno.anotar_pista({"id": "pista_falsa", "tipo": "marca", "tag": "lixo_revirado", "local": "", "minuto": 0})
	var estado: Dictionary = c.escolher("prova:pista_falsa")
	assert_true(estado["acabou"])
	assert_eq(c.sessao.suspeita, 1, "a suspeita sobe")
	assert_true(c.abrir(cliente)["acabou"], "não quer mais conversar")


func test_janela_mostra_opcoes_numeradas_e_escolhe_pelo_numero() -> void:
	var janela := JanelaDialogo.new()
	janela.montar()
	var escolhidas: Array = []
	janela.escolheu.connect(func(id: String) -> void: escolhidas.append(id))
	janela.mostrar({"nome": "Fulano", "descricao": "", "falas": ["Oi."], "acabou": false,
		"opcoes": [{"id": "a", "texto": "Primeira"}, {"id": "b", "texto": "Segunda"}]})
	assert_eq(janela.opcoes.get_child_count(), 2)
	assert_has(janela.opcoes.get_child(1).text, "2. Segunda")
	janela.escolher_numero(1)
	assert_eq(escolhidas, ["b"])
	janela.mostrar({"nome": "Fulano", "descricao": "", "falas": ["Tchau."], "acabou": true, "opcoes": []})
	assert_eq(janela.ids_das_opcoes(), ["fim"] as Array[String], "no fim só sobra encerrar")
	janela.escolher_numero(0)
	assert_false(janela.aberta, "encerrou")
	janela.free()


func test_rua_cliente_do_caso_esta_na_calcada_e_conversa_trava_o_cacador() -> void:
	var rua := Rua.new()
	rua.montar(12)
	assert_eq(rua.moradores.size(), 1)
	var cliente: Node3D = rua.moradores[0]
	assert_eq(cliente.npc_id, rua.sessao.caso["contrato"]["cliente"])
	rua.cacador.position = cliente.position + Vector3(0, 0, 1.2)
	var olho: Vector3 = cliente.position + Vector3(0.7, 1.8, 4.0)
	var alvo: int = rua.alvo_na_mira(olho, (cliente.ponto_de_conversa() - olho).normalized())
	assert_eq(alvo, rua.pistas.size(), "o cliente vira alvo depois das pistas")
	rua.conversar(cliente)
	assert_true(rua.dialogo.aberta)
	assert_true(rua.cacador.bloqueado)
	var antes: int = rua.sessao.minuto
	rua.dialogo.escolher_numero(rua.dialogo.ids_das_opcoes().find("perguntar"))
	assert_true(rua.sessao.minuto > antes, "escolher na janela entrevista na sessão")
	rua.dialogo.fechar()
	assert_false(rua.cacador.bloqueado)
	rua.free()
