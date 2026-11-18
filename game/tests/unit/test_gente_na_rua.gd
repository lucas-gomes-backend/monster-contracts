extends "res://tests/framework/test_case.gd"
## Fase 4: a gente dos bairros na cidade 3D (presentation/cidade/populacao_3d.gd): cada
## um na porta de onde a rotina manda, e quem muda de lugar anda até lá pelas ruas.

const Cena := preload("res://presentation/cidade/bairro_cena.gd")

var _cena: Node3D


func before_each() -> void:
	_cena = Cena.new()
	_cena.montar("valongo", 1)


func after_each() -> void:
	_cena.free()


func test_gente_nos_dois_bairros_do_corte_vertical() -> void:
	for id in ["valongo", "centro"]:
		assert_true(_cena.populacoes.has(id), "%s tem gente" % id)
		assert_true(_cena.populacoes[id].npcs.size() >= 25, "%s: %d moradores" % [id, _cena.populacoes[id].npcs.size()])


func test_quem_aparece_esta_na_porta_do_lugar_da_rotina() -> void:
	var gente: Node3D = _cena.populacoes["valongo"]
	assert_gte(gente.visiveis(), 1, "às 8h já tem gente trabalhando na rua")
	for id in gente.pessoas:
		var p: Dictionary = gente.pessoas[id]
		if not p["no"].visible:
			continue
		var porta: Variant = gente.porta_de(p["local"], p["indice"])
		assert_true(porta != null, "%s visível num lugar do bairro" % id)
		assert_true(Vector2(p["no"].position.x, p["no"].position.z).distance_to(porta) < 0.01, "%s na porta de %s" % [id, p["local"]])
		assert_has(["trabalhando", "lazer"], p["atividade"])


func test_relogio_anda_e_quem_muda_de_lugar_vai_andando_pelas_ruas() -> void:
	var gente: Node3D = _cena.populacoes["valongo"]
	# Passa o tempo até alguém sair de um lugar do bairro para outro.
	var andando := ""
	for i in 24 * 60:
		_cena.passar_tempo(1.0 / _cena.minutos_por_segundo)
		for id in gente.pessoas:
			if not gente.pessoas[id]["rota"].is_empty():
				andando = id
		if not andando.is_empty():
			break
	assert_false(andando.is_empty(), "em um dia, alguém troca de lugar a pé")
	var p: Dictionary = gente.pessoas[andando]
	var destino: Vector2 = p["rota"][-1]
	assert_gte(p["rota"].size(), 3, "vai pelas ruas, não em linha reta pelos prédios")
	assert_true(p["no"].visible, "quem anda está à vista")
	var antes := Vector2(p["no"].position.x, p["no"].position.z)
	gente.andar(1.0)
	var depois := Vector2(p["no"].position.x, p["no"].position.z)
	assert_almost_eq(antes.distance_to(depois), gente.velocidade, 0.05, "anda na velocidade a pé")
	for i in 2000:
		gente.andar(0.5)
		if p["rota"].is_empty():
			break
	assert_true(p["rota"].is_empty(), "chega")
	assert_true(Vector2(p["no"].position.x, p["no"].position.z).distance_to(destino) < 0.01, "na porta do destino")


func test_relogio_mostra_dia_e_hora() -> void:
	assert_eq(_cena.texto_do_relogio(), "Quarta, 08:00")
	_cena.passar_tempo(65.0 / _cena.minutos_por_segundo)
	assert_eq(_cena.texto_do_relogio(), "Quarta, 09:05")


func test_mesma_semente_mesma_gente_no_mesmo_lugar() -> void:
	var outra := Cena.new()
	outra.montar("valongo", 1)
	var a: Node3D = _cena.populacoes["valongo"]
	var b: Node3D = outra.populacoes["valongo"]
	for id in a.pessoas:
		assert_eq(a.pessoas[id]["local"], b.pessoas[id]["local"], id)
	outra.free()
