extends "res://tests/framework/test_case.gd"
## Rotina dos NPCs e quem presenciou o quê (core/npcs/rotina.gd, core/npcs/presenca.gd).

const Catalogo := preload("res://core/dados/catalogo.gd")
const Bairro := preload("res://core/mundo/bairro.gd")
const Gerador := preload("res://core/npcs/gerador_populacao.gd")
const Rotina := preload("res://core/npcs/rotina.gd")
const Presenca := preload("res://core/npcs/presenca.gd")
const Criatura := preload("res://core/criaturas/criatura.gd")
const Barramento := preload("res://core/eventos/barramento.gd")
const Rng := preload("res://core/rng.gd")
const Relogio := preload("res://core/tempo/relogio.gd")

const SEMANA_UTIL := ["segunda", "terca", "quarta", "quinta", "sexta"]


func _bairro() -> RefCounted:
	return Bairro.new(Catalogo.carregar_bairro("paqueta")["dados"])


func _config() -> Dictionary:
	return Catalogo.carregar_config_populacao()["dados"]


func _rotina(semente: int = 1) -> RefCounted:
	return Rotina.new(_config(), Rng.new(semente), _bairro())


## NPC de teste. "casa" é o número da casa (casa_01 fica na rua_1, casa_04 na rua_do_cemiterio).
func _npc(id: String, casa: int, tracos: Array = [], ocupacao: Dictionary = {}, trabalho: String = "", idade: int = 40) -> Dictionary:
	return {"id": id, "casa": "paqueta/casa_%02d" % casa, "tracos": tracos, "ocupacao": ocupacao,
		"trabalho": trabalho, "idade": idade, "memorias": [], "relacoes": []}


func _vigia() -> Dictionary:
	var oc := {"id": "vigia_noturno", "inicio": 20, "fim": 6, "dias": Relogio.DIAS, "sono": [8, 15]}
	return _npc("vigia", 1, [], oc, "paqueta/cemiterio")


func test_rotina_padeiro_esta_na_padaria_no_horario_de_trabalho() -> void:
	var oc := {"id": "padeiro", "inicio": 4, "fim": 13, "dias": SEMANA_UTIL}
	var padeiro := _npc("padeiro", 2, [], oc, "paqueta/padaria")
	assert_eq(_rotina().onde_esta(padeiro, Relogio.minutos_de(2015, 11, 11, 8)), {"local": "paqueta/padaria", "atividade": "trabalhando"})


func test_rotina_de_madrugada_quem_nao_trabalha_dorme_em_casa() -> void:
	var morador := _npc("morador", 3)
	assert_eq(_rotina().onde_esta(morador, Relogio.minutos_de(2015, 11, 11, 3)), {"local": "paqueta/casa_03", "atividade": "dormindo"})


func test_rotina_notivago_esta_acordado_as_23h_e_dorme_as_3h() -> void:
	var notivago := _npc("notivago", 3, ["notivago"])
	var r := _rotina()
	assert_ne(r.onde_esta(notivago, Relogio.minutos_de(2015, 11, 11, 23))["atividade"], "dormindo", "23h")
	assert_eq(r.onde_esta(notivago, Relogio.minutos_de(2015, 11, 12, 3))["atividade"], "dormindo", "3h")


func test_rotina_vigia_trabalha_de_noite_e_dorme_de_dia() -> void:
	var r := _rotina()
	assert_eq(r.onde_esta(_vigia(), Relogio.minutos_de(2015, 11, 12, 23))["local"], "paqueta/cemiterio", "23h")
	assert_eq(r.onde_esta(_vigia(), Relogio.minutos_de(2015, 11, 13, 10))["atividade"], "dormindo", "10h")


func test_rotina_quem_bebe_vai_ao_bar_em_algumas_noites_e_nunca_a_outro_lugar() -> void:
	var bebe := _npc("bebe", 3, ["bebe_muito"])
	var r := _rotina()
	var no_bar := 0
	for dia in 60:
		var lugar: String = r.onde_esta(bebe, Relogio.minutos_de(2015, 11, 9, 19) + dia * Relogio.MINUTOS_POR_DIA)["local"]
		if lugar == "paqueta/bar":
			no_bar += 1
		elif lugar != "paqueta/casa_03":
			fail("dia %d: foi para %s" % [dia, lugar])
	assert_true(no_bar > 0 and no_bar < 60, "vai ao bar em algumas noites, não em todas (%d de 60)" % no_bar)


