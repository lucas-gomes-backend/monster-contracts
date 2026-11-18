extends "res://tests/framework/test_case.gd"
## Fase 4: negociação e apaziguamento com o Curupira (core/confronto/negociacao.gd, docs/06).

const Negociacao := preload("res://core/confronto/negociacao.gd")
const Bolsos := preload("res://core/confronto/bolsos.gd")
const Estado := preload("res://core/confronto/estado_criatura.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_negociacao()["dados"]


func _ficha(id: String) -> Dictionary:
	return Catalogo.carregar_criaturas()["criaturas"][id]


func _com_personalidade(p: String, cfg: Dictionary = {}) -> RefCounted:
	var c := cfg if not cfg.is_empty() else _cfg()
	for semente in 200:
		var n := Negociacao.new(_ficha("curupira"), "desmatamento", c, Rng.new(semente).stream("negociacao"))
		if n.personalidade == p:
			return n
	return null


func _indice(id: String) -> int:
	var ofertas: Array = _cfg()["ofertas"]
	for i in ofertas.size():
		if ofertas[i]["id"] == id:
			return i
	return -1


func _bolsos_com_oferenda() -> RefCounted:
	return Bolsos.new([{"item": "oferenda_fumo_e_cachaca", "nome": "Fumo e cachaça", "quantidade": 1}])


func test_negociacao_config_e_valida() -> void:
	assert_eq(Catalogo.carregar_config_negociacao()["erros"], [] as Array[String])


func test_so_negocia_quem_e_esperto_e_nao_hostil() -> void:
	assert_true(Negociacao.pode(_ficha("curupira")))
	for id in ["lobisomem_br", "corpo_seco", "mula_sem_cabeca", "golpe_humano"]:
		assert_false(Negociacao.pode(_ficha(id)), id)


func test_a_criatura_abre_cobrando_o_gatilho_do_caso() -> void:
	var n := Negociacao.new(_ficha("curupira"), "desmatamento", _cfg(), Rng.new(1).stream("negociacao"))
	assert_has(n.ultima_fala, _cfg()["exigencias"]["desmatamento"])
	assert_has(n.ultima_fala, _cfg()["abertura"][n.personalidade])


func test_personalidade_sai_da_semente() -> void:
	var vistas := {}
	for semente in 40:
		vistas[Negociacao.new(_ficha("curupira"), "desmatamento", _cfg(), Rng.new(semente).stream("negociacao")).personalidade] = true
	assert_gte(vistas.size(), 3, "personalidades variam")
	var a := Negociacao.new(_ficha("curupira"), "desmatamento", _cfg(), Rng.new(9).stream("negociacao"))
	var b := Negociacao.new(_ficha("curupira"), "desmatamento", _cfg(), Rng.new(9).stream("negociacao"))
	assert_eq(a.personalidade, b.personalidade)


func test_cada_personalidade_tem_um_caminho_para_o_acordo() -> void:
	var caminhos := {"orgulhosa": "pedir_licenca", "curiosa": "contar_a_verdade", "ressentida": "contar_a_verdade", "faminta": "dar_oferenda"}
	for p in caminhos:
		var n := _com_personalidade(p)
		assert_false(n == null, p)
		n.oferecer(_indice(caminhos[p]), _bolsos_com_oferenda())
		assert_eq(n.satisfacao, 1, "%s gostou" % p)
		n.oferecer(_indice("prometer_justica"))
		assert_eq(n.situacao, Negociacao.ACORDO, p)
		assert_eq(n.termos.size(), 1, "o acordo tem termo (custo)")


func test_prometer_sem_agradar_antes_nao_fecha() -> void:
	var n := _com_personalidade("orgulhosa")
	var antes: int = n.paciencia
	n.oferecer(_indice("prometer_justica"))
	assert_eq(n.situacao, Negociacao.CONVERSANDO)
	assert_eq(n.paciencia, antes - 1)


func test_ameacar_ofende_e_esgota_a_paciencia() -> void:
	var n := _com_personalidade("curiosa")
	n.oferecer(_indice("ameacar"))
	assert_eq(n.paciencia, int(_cfg()["paciencia_inicial"]) - 2)
	n.oferecer(_indice("ameacar"))
	assert_eq(n.situacao, Negociacao.RECUSA)


func test_oferenda_sem_ter_no_bolso_nao_conta() -> void:
	var n := _com_personalidade("faminta")
	var antes: int = n.paciencia
	n.oferecer(_indice("dar_oferenda"), Bolsos.new([{"item": "sal_grosso", "nome": "Sal", "quantidade": 1}]))
	assert_eq(n.ultima_fala, _cfg()["falas"]["sem_item"])
	assert_eq(n.paciencia, antes)
	assert_eq(n.satisfacao, 0)


func test_oferenda_dada_sai_do_bolso() -> void:
	var n := _com_personalidade("faminta")
	var b := _bolsos_com_oferenda()
	n.oferecer(_indice("dar_oferenda"), b)
	assert_eq(b.quantidade("oferenda_fumo_e_cachaca"), 0)


func test_criatura_ardilosa_pode_trair_o_acordo() -> void:
	var cfg := _cfg().duplicate(true)
	cfg["chance_de_traicao"]["astuta"] = 1.0
	var n := _com_personalidade("orgulhosa", cfg)
	n.oferecer(_indice("pedir_licenca"))
	n.oferecer(_indice("prometer_justica"))
	assert_eq(n.situacao, Negociacao.ACORDO, "parece acordo")
	assert_true(n.traira, "mas vai trair")
	cfg["chance_de_traicao"]["astuta"] = 0.0
	var honesta := _com_personalidade("orgulhosa", cfg)
	honesta.oferecer(_indice("pedir_licenca"))
	honesta.oferecer(_indice("prometer_justica"))
	assert_false(honesta.traira, "sem chance, cumpre")


# --- Na cidade ---

func _cena(especie: String) -> Node3D:
	var cena := Cena.new()
	cena.montar("valongo", 1)
	cena.trazer_criatura(especie)
	cena.criatura.position = cena.cacador.position + Vector3(2.0, -cena.cacador.position.y, 0)
	return cena


func test_conversando_ela_escuta_e_o_acordo_resolve() -> void:
	var cena := _cena("curupira")
	assert_true(cena.conversar())
	assert_true(cena.conversa_tela.visible)
	for i in 50:
		cena.passar_tempo(0.1)
	assert_eq(cena.ferimentos.texto(), "nenhum", "escutando, não ataca")
	var caminho := {"orgulhosa": "pedir_licenca", "curiosa": "contar_a_verdade", "ressentida": "contar_a_verdade", "faminta": "dar_oferenda"}
	cena.oferecer(_indice(caminho[cena.negociacao.personalidade]))
	cena.oferecer(_indice("prometer_justica"))
	assert_eq(cena.criatura.estado.estado, Estado.RESOLVIDA)
	assert_eq(cena.criatura.estado.resolucao, "negocia")
	assert_eq(cena.acordos.size(), 1)
	assert_false(cena.conversa_tela.visible)
	cena.free()


func test_recusa_vira_confronto() -> void:
	var cena := _cena("curupira")
	cena.conversar()
	cena.oferecer(_indice("ameacar"))
	cena.oferecer(_indice("ameacar"))
	assert_eq(cena.criatura.estado.estado, Estado.LIVRE)
	assert_eq(cena.criatura.estado.agressividade, 1, "mais agressiva")
	assert_true(cena.negociacao == null)
	cena.free()


func test_lobisomem_nao_conversa() -> void:
	var cena := _cena("lobisomem_br")
	assert_false(cena.conversar())
	assert_false(cena.conversa_tela.visible)
	cena.free()


func test_curupira_furioso_nao_aceita_a_oferenda() -> void:
	var cena := _cena("curupira")
	cena.criatura.estado.agressividade = 3
	var i := -1
	for j in cena.bolsos.itens.size():
		if cena.bolsos.itens[j]["item"] == "oferenda_fumo_e_cachaca":
			i = j
	cena.usar_bolso(i)
	assert_eq(cena.criatura.estado.estado, Estado.LIVRE, "não se acalmou")
	assert_eq(cena.bolsos.itens[i]["quantidade"], 1, "a oferenda volta para o bolso")
	cena.criatura.estado.agressividade = 0
	cena.usar_bolso(i)
	assert_eq(cena.criatura.estado.estado, Estado.RESOLVIDA, "calma, aceita")
	cena.free()
