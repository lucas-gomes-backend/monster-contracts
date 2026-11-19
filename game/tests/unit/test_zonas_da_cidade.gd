extends "res://tests/framework/test_case.gd"
## Fase 5: zonas da cidade (docs/07, "Bairros"), começando pela Central e portuária e pela orla.
## Todo bairro de uma zona que já entrou no jogo tem o traçado real, os dados de conteúdo e gera
## casos; principais têm mais gente e pontos-chave próprios; secundários são menores.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Gerador := preload("res://core/casos/gerador_casos.gd")


func _zonas() -> Dictionary:
	return Catalogo.carregar_config_zonas()["dados"]["zonas"]


func _bairros() -> Array:
	var todos := []
	for z in _zonas().values():
		todos += z["principais"] + z["secundarios"]
	return todos


func _zona_de(id: String) -> String:
	for z in _zonas():
		if id in _zonas()[z]["principais"] + _zonas()[z]["secundarios"]:
			return z
	return ""


func test_as_zonas_central_e_da_orla_estao_no_jogo() -> void:
	assert_has(_zonas(), "central_portuaria")
	assert_has(_zonas(), "orla")
	assert_has(_zonas()["orla"]["principais"], "gonzaga")
	assert_has(_zonas()["orla"]["principais"], "ponta_da_praia")


func test_config_de_zonas_e_valida_e_nao_repete_bairro() -> void:
	assert_eq(Catalogo.carregar_config_zonas()["erros"], [] as Array[String])
	var vistos := {}
	var pendentes := []
	for z in _zonas().values():
		pendentes += z["pendentes"]
	for id in _bairros() + pendentes:
		assert_false(vistos.has(id), "%s aparece uma vez só" % id)
		vistos[id] = true


func test_todo_bairro_da_zona_tem_tracado_e_conteudo_da_zona() -> void:
	var reais := Catalogo.bairros_reais()
	for id in _bairros():
		assert_has(reais, id, "%s: traçado do mapa real" % id)
		var r := Catalogo.carregar_bairro(id)
		assert_eq(r["erros"].size(), 0, "%s: %s" % [id, r["erros"]])
		assert_eq(r["dados"]["zona"], _zona_de(id), id)


func test_ruas_dos_lugares_existem_no_mapa_real() -> void:
	for id in _bairros():
		var real: Dictionary = Catalogo.carregar_bairro_real(id)["dados"]
		var ruas := {}
		for rua in real["ruas"]:
			ruas[_slug(str(rua["nome"]))] = true
		for local in Catalogo.carregar_bairro(id)["dados"]["locais"]:
			assert_true(ruas.has(local["rua"]), "%s: %s fica na %s, que existe" % [id, local["id"], local["rua"]])


func test_principais_tem_mais_gente_e_pontos_chave_que_os_secundarios() -> void:
	for z in _zonas():
		_principais_maiores(_zonas()[z])


func _principais_maiores(zona: Dictionary) -> void:
	var menor_principal := 1000
	var maior_secundario := 0
	for id in zona["principais"]:
		var b: Dictionary = Catalogo.carregar_bairro(id)["dados"]
		menor_principal = mini(menor_principal, int(b["populacao_alvo"]))
		var tipos := {}
		for l in b["locais"]:
			tipos[l["tipo"]] = true
		assert_true(tipos.has("igreja") or tipos.has("cemiterio") or tipos.has("delegacia"), "%s tem ponto-chave próprio" % id)
	for id in zona["secundarios"]:
		maior_secundario = maxi(maior_secundario, int(Catalogo.carregar_bairro(id)["dados"]["populacao_alvo"]))
	assert_gte(menor_principal, 30, "principal: 30 a 60 moradores")
	assert_true(maior_secundario < menor_principal, "secundário tem menos gente")


func test_casos_nascem_em_todo_bairro_da_zona() -> void:
	for id in _bairros():
		var validos := 0
		for s in range(1, 6):
			if Gerador.gerar(s, id).get("valido", false):
				validos += 1
		assert_gte(validos, 1, "%s gera caso válido" % id)


func test_a_zona_toda_comeca_liberada() -> void:
	var liberadas: Array = Catalogo.carregar_config_progressao()["dados"]["regioes_liberadas"]
	for id in _bairros():
		assert_has(liberadas, id)


func _slug(nome: String) -> String:
	return load("res://core/cidade/lugares_reais.gd").slug(nome)