func test_rotina_nao_tem_estado_a_ordem_das_perguntas_nao_importa() -> void:
	var npcs := Gerador.gerar(_bairro(), _config(), Rng.new(5))
	var r := _rotina(5)
	var momentos := [Relogio.minutos_de(2015, 11, 12, 23), Relogio.minutos_de(2015, 11, 9, 19), Relogio.minutos_de(2015, 11, 14, 8)]
	var ida := []
	var volta := []
	for m in momentos:
		for npc in npcs:
			ida.append(r.onde_esta(npc, m))
	momentos.reverse()
	for m in momentos:
		for npc in npcs:
			volta.append(r.onde_esta(npc, m))
	var volta_reordenada := []
	var n := npcs.size()
	for bloco in [2, 1, 0]:
		volta_reordenada.append_array(volta.slice(bloco * n, (bloco + 1) * n))
	assert_eq(ida, volta_reordenada)


func test_rotina_todo_npc_esta_sempre_num_lugar_valido() -> void:
	var b := _bairro()
	var npcs := Gerador.gerar(b, _config(), Rng.new(3))
	var r := _rotina(3)
	var inicio := Relogio.minutos_de(2015, 11, 9)
	for hora in 7 * 24:
		for npc in npcs:
			var lugar: String = r.onde_esta(npc, inicio + hora * 60)["local"]
			if lugar != Bairro.FORA_DO_BAIRRO and not b.existe(lugar):
				fail("%s em lugar inválido %s" % [npc["id"], lugar])


func test_presenca_vigia_ouve_e_quem_dorme_sem_sono_leve_nao() -> void:
	var b := _bairro()
	var barramento := Barramento.new()
	var vigia := _vigia()
	var dorminhoco := _npc("dorminhoco", 4)
	var sono_leve := _npc("sono_leve", 8, ["sono_leve"])
	var outra_rua := _npc("outra_rua", 2, ["notivago"])
	var npcs := [vigia, dorminhoco, sono_leve, outra_rua]
	var _p := Presenca.new(npcs, _rotina(), b, barramento, ["criatura.ataque"])
	barramento.publicar(Relogio.minutos_de(2015, 11, 12, 23, 30), "criatura.ataque", "lobo#1", "paqueta/galinheiro_1")
	assert_eq(vigia["memorias"].size(), 1, "vigia no cemitério, mesma rua, acordado")
	assert_eq(dorminhoco["memorias"].size(), 0, "dormindo sem sono leve")
	assert_eq(sono_leve["memorias"].size(), 1, "dormindo com sono leve")
	assert_eq(outra_rua["memorias"].size(), 0, "acordado em outra rua")
	barramento.encerrar()


func test_presenca_quem_esta_no_lugar_ve() -> void:
	var barramento := Barramento.new()
	var vigia := _vigia()
	var _p := Presenca.new([vigia], _rotina(), _bairro(), barramento, ["criatura.ataque"])
	barramento.publicar(Relogio.minutos_de(2015, 11, 12, 23, 30), "criatura.ataque", "lobo#1", "paqueta/cemiterio")
	assert_eq(vigia["memorias"].size(), 1)
	if vigia["memorias"].size() == 1:
		assert_eq(vigia["memorias"][0]["modo"], "viu")
	barramento.encerrar()


func test_presenca_com_criatura_toda_memoria_aponta_para_um_ataque() -> void:
	var b := _bairro()
	var criaturas: Dictionary = Catalogo.carregar_criaturas()["criaturas"]
	var config_criaturas: Dictionary = Catalogo.carregar_config_criaturas()["dados"]
	var total := 0
	for semente in [1, 2, 3, 4, 5]:
		var rng := Rng.new(semente)
		var barramento := Barramento.new()
		var npcs := Gerador.gerar(b, _config(), rng)
		var _p := Presenca.new(npcs, Rotina.new(_config(), rng, b), b, barramento, ["criatura.ataque"])
		var lobo := Criatura.new(criaturas["lobisomem_br"], "lobisomem_br#1", rng, barramento, config_criaturas,
			["paqueta/galinheiro_1", "paqueta/galinheiro_2", "paqueta/cemiterio"])
		var inicio := Relogio.minutos_de(2015, 11, 9)
		lobo.despertar(inicio, "teste")
		for hora in 60 * 24:
			lobo.passo(inicio + hora * 60)
		for memoria in barramento.registro.buscar("npc.presenciou"):
			total += 1
			var origem: Dictionary = barramento.registro.obter(int(memoria["dados"]["evento_origem"]))
			if origem.get("tipo", "") != "criatura.ataque" or origem["minuto"] != memoria["minuto"]:
				fail("semente %d: memória sem ataque de origem" % semente)
		barramento.encerrar()
	assert_gte(total, 1, "alguém presenciou algum ataque em 5 sementes")
