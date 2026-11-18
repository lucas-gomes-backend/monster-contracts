extends "res://tests/framework/test_case.gd"
## Fase 5: Vampirismo e Licantropia pegos por mordida, com estigma básico (docs/12).

const Condicao := preload("res://core/condicoes/condicao.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")
const Relogio := preload("res://core/tempo/relogio.gd")


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_condicoes()["dados"]


func _ficha(id: String) -> Dictionary:
	return Catalogo.carregar_criaturas()["criaturas"][id]


func test_config_valida_e_as_criaturas_transmitem() -> void:
	assert_eq(Catalogo.carregar_config_condicoes()["erros"], [] as Array[String])
	assert_eq(_ficha("strigoi")["condicao_transmitida"], "vampirismo")
	assert_eq(_ficha("lobisomem_eu")["condicao_transmitida"], "licantropia")


func test_so_ferimento_grave_de_quem_transmite_passa_a_condicao() -> void:
	var cfg := _cfg()
	assert_eq(Condicao.pega_pela_mordida(cfg, _ficha("strigoi"), "grave", 0.0), "vampirismo")
	assert_eq(Condicao.pega_pela_mordida(cfg, _ficha("lobisomem_eu"), "critico", 0.0), "licantropia")
	assert_eq(Condicao.pega_pela_mordida(cfg, _ficha("strigoi"), "leve", 0.0), "", "arranhão não passa")
	assert_eq(Condicao.pega_pela_mordida(cfg, _ficha("lobisomem_br"), "grave", 0.0), "", "o lobisomem brasileiro não transmite")
	assert_eq(Condicao.pega_pela_mordida(cfg, _ficha("strigoi"), "grave", 0.99), "", "com sorte, escapa")


func test_vampiro_enxerga_no_escuro_e_o_sol_fere() -> void:
	var c := Condicao.new(_cfg())
	assert_false(c.enxerga_no_escuro())
	assert_eq(c.sol_fere_a_cada_minutos(), 0)
	c.adquirir("vampirismo")
	assert_true(c.enxerga_no_escuro())
	assert_true(c.sol_fere_a_cada_minutos() > 0)
	assert_true(c.fator_de_estigma() > 0.0)
	assert_eq(c.texto(), "Vampirismo (Recente)")


func test_lobisomem_fareja_qualquer_criatura_perto_sem_dizer_qual() -> void:
	var c := Condicao.new(_cfg())
	c.adquirir("licantropia")
	assert_true(c.sente(_ficha("corpo_seco"), 10.0))
	assert_true(c.sente(_ficha("onryo"), 10.0))
	assert_false(c.sente(_ficha("corpo_seco"), 500.0), "longe demais")


func test_uma_condicao_por_vez() -> void:
	var c := Condicao.new(_cfg())
	assert_true(c.adquirir("vampirismo")["ok"])
	assert_false(c.adquirir("licantropia")["ok"])


# --- Na cidade ---

func _cena() -> Node3D:
	var cena := Cena.new()
	cena.montar("valongo", 1)
	return cena


func test_na_rua_de_dia_o_sol_fere_o_vampiro() -> void:
	var cena := _cena()
	cena.condicao.adquirir("vampirismo")
	cena.minuto = Relogio.minutos_de(2015, 11, 12, 12, 0)
	for i in int(_cfg()["vampirismo"]["sol_fere_a_cada_minutos"]):
		cena._um_minuto()
	assert_eq(cena.ferimentos.texto(), "tronco (leve)")
	cena.free()


func test_de_noite_o_sol_nao_fere() -> void:
	var cena := _cena()
	cena.condicao.adquirir("vampirismo")
	cena.minuto = Relogio.minutos_de(2015, 11, 12, 23, 0)
	for i in int(_cfg()["vampirismo"]["sol_fere_a_cada_minutos"]) * 2:
		cena._um_minuto()
	assert_eq(cena.ferimentos.texto(), "nenhum")
	cena.free()


func test_estigma_quem_ve_desconfia_mesmo_limpo() -> void:
	var limpo := _cena()
	var marcado := _cena()
	marcado.condicao.adquirir("licantropia")
	for cena in [limpo, marcado]:
		# Um transeunte bem do lado.
		var a: Dictionary = cena.transeuntes["valongo"].andantes[0]
		a["no"].visible = true
		a["no"].position = cena.cacador.position
		for i in 30:
			cena._um_minuto()
	assert_eq(limpo.suspeita.pontos("valongo"), 0, "limpo e sem condição, ninguém desconfia")
	assert_true(marcado.suspeita.pontos("valongo") > 0, "com a condição, quem vê desconfia")
	limpo.free()
	marcado.free()


func test_mordida_grave_de_strigoi_pode_passar_vampirismo_na_cidade() -> void:
	var pegou := 0
	for semente in 30:
		var cena := Cena.new()
		cena.montar("valongo", semente)
		cena._mordida(_ficha("strigoi"), "grave")
		if cena.condicao.id == "vampirismo":
			pegou += 1
		cena.free()
	assert_true(pegou > 0 and pegou < 30, "às vezes pega, às vezes não (%d de 30)" % pegou)
