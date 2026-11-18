extends "res://tests/framework/test_case.gd"
## Fase 4: suspeita e maré básicas no núcleo (core/mundo/suspeita.gd, core/tempo/mare.gd).

const Catalogo := preload("res://core/dados/catalogo.gd")
const Suspeita := preload("res://core/mundo/suspeita.gd")
const Mare := preload("res://core/tempo/mare.gd")
const Relogio := preload("res://core/tempo/relogio.gd")

var _cfg: Dictionary


func before_each() -> void:
	_cfg = Catalogo.carregar_config_suspeita()["dados"]


func test_configs_validas() -> void:
	assert_eq(Catalogo.carregar_config_suspeita()["erros"].size(), 0)
	assert_eq(Catalogo.carregar_config_mare()["erros"].size(), 0)


func test_suspeita_sobe_de_nivel_pelos_limites() -> void:
	var s := Suspeita.new(_cfg)
	assert_eq(s.nivel("valongo"), Suspeita.NORMAL)
	s.somar("valongo", int(_cfg["niveis"]["observado"]), "teste", 0)
	assert_eq(s.nivel("valongo"), Suspeita.OBSERVADO)
	s.somar("valongo", int(_cfg["niveis"]["procurado"]), "teste", 0)
	assert_eq(s.nivel("valongo"), Suspeita.PROCURADO)
	s.somar("valongo", 1000, "teste", 0)
	assert_eq(s.nivel("valongo"), Suspeita.BARRADO)
	assert_eq(s.historico.size(), 3)


func test_suspeita_geral_recebe_metade_e_vale_em_todo_bairro() -> void:
	var s := Suspeita.new(_cfg)
	s.somar("valongo", 2 * int(_cfg["niveis"]["observado"]), "teste", 0)
	assert_eq(s.geral, int(_cfg["niveis"]["observado"]))
	assert_eq(s.nivel("centro"), Suspeita.OBSERVADO, "a fama corre pela cidade")
	assert_eq(s.pontos("centro"), 0)


func test_suspeita_cai_com_o_tempo_e_nao_fica_negativa() -> void:
	var s := Suspeita.new(_cfg)
	s.somar("valongo", 5, "teste", 0)
	s.passar_minutos(59)
	assert_eq(s.pontos("valongo"), 5, "antes da hora cheia não cai")
	s.passar_minutos(1)
	assert_eq(s.pontos("valongo"), 5 - int(_cfg["queda_por_hora"]))
	s.passar_minutos(60 * 100)
	assert_eq(s.pontos("valongo"), 0)


func test_sujo_do_esgoto_quem_ve_aumenta_a_suspeita_ate_passar() -> void:
	var s := Suspeita.new(_cfg)
	assert_eq(s.visto("valongo", 100), 0, "limpo, ninguém liga")
	s.sujar(100)
	assert_true(s.sujo(150))
	assert_eq(s.visto("valongo", 150), int(_cfg["sujeira"]["pontos_por_minuto_visto"]))
	var fim := 100 + int(_cfg["sujeira"]["duracao_minutos"])
	assert_false(s.sujo(fim), "a sujeira passa")
	assert_eq(s.visto("valongo", fim), 0)


func test_detido_a_suspeita_cai_e_limpa() -> void:
	var s := Suspeita.new(_cfg)
	s.somar("centro", 200, "teste", 0)
	s.sujar(0)
	s.detido("centro", 10)
	assert_eq(s.pontos("centro"), int(_cfg["detencao"]["suspeita_depois"]))
	assert_false(s.sujo(11))


func test_mare_sobe_e_desce_duas_vezes_por_dia() -> void:
	var cfg: Dictionary = Catalogo.carregar_config_mare()["dados"]
	var m := Mare.new(cfg)
	var r: Dictionary = cfg["preamar_de_referencia"]
	var preamar := Relogio.minutos_de(int(r["ano"]), int(r["mes"]), int(r["dia"]), int(r["hora"]), int(r["minuto"]))
	assert_almost_eq(m.altura(preamar), m.media + m.amplitude, 0.001, "maré alta na referência")
	assert_almost_eq(m.altura(preamar + m.periodo / 2), m.media - m.amplitude, 0.01, "baixa-mar meio ciclo depois")
	assert_almost_eq(m.altura(preamar + m.periodo), m.altura(preamar), 0.001, "o ciclo se repete")
	var altas := 0
	for minuto in range(preamar + 1, preamar + 24 * 60):
		if m.proxima_preamar(minuto) == minuto:
			altas += 1
	assert_true(altas == 1 or altas == 2, "uma ou duas preamares por dia (%d)" % altas)


func test_mare_alta_alaga_as_galerias_e_a_baixa_nao() -> void:
	var cfg: Dictionary = Catalogo.carregar_config_mare()["dados"]
	var m := Mare.new(cfg)
	var preamar := m.proxima_preamar(0)
	assert_true(m.galerias_alagadas(preamar))
	assert_false(m.galerias_alagadas(preamar + m.periodo / 2))
	assert_almost_eq(m.fracao(preamar), 1.0, 0.001)
