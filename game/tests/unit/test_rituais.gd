extends "res://tests/framework/test_case.gd"
## Fase 4: rituais com teste de reflexo (core/confronto/ritual.gd, docs/06).

const Ritual := preload("res://core/confronto/ritual.gd")
const Bolsos := preload("res://core/confronto/bolsos.gd")
const Estado := preload("res://core/confronto/estado_criatura.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_rituais()["dados"]


func _def(id: String) -> Dictionary:
	for r in _cfg()["rituais"]:
		if r["id"] == id:
			return r
	return {}


func _ritual(id: String) -> RefCounted:
	return Ritual.new(_def(id), _cfg(), Rng.new(1).stream("ritual"))


## Instante em que o marcador (na ida) está exatamente na posição p.
func _quando(p: float) -> float:
	return p / float(_cfg()["velocidade_do_marcador"])


func test_rituais_config_e_valida_e_cada_um_entrega_uma_fraqueza() -> void:
	assert_eq(Catalogo.carregar_config_rituais()["erros"], [] as Array[String])
	var itens := {}
	for ficha in Catalogo.carregar_criaturas()["criaturas"].values():
		for f in ficha["fraquezas"]:
			itens[f["item"]] = true
	assert_gte(_cfg()["rituais"].size(), 2, "2 a 3 rituais")
	for r in _cfg()["rituais"]:
		assert_true(itens.has(r["item"]), "%s entrega %s, que é fraqueza de alguém" % [r["id"], r["item"]])
		for p in r["passos"]:
			if p["tipo"] == "palavra":
				assert_true(int(p["certa"]) < p["opcoes"].size())


func test_marcador_vai_e_volta() -> void:
	var r := _ritual("sepultamento")
	assert_almost_eq(r.marcador(0.0), 0.0, 0.001)
	assert_almost_eq(r.marcador(_quando(1.0)), 1.0, 0.001)
	assert_almost_eq(r.marcador(_quando(1.0) * 2.0), 0.0, 0.001)


func test_janela_encolhe_com_medo_e_braco_ferido_ate_o_minimo() -> void:
	var r := _ritual("sepultamento")
	var calmo: float = r.largura(0.0, 1.0)
	assert_true(r.largura(1.0, 1.0) < calmo, "medo encolhe")
	assert_true(r.largura(0.0, 1.5) < calmo, "braço ferido encolhe")
	assert_almost_eq(r.largura(1.0, 100.0), float(_cfg()["janela_minima"]), 0.0001)


func test_acertar_o_tempo_avanca_errar_repete() -> void:
	var r := _ritual("sepultamento")
	var errado: float = fposmod(r.centro + 0.5, 1.0)
	assert_false(r.tentar(errado, 0.0, 0.0))
	assert_eq(r.passo, 0, "repete o passo")
	assert_eq(r.erros_de_tempo, 1)
	assert_true(r.tentar(r.centro_em(0.0, 0.0), 0.0, 0.0))
	assert_eq(r.passo, 1)


func test_palavra_errada_faz_o_ritual_falhar() -> void:
	var r := _ritual("sepultamento")
	r.tentar(r.centro, 0.0, 0.0)
	r.tentar(r.centro, 0.0, 0.0)
	assert_eq(r.passo_atual()["tipo"], "palavra")
	assert_false(r.tentar(r.centro, 0.0, 0.0), "palavra não se faz com tempo")
	assert_false(r.escolher(1))
	assert_eq(r.situacao, Ritual.FALHOU)


func test_ritual_inteiro_certo_completa() -> void:
	var r := _ritual("freio_da_mula")
	for p in _def("freio_da_mula")["passos"]:
		if p["tipo"] == "palavra":
			assert_true(r.escolher(int(p["certa"])))
		else:
			assert_true(r.tentar(r.centro, 0.0, 0.0))
	assert_eq(r.situacao, Ritual.COMPLETO)


func test_interrupcao_nao_avanca_o_passo() -> void:
	var r := _ritual("sepultamento")
	r.tentar(r.centro, 0.0, 0.0)
	r.interromper()
	assert_eq(r.passo, 1)
	assert_eq(r.situacao, Ritual.ANDANDO)


func test_materiais_saem_dos_bolsos_e_sem_eles_nao_comeca() -> void:
	var b := Bolsos.new([{"item": "vela", "nome": "Velas", "quantidade": 2}, {"item": "sal_grosso", "nome": "Sal", "quantidade": 1}])
	assert_true(Ritual.gastar_materiais(_def("sepultamento"), b)["ok"])
	assert_eq(b.quantidade("vela"), 0)
	assert_eq(b.quantidade("sal_grosso"), 0)
	var r: Dictionary = Ritual.gastar_materiais(_def("sepultamento"), b)
	assert_false(r["ok"])
	assert_eq(r["falta"], "vela")


# --- Na cidade ---

func _cena_com(especie: String, contida: bool) -> Node3D:
	var cena := Cena.new()
	cena.montar("valongo", 1)
	cena.trazer_criatura(especie)
	cena.criatura.position = cena.cacador.position + Vector3(1.5, -cena.cacador.position.y, 0)
	if contida:
		cena.criatura.estado.estado = Estado.CONTIDA
		cena.criatura.estado.restante = 999.0
	return cena


func _fazer_passos(cena: Node3D, def: Dictionary, palavra_certa: bool = true) -> void:
	for p in def["passos"]:
		if cena.ritual == null:
			return
		match p["tipo"]:
			"palavra":
				cena.escolher_palavra(int(p["certa"]) if palavra_certa else (int(p["certa"]) + 1) % p["opcoes"].size())
			"apertar":
				cena.tempo_do_passo = _quando(cena.ritual.centro)
				cena.apertar_no_ritual()
			"segurar":
				cena.apertar_no_ritual()
				cena.tempo_do_passo = _quando(cena.ritual.centro)
				cena.soltar_no_ritual()


func test_sepultamento_bane_o_corpo_seco_contido() -> void:
	var cena := _cena_com("corpo_seco", true)
	var velas: int = cena.bolsos.quantidade("vela")
	assert_true(cena.abrir_rituais())
	assert_true(cena.cacador.bloqueado, "parado durante o ritual")
	assert_true(cena.comecar_ritual(0))
	assert_eq(cena.bolsos.quantidade("vela"), velas - 2, "gastou as velas")
	_fazer_passos(cena, _def("sepultamento"))
	assert_eq(cena.criatura.estado.estado, Estado.RESOLVIDA)
	assert_eq(cena.criatura.estado.resolucao, "bane")
	assert_false(cena.ritual_tela.visible)
	assert_false(cena.cacador.bloqueado, "solto de novo")
	cena.free()


func test_ritual_errado_para_a_criatura_a_enfurece() -> void:
	var cena := _cena_com("corpo_seco", true)
	cena.abrir_rituais()
	assert_true(cena.comecar_ritual(1), "o freio da mula no corpo-seco")
	_fazer_passos(cena, _def("freio_da_mula"))
	assert_eq(cena.criatura.estado.estado, Estado.LIVRE, "se libertou")
	assert_eq(cena.criatura.estado.agressividade, int(Catalogo.carregar_config_confronto()["dados"]["criatura"]["agressividade_maxima"]))
	cena.free()


func test_criatura_solta_nao_deixa_comecar() -> void:
	var cena := _cena_com("corpo_seco", false)
	cena.abrir_rituais()
	var velas: int = cena.bolsos.quantidade("vela")
	assert_false(cena.comecar_ritual(0))
	assert_eq(cena.bolsos.quantidade("vela"), velas, "não gastou nada")
	cena.free()


func test_longe_da_criatura_nao_abre() -> void:
	var cena := _cena_com("corpo_seco", true)
	cena.criatura.position += Vector3(20, 0, 0)
	assert_false(cena.abrir_rituais())
	assert_false(cena.ritual_tela.visible)
	cena.free()


func test_palavra_errada_na_cidade_perde_os_materiais() -> void:
	var cena := _cena_com("corpo_seco", true)
	cena.abrir_rituais()
	cena.comecar_ritual(0)
	_fazer_passos(cena, _def("sepultamento"), false)
	assert_true(cena.ritual == null, "falhou")
	assert_eq(cena.criatura.estado.estado, Estado.CONTIDA, "nada aconteceu com ela")
	assert_eq(cena.bolsos.quantidade("sal_grosso"), 2, "o sal foi junto")
	cena.free()


func test_ser_atacado_durante_o_ritual_perde_o_passo() -> void:
	var cena := _cena_com("lobisomem_br", false)
	cena.criatura.estado.estado = Estado.CONTIDA
	cena.criatura.estado.restante = 0.05
	cena.abrir_rituais()
	cena.rituais[0]["exige_estado"] = "contida"
	assert_true(cena.comecar_ritual(0))
	cena.tempo_do_passo = _quando(cena.ritual.centro)
	cena.apertar_no_ritual()
	assert_eq(cena.ritual.passo, 1)
	var centro_antes: float = cena.ritual.centro
	# A contenção acaba e o lobisomem ataca.
	for i in 40:
		cena.passar_tempo(0.1)
	assert_ne(cena.ferimentos.texto(), "nenhum", "foi atacado")
	assert_eq(cena.ritual.passo, 1, "o passo atual não avançou")
	assert_ne(cena.ritual.centro, centro_antes, "o passo recomeçou (janela nova)")
	cena.free()
