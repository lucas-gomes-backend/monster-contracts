extends "res://tests/framework/test_case.gd"
## Fase 4: morte simples, volta com custo e sem a arena do limbo (docs/13, Parte C).

const VoltaDaMorte := preload("res://core/progressao/volta_da_morte.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_morte()["dados"]


func test_config_da_morte_e_valida() -> void:
	assert_eq(Catalogo.carregar_config_morte()["erros"], [] as Array[String])


func test_cada_volta_custa_mais_que_a_anterior() -> void:
	var a := VoltaDaMorte.custo(1, _cfg())
	var b := VoltaDaMorte.custo(2, _cfg())
	assert_eq(a["dias_perdidos"], int(_cfg()["dias_perdidos"]))
	assert_eq(a["minutos"], int(a["dias_perdidos"]) * 1440)
	assert_true(b["dias_perdidos"] > a["dias_perdidos"], "mais tempo perdido")
	assert_true(b["dias_envelhecidos"] > a["dias_envelhecidos"], "o limbo rouba mais vida")
	assert_true(b["fracao_perdida"] > a["fracao_perdida"], "mais equipamento fica para trás")
	assert_eq(VoltaDaMorte.custo(50, _cfg())["fracao_perdida"], float(_cfg()["fracao_maxima"]), "com teto")


func test_perdidos_sorteia_pela_semente_e_arredonda_para_cima() -> void:
	var entradas := []
	for n in [3, 7, 9, 12, 20]:
		entradas.append({"n": n})
	var p := VoltaDaMorte.perdidos(entradas, 0.25, 4, 1)
	assert_eq(p.size(), 2, "25% de 5 pilhas: 2")
	assert_eq(p, VoltaDaMorte.perdidos(entradas, 0.25, 4, 1), "mesma semente e volta, mesmas perdas")
	for n in p:
		assert_true(n in [3, 7, 9, 12, 20])
	var variou := false
	for s in 20:
		variou = variou or VoltaDaMorte.perdidos(entradas, 0.25, s, 1) != p
	assert_true(variou, "o sorteio muda com a semente")
	assert_eq(VoltaDaMorte.perdidos([], 0.5, 1, 1).size(), 0)


func test_marca_do_limbo_aumenta_o_medo() -> void:
	assert_eq(VoltaDaMorte.multiplicador_do_medo(0, _cfg()), 1.0)
	assert_true(VoltaDaMorte.multiplicador_do_medo(2, _cfg()) > VoltaDaMorte.multiplicador_do_medo(1, _cfg()))


# --- Na cidade ---

func _cena() -> Node3D:
	var cena := Cena.new()
	cena.montar("valongo", 1)
	Engine.get_main_loop().root.add_child(cena)
	return cena


func _soltar(cena: Node3D) -> void:
	cena.get_parent().remove_child(cena)
	cena.free()


func test_morrer_volta_no_motel_com_custo() -> void:
	var cena := _cena()
	var c := VoltaDaMorte.custo(1, _cfg())
	var pilhas: int = cena.mochila.entradas.size()
	assert_gte(pilhas, 1, "a mochila começa com alguma coisa")
	var minuto: int = cena.minuto
	var dias: int = cena.progresso.dias_vividos
	cena.ferimentos.receber("cabeca", "critico")
	cena.passar_tempo(60.0)
	assert_true(cena.ferimentos.morto)
	assert_true(cena.cacador.bloqueado, "morto não anda")
	cena.passar_tempo(float(_cfg()["segundos_ate_voltar"]))
	assert_false(cena.ferimentos.morto, "voltou")
	assert_false(cena.cacador.bloqueado)
	assert_eq(cena.ferimentos.texto(), "nenhum", "o corpo volta inteiro")
	assert_eq(cena.progresso.voltas_do_limbo, 1, "marca do limbo")
	assert_gte(cena.minuto - minuto, int(c["minutos"]), "o mundo seguiu")
	assert_eq(cena.progresso.dias_vividos - dias, int(c["dias_perdidos"]) + int(c["dias_envelhecidos"]), "envelheceu")
	assert_eq(cena.mochila.entradas.size(), pilhas - int(ceil(pilhas * float(c["fracao_perdida"]))), "parte da mochila ficou no limbo")
	var porta: Vector2 = cena.porta_do_motel()
	assert_true(Vector2(cena.cacador.position.x, cena.cacador.position.z).distance_to(porta) < 0.5, "acorda no motel")
	_soltar(cena)


func test_o_porta_malas_nao_vai_para_o_limbo() -> void:
	var cena := _cena()
	var guardado: int = cena.porta_malas.entradas.size()
	cena.ferimentos.receber("cabeca", "critico")
	cena.passar_tempo(60.0)
	cena.passar_tempo(float(_cfg()["segundos_ate_voltar"]))
	assert_eq(cena.porta_malas.entradas.size(), guardado)
	_soltar(cena)


func test_segunda_volta_custa_mais() -> void:
	var cena := _cena()
	var a: Dictionary = cena.voltar_da_morte()
	var b: Dictionary = cena.voltar_da_morte()
	assert_eq(cena.progresso.voltas_do_limbo, 2)
	assert_true(int(b["dias_perdidos"]) > int(a["dias_perdidos"]))
	_soltar(cena)
