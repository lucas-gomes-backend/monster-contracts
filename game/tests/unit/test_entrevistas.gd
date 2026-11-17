extends "res://tests/framework/test_case.gd"
## Entrevistas e confronto com provas (core/investigacao/sessao.gd, docs/05).

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Sessao := preload("res://core/investigacao/sessao.gd")
const Interpretador := preload("res://ui/texto/interpretador.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")

const SEMENTES := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]


func _sessao(caso: Dictionary) -> RefCounted:
	return Sessao.new(caso, Catalogo.carregar_criaturas()["criaturas"], Catalogo.carregar_bairro(caso["bairro"])["dados"], Catalogo.carregar_config_investigacao()["dados"])


## Leva o caçador até onde a pessoa está acordada, nos dias depois do contrato.
func _encontrar(s: RefCounted, npc_id: String) -> bool:
	var npc: Dictionary = s.npc(npc_id)
	for hora in 7 * 24:
		var m: int = int(s.caso["contrato"]["minuto"]) + hora * 60
		var p: Dictionary = s._rotina.onde_esta(npc, m)
		if not p["atividade"] in ["dormindo", "transformado"] and p["local"] != "fora_do_bairro":
			s.minuto = m
			s._local_atual = p["local"]
			return true
	return false


## Primeiro caso com uma mentira do tipo pedido: [caso, depoimento mentiroso, prova que desmente].
func _caso_com_mentira(tipo: String) -> Array:
	for semente in range(1, 40):
		var caso := Gerador.gerar(semente)
		for dep in caso["depoimentos"]:
			if dep["mentira"].get("tipo", "") != tipo:
				continue
			for prova in caso["depoimentos"]:
				if Sessao.desmente(prova, dep):
					return [caso, dep, prova]
	return []


func test_entrevista_cliente_sempre_atende() -> void:
	var s := _sessao(Gerador.gerar(1))
	assert_true(s.entrevistar(s.caso["contrato"]["cliente"])["ok"])


func test_entrevista_quem_nao_esta_aqui_nao_fala() -> void:
	var s := _sessao(Gerador.gerar(2))
	var cliente: String = s.caso["contrato"]["cliente"]
	for npc in s.caso["npcs"]:
		if npc["id"] != cliente:
			var r: Dictionary = s.entrevistar(npc["id"])
			assert_false(r["ok"], "ainda não foi a lugar nenhum")
			assert_eq(s.minuto, int(s.caso["contrato"]["minuto"]), "recusa não gasta tempo")
			return


func test_entrevista_anota_o_que_a_pessoa_conta_e_gasta_tempo() -> void:
	var caso := Gerador.gerar(3)
	var s := _sessao(caso)
	var alvo: String = caso["depoimentos"][0]["npc"]
	assert_true(_encontrar(s, alvo), "achou a pessoa")
	var antes: int = s.minuto
	var r: Dictionary = s.entrevistar(alvo)
	assert_true(r["ok"], str(r["erro"]))
	assert_eq(s.minuto - antes, int(Catalogo.carregar_config_investigacao()["dados"]["minutos_entrevista"]))
	var esperados := 0
	for dep in caso["depoimentos"]:
		if dep["npc"] == alvo:
			esperados += 1
	assert_eq(r["novos"].size(), esperados, "todos os depoimentos dessa pessoa")


func test_confronto_sem_entrevistar_antes_e_recusado() -> void:
	var s := _sessao(Gerador.gerar(4))
	assert_eq(s.confrontar(s.caso["contrato"]["cliente"], "pista_000")["erro"], "entreviste essa pessoa antes")


func test_toda_mentira_gerada_tem_uma_prova_que_a_desmente() -> void:
	for semente in SEMENTES:
		var caso := Gerador.gerar(semente)
		for dep in caso["depoimentos"]:
			if dep["mentira"].is_empty():
				continue
			var achou := false
			for prova in caso["depoimentos"]:
				if Sessao.desmente(prova, dep):
					achou = true
					break
			assert_true(achou, "semente %d: %s sem prova" % [semente, dep["id"]])


func test_prova_que_nao_tem_relacao_nao_desmente() -> void:
	var achado := _caso_com_mentira("onde_estava")
	assert_false(achado.is_empty(), "existe caso com essa mentira")
	if achado.is_empty():
		return
	var dep: Dictionary = achado[1]
	for pista in achado[0]["pistas"]:
		assert_false(Sessao.desmente(pista, dep), "pista %s não é testemunha de onde a pessoa estava" % pista["id"])


func _confrontar_com(tipo: String, prova_certa: bool) -> Dictionary:
	var achado := _caso_com_mentira(tipo)
	if achado.is_empty():
		return {}
	var caso: Dictionary = achado[0]
	var dep: Dictionary = achado[1]
	var s := _sessao(caso)
	if not _encontrar(s, dep["npc"]):
		return {}
	s.entrevistar(dep["npc"])
	var prova: Dictionary = achado[2]
	if not prova_certa:
		prova = {"id": "pista_falsa", "tipo": "marca", "tag": "lixo_revirado"}
		s.caderno.anotar_pista(prova)
	else:
		s.caderno.anotar_depoimento(prova)
	return {"sessao": s, "resultado": s.confrontar(dep["npc"], prova["id"]), "dep": dep}


func test_confronto_com_a_prova_certa_faz_a_pessoa_contar_onde_estava() -> void:
	var r := _confrontar_com("onde_estava", true)
	assert_false(r.is_empty(), "cenário montado")
	if r.is_empty():
		return
	assert_true(r["resultado"]["cedeu"], "cedeu")
	var verdade: Dictionary = {}
	for d in r["sessao"].caderno.depoimentos():
		if d["id"] == r["resultado"]["revelado"]:
			verdade = d
	assert_eq(verdade.get("local_declarado", ""), r["dep"]["mentira"]["verdade"], "conta o lugar verdadeiro")
	assert_eq(r["sessao"].suspeita, 0, "acusar com razão não gera suspeita")


func test_confronto_com_a_prova_certa_faz_a_familia_ceder() -> void:
	var r := _confrontar_com("protege_familiar", true)
	assert_false(r.is_empty(), "cenário montado")
	if not r.is_empty():
		assert_true(r["resultado"]["cedeu"])


func test_confronto_com_prova_errada_fecha_a_pessoa_e_gera_suspeita() -> void:
	var r := _confrontar_com("onde_estava", false)
	assert_false(r.is_empty(), "cenário montado")
	if r.is_empty():
		return
	var s: RefCounted = r["sessao"]
	assert_false(r["resultado"]["cedeu"])
	assert_eq(s.suspeita, 1, "suspeita sobe")
	assert_eq(s.entrevistar(r["dep"]["npc"])["erro"], "não quer mais falar com você")


func test_interpretador_comandos_de_entrevista_respondem() -> void:
	var s := _sessao(Gerador.gerar(12))
	var jogo := Interpretador.new(s, Catalogo.carregar_criaturas()["criaturas"], Catalogo.carregar_textos_marcas()["dados"])
	for comando in ["casas", "aqui", "entrevistar cliente", "depoimentos", "ir h1", "aqui", "confrontar cliente p1"]:
		var resposta := jogo.executar(comando)
		if resposta.is_empty() or resposta.begins_with("Não entendi"):
			fail("comando '%s' não respondeu: %s" % [comando, resposta])
