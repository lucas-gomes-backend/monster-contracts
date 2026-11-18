extends "res://tests/framework/test_case.gd"
## Fase 4: armas, bolsos (menu radial), círculo de sal e a criatura no campo (docs/06).

const Arsenal := preload("res://core/confronto/arsenal.gd")
const Bolsos := preload("res://core/confronto/bolsos.gd")
const Circulo := preload("res://core/confronto/circulo_de_sal.gd")
const Estado := preload("res://core/confronto/estado_criatura.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_armas()["dados"]


func _arsenal(semente: int = 1) -> RefCounted:
	return Arsenal.new(_cfg(), Rng.new(semente).stream("armas"))


func _ficha(id: String) -> Dictionary:
	return Catalogo.carregar_criaturas()["criaturas"][id]


func test_armas_config_e_valida() -> void:
	assert_eq(Catalogo.carregar_config_armas()["erros"], [] as Array[String])


# --- Arsenal ---

func test_espingarda_tem_dois_tiros_e_recarga_lenta() -> void:
	var a := _arsenal()
	assert_eq(a.equipada, "espingarda_de_sal")
	for i in 2:
		assert_true(a.disparar(Vector3.FORWARD, Vector3.ZERO, 0.0)["ok"])
	var r: Dictionary = a.disparar(Vector3.FORWARD, Vector3.ZERO, 0.0)
	assert_false(r["ok"])
	assert_eq(r["motivo"], "sem munição")
	assert_true(a.recarregar())
	assert_false(a.disparar(Vector3.FORWARD, Vector3.ZERO, 0.0)["ok"], "recarregando não atira")
	a.passar(1.0)
	assert_true(a.recarregando > 0.0, "ainda recarregando")
	a.passar(2.0)
	assert_eq(a.municao["espingarda_de_sal"], 2)


func test_braco_ferido_recarrega_mais_devagar() -> void:
	var a := _arsenal()
	a.disparar(Vector3.FORWARD, Vector3.ZERO, 0.0)
	a.recarregar()
	a.passar(2.6, 2.0)
	assert_true(a.recarregando > 0.0, "com o braço ferido, 2,6 s não bastam")


func test_tiro_certeiro_perto_acerta_e_entrega_o_item() -> void:
	var a := _arsenal()
	var r: Dictionary = a.disparar(Vector3.FORWARD, Vector3.FORWARD * 3.0, 0.6)
	assert_true(r["acertou"])
	assert_eq(r["item"], "sal_grosso")


func test_tiro_para_o_lado_ou_longe_demais_erra() -> void:
	var a := _arsenal()
	assert_false(a.disparar(Vector3.FORWARD, Vector3(3, 0, -3), 0.6)["acertou"], "45 graus fora")
	a.recarregar()
	a.passar(5.0)
	assert_false(a.disparar(Vector3.FORWARD, Vector3.FORWARD * 40.0, 0.6)["acertou"], "fora do alcance")


func test_medo_faz_errar_mais() -> void:
	var calmo := _arsenal(3)
	var tremendo := _arsenal(3)
	calmo.equipar("revolver")
	tremendo.equipar("revolver")
	var acertos_calmo := 0
	var acertos_tremendo := 0
	for i in 120:
		calmo.municao["revolver"] = 6
		tremendo.municao["revolver"] = 6
		if calmo.disparar(Vector3.FORWARD, Vector3.FORWARD * 12.0, 0.6, 0.0)["acertou"]:
			acertos_calmo += 1
		if tremendo.disparar(Vector3.FORWARD, Vector3.FORWARD * 12.0, 0.6, 1.0)["acertou"]:
			acertos_tremendo += 1
	assert_true(acertos_tremendo < acertos_calmo, "tremendo %d < calmo %d" % [acertos_tremendo, acertos_calmo])


func test_faca_so_pega_de_perto_e_nao_gasta_municao() -> void:
	var a := _arsenal()
	assert_true(a.equipar("faca"))
	assert_true(a.disparar(Vector3.FORWARD, Vector3.FORWARD * 1.2, 0.6)["acertou"])
	assert_false(a.disparar(Vector3.FORWARD, Vector3.FORWARD * 5.0, 0.6)["acertou"])
	for i in 20:
		assert_true(a.disparar(Vector3.FORWARD, Vector3.ZERO, 0.0)["ok"], "lâmina não acaba")


# --- Bolsos e círculo ---

func test_bolsos_gastam_e_acabam() -> void:
	var b := Bolsos.new(_cfg()["bolsos"])
	var antes: int = b.quantidade("oferenda_fumo_e_cachaca")
	var i := -1
	for j in b.itens.size():
		if b.itens[j]["item"] == "oferenda_fumo_e_cachaca":
			i = j
	assert_eq(b.usar(i), "oferenda_fumo_e_cachaca")
	assert_eq(b.quantidade("oferenda_fumo_e_cachaca"), antes - 1)
	for k in 5:
		b.usar(i)
	assert_eq(b.usar(i), "", "acabou")


func test_menu_radial_escolhe_a_fatia_pela_direcao() -> void:
	assert_eq(Bolsos.fatia(Vector2(0, -1), 8), 0, "em cima")
	assert_eq(Bolsos.fatia(Vector2(1, 0), 8), 2, "à direita")
	assert_eq(Bolsos.fatia(Vector2(0, 1), 8), 4, "embaixo")
	assert_eq(Bolsos.fatia(Vector2(-1, 0), 8), 6, "à esquerda")
	assert_eq(Bolsos.fatia(Vector2(0.05, 0), 8), -1, "parado no meio: nada")


func test_circulo_de_sal_barra_quem_tem_sal_como_fraqueza() -> void:
	assert_true(Circulo.barra(_ficha("corpo_seco")))
	assert_false(Circulo.barra(_ficha("lobisomem_br")))
	var c := Circulo.new(Vector2.ZERO, _cfg()["circulo_de_sal"])
	assert_true(c.dentro(Vector2(0.5, 0)))
	assert_false(c.dentro(Vector2(5, 0)))


func test_circulo_desgasta_mais_rapido_com_chuva_e_pressao() -> void:
	var calmo := Circulo.new(Vector2.ZERO, _cfg()["circulo_de_sal"])
	var chuva := Circulo.new(Vector2.ZERO, _cfg()["circulo_de_sal"])
	var pressao := Circulo.new(Vector2.ZERO, _cfg()["circulo_de_sal"])
	calmo.passar(10.0)
	chuva.passar(10.0, true)
	pressao.passar(10.0, false, true)
	assert_true(chuva.restante < calmo.restante)
	assert_true(pressao.restante < calmo.restante)
	calmo.passar(1000.0)
	assert_false(calmo.ativo(), "uma hora acaba")


# --- Na cidade ---

func _cena() -> Node3D:
	var cena := Cena.new()
	cena.montar("valongo", 1)
	return cena


func _passar(cena: Node3D, segundos: float) -> void:
	for i in int(segundos / 0.1):
		cena.passar_tempo(0.1)


func test_criatura_vem_e_fere_uma_parte_do_corpo() -> void:
	var cena := _cena()
	cena.trazer_criatura("lobisomem_br")
	assert_false(cena.criatura == null)
	_passar(cena, 12.0)
	assert_ne(cena.ferimentos.texto(), "nenhum", "foi ferido")
	assert_true(cena.medo.valor > 0.0, "e ficou com medo")
	cena.free()


func test_circulo_de_sal_segura_o_corpo_seco_mas_nao_o_lobisomem() -> void:
	for especie in ["corpo_seco", "lobisomem_br"]:
		var cena := _cena()
		cena.usar_bolso(0)
		assert_eq(cena.circulos.size(), 1, "sal no chão")
		cena.trazer_criatura(especie)
		_passar(cena, 12.0)
		var c: RefCounted = cena.circulos[0] if not cena.circulos.is_empty() else null
		if especie == "corpo_seco":
			assert_eq(cena.ferimentos.texto(), "nenhum", "o corpo-seco não entra no círculo")
			var dist: float = Vector2(cena.criatura.position.x, cena.criatura.position.z).distance_to(c.centro)
			assert_true(dist >= c.raio, "parou na linha (%.2f)" % dist)
			assert_true(c.restante < float(_cfg()["circulo_de_sal"]["dura"]) - 12.0, "pressionando, o sal gasta mais rápido")
		else:
			assert_ne(cena.ferimentos.texto(), "nenhum", "o lobisomem passa por cima do sal")
		cena.free()


func test_oferenda_de_perto_apazigua_o_curupira() -> void:
	var cena := _cena()
	cena.trazer_criatura("curupira")
	cena.criatura.position = cena.cacador.position + Vector3(1.5, -cena.cacador.position.y, 0)
	var i := -1
	for j in cena.bolsos.itens.size():
		if cena.bolsos.itens[j]["item"] == "oferenda_fumo_e_cachaca":
			i = j
	cena.usar_bolso(i)
	assert_eq(cena.criatura.estado.estado, Estado.RESOLVIDA)
	cena.passar_tempo(0.1)
	assert_false(cena.criatura.visible, "foi embora")
	cena.free()


func test_item_sem_criatura_perto_volta_para_o_bolso() -> void:
	var cena := _cena()
	var antes: int = cena.bolsos.itens[1]["quantidade"]
	cena.usar_bolso(1)
	assert_eq(cena.bolsos.itens[1]["quantidade"], antes, "não gastou à toa")
	cena.free()


func test_bandagem_trata_o_pior_ferimento() -> void:
	var cena := _cena()
	cena.ferimentos.receber("tronco", "critico")
	var i := -1
	for j in cena.bolsos.itens.size():
		if cena.bolsos.itens[j]["item"] == "bandagem":
			i = j
	cena.usar_bolso(i)
	assert_eq(cena.ferimentos.texto(), "tronco (grave)")
	cena.free()


func test_tiro_de_sal_prende_o_corpo_seco_e_o_tiro_faz_barulho() -> void:
	var cena := _cena()
	(Engine.get_main_loop() as SceneTree).root.add_child(cena)
	cena.trazer_criatura("corpo_seco")
	var camera: Camera3D = cena.cacador.camera
	var frente := -camera.global_basis.z
	cena.criatura.global_position = camera.global_position + frente * 3.0 - Vector3(0, 1.0, 0)
	cena.cacador.mirando = true
	var a: Dictionary = cena.transeuntes["valongo"].andantes[0]
	a["no"].visible = true
	a["no"].position = cena.cacador.position + Vector3(2, 0, 0)
	var r: Dictionary = cena.atirar()
	assert_true(r["acertou"], "acertou de perto")
	assert_eq(cena.criatura.estado.estado, Estado.CONTIDA, "sal prende o corpo-seco")
	assert_true(cena.suspeita.pontos("valongo") > 0, "alguém ouviu o tiro")
	assert_has(cena.texto_do_hud(), "Criatura: contida")
	cena.get_parent().remove_child(cena)
	cena.free()


func test_sem_mirar_a_arma_de_fogo_nao_dispara() -> void:
	var cena := _cena()
	cena.cacador.mirando = false
	assert_eq(cena.atirar(), {})
	assert_eq(cena.arsenal.municao["espingarda_de_sal"], 2)
	cena.free()
