extends "res://tests/framework/test_case.gd"
## Relatório do caso (core/investigacao/relatorio.gd) e como ele aparece no texto e na janela.

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Sessao := preload("res://core/investigacao/sessao.gd")
const Relatorio := preload("res://core/investigacao/relatorio.gd")
const Interpretador := preload("res://ui/texto/interpretador.gd")
const Jogo := preload("res://ui/jogo.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")

const SEMENTES := [1, 2, 3, 4, 5, 6, 7, 8]


func _criaturas() -> Dictionary:
	return Catalogo.carregar_criaturas()["criaturas"]


func _gatilhos() -> Dictionary:
	return Catalogo.carregar_textos_gatilhos()["dados"]


func _sessao(semente: int) -> RefCounted:
	var caso := Gerador.gerar(semente)
	return Sessao.new(caso, _criaturas(), Catalogo.carregar_bairro(caso["bairro"])["dados"], Catalogo.carregar_config_investigacao()["dados"])


func _pistas_da_criatura(s: RefCounted) -> int:
	var n := 0
	for p in s.caso["pistas"]:
		if p["origem"] == "criatura" and p["tipo"] != "testemunho":
			n += 1
	return n


func test_relatorio_todo_gatilho_tem_texto() -> void:
	var textos := _gatilhos()
	for ficha in _criaturas().values():
		for gatilho in ficha["gatilhos"]:
			assert_true(textos.has(gatilho), "%s: gatilho %s sem texto" % [ficha["id"], gatilho])


func test_relatorio_quem_nao_investiga_perde_tudo_e_sabe_por_que() -> void:
	for semente in SEMENTES:
		var s := _sessao(semente)
		s.agir("abandonar", "")
		var r := Relatorio.gerar(s, _criaturas(), _gatilhos())
		assert_eq(r["pistas"]["encontradas"].size(), 0, "semente %d" % semente)
		assert_eq(r["pistas"]["perdidas"].size(), _pistas_da_criatura(s), "semente %d: toda pista perdida aparece" % semente)
		var por_id := {}
		for p in s.caso["pistas"]:
			por_id[p["id"]] = p
		for perdida in r["pistas"]["perdidas"]:
			var p: Dictionary = por_id[perdida["id"]]
			var ainda_existia: bool = int(p["valida_ate"]) < 0 or int(p["valida_ate"]) > int(s.caso["contrato"]["minuto"])
			if p["tipo"] == "marca" and p["detectar"] in ["olho_nu", "entrevista", "pesquisa"] and ainda_existia:
				assert_eq(perdida["motivo"], Relatorio.MOTIVO_NAO_FOI, "semente %d: %s estava lá esperando" % [semente, p["id"]])
			if p["tipo"] == "registro":
				assert_eq(perdida["motivo"], Relatorio.MOTIVO_NAO_PESQUISOU, "semente %d" % semente)
		for m in r["mentiras"]:
			assert_false(m["ouvida"], "semente %d: não ouviu ninguém" % semente)


func test_relatorio_encontradas_e_perdidas_somam_o_total() -> void:
	for semente in SEMENTES:
		var s := _sessao(semente)
		for local in s.locais():
			s.ir(local)
		s.pesquisar()
		s.agir("abandonar", "")
		var r := Relatorio.gerar(s, _criaturas(), _gatilhos())
		assert_eq(r["pistas"]["encontradas"].size() + r["pistas"]["perdidas"].size(), _pistas_da_criatura(s), "semente %d" % semente)
		for perdida in r["pistas"]["perdidas"]:
			assert_ne(perdida["motivo"], Relatorio.MOTIVO_NAO_FOI, "semente %d: foi a todos os lugares públicos" % semente)
			assert_ne(perdida["motivo"], Relatorio.MOTIVO_NAO_PESQUISOU, "semente %d: pesquisou" % semente)


func test_relatorio_separa_ligacoes_certas_e_erradas() -> void:
	var s := _sessao(12)
	for local in s.locais():
		s.ir(local)
	var pista: Dictionary = s.caderno.pistas()[0]
	var outra_tag := ""
	for tag in s.caderno.vocabulario():
		if tag != pista.get("tag", ""):
			outra_tag = tag
			break
	if s.caderno.vocabulario().has(pista.get("tag", "")):
		s.caderno.ligar(pista["id"], pista["tag"])
	s.caderno.ligar(pista["id"], outra_tag)
	s.agir("abandonar", "")
	var r := Relatorio.gerar(s, _criaturas(), _gatilhos())
	assert_eq(r["ligacoes"]["erradas"].size(), 1, "a ligação à característica errada")
	for certa in r["ligacoes"]["certas"]:
		assert_eq(certa["tag"], pista["tag"])


func test_relatorio_conta_o_porque_e_o_tempo() -> void:
	var s := _sessao(3)
	s.agir("abandonar", "")
	var r := Relatorio.gerar(s, _criaturas(), _gatilhos())
	assert_eq(r["verdade"]["por_que"], _gatilhos()[s.caso["verdade"]["gatilho"]])
	assert_eq(r["tempo"]["minutos_gastos"], 0)
	assert_false(r["tempo"]["passou_do_prazo"])


func test_relatorio_no_texto_so_depois_de_encerrar() -> void:
	var s := _sessao(5)
	var jogo := Interpretador.new(s, _criaturas(), Catalogo.carregar_textos_marcas()["dados"])
	assert_has(jogo.executar("relatorio"), "quando o caso for encerrado")
	jogo.executar("agir abandonar")
	var texto := jogo.executar("relatorio")
	for secao in ["RELATÓRIO DO CASO", "POR QUÊ", "PISTAS DA CRIATURA", "SUAS LIGAÇÕES", "QUEM MENTIU", "RUÍDO", "DEPOIMENTOS"]:
		assert_has(texto, secao)


func test_relatorio_aparece_na_janela_ao_encerrar() -> void:
	var janela := Jogo.new()
	janela.montar()
	janela.novo_caso(7)
	janela.executar("agir abandonar")
	assert_has(janela._relatorio_texto.get_parsed_text(), "RELATÓRIO DO CASO")
	janela.free()
