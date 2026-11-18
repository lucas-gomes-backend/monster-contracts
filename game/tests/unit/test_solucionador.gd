extends "res://tests/framework/test_case.gd"
## Solucionador automático (core/casos/solucionador.gd). Parte com casos gerados, parte com
## casos gerados e depois "estragados" de propósito, para provar que ele reprova.

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Solucionador := preload("res://core/casos/solucionador.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")

const SEMENTES := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]


func _criaturas() -> Dictionary:
	return Catalogo.carregar_criaturas()["criaturas"]


func test_solucionador_todo_caso_entregue_e_justo() -> void:
	for semente in SEMENTES:
		var caso := Gerador.gerar(semente)
		assert_true(caso.get("valido", false), "semente %d gerou caso" % semente)
		if not caso.get("valido", false):
			continue
		var v := Solucionador.validar(caso, _criaturas(), "antigo_religioso")
		assert_true(v["valido"], "semente %d: %s" % [semente, str(v["motivos"])])
		assert_eq(v["candidatos"], [caso["verdade"]["especie"]], "semente %d: sobra só a verdadeira" % semente)


## Caso mínimo montado à mão: lobisomem, sem hospedeiro, só com as marcas pedidas.
func _caso_com_marcas(tags: Array) -> Dictionary:
	var pistas: Array = []
	for tag in tags:
		pistas.append({"id": "pista_%s" % tag, "tipo": "marca", "tag": tag, "detectar": "olho_nu", "valida_ate": -1, "local": "", "minuto": 0})
	return {
		"verdade": {"especie": "lobisomem_br", "hospedeiro": ""},
		"contrato": {"minuto": 100},
		"pistas": pistas,
		"depoimentos": [],
		"registro": null,
	}


func test_solucionador_uma_so_evidencia_nao_basta() -> void:
	var v := Solucionador.validar(_caso_com_marcas(["pegadas_cao_grande"]), _criaturas(), "antigo_religioso")
	assert_false(v["valido"], "perder essa pista travaria o caso")


func test_solucionador_duas_evidencias_distintas_bastam() -> void:
	var v := Solucionador.validar(_caso_com_marcas(["pegadas_cao_grande", "galinheiro_atacado"]), _criaturas(), "antigo_religioso")
	assert_true(v["valido"], str(v["motivos"]))


func test_solucionador_sem_evidencias_o_caso_e_injusto() -> void:
	var caso := Gerador.gerar(3).duplicate()
	caso["pistas"] = []
	caso["depoimentos"] = []
	var v := Solucionador.validar(caso, _criaturas(), "antigo_religioso")
	assert_false(v["valido"])


func test_solucionador_pistas_vencidas_nao_contam() -> void:
	var caso := Gerador.gerar(4).duplicate()
	var vencidas: Array = []
	for pista in caso["pistas"]:
		var p: Dictionary = pista.duplicate()
		p["valida_ate"] = int(caso["contrato"]["minuto"]) - 1
		vencidas.append(p)
	caso["pistas"] = vencidas
	var evidencias := Solucionador.coletar_evidencias(caso)
	for ev in evidencias:
		if str(ev["fonte"]).begins_with("pista_"):
			fail("pista vencida virou evidência: %s" % ev["fonte"])


func test_solucionador_pista_de_laboratorio_nao_conta_para_iniciante() -> void:
	var caso := Gerador.gerar(5).duplicate()
	caso["pistas"] = [{"id": "pista_x", "tipo": "marca", "tag": "pelos_escuros_grossos", "detectar": "laboratorio", "valida_ate": -1, "local": "", "minuto": 0}]
	caso["depoimentos"] = []
	assert_eq(Solucionador.coletar_evidencias(caso), [])


func test_solucionador_ruido_nao_descarta_ninguem() -> void:
	var caso := Gerador.gerar(6).duplicate()
	var so_ruido: Array = []
	for pista in caso["pistas"]:
		if pista["origem"] == "ruido" and pista["tipo"] == "marca":
			var p: Dictionary = pista.duplicate()
			p["valida_ate"] = -1  # garante que a pista de ruído conta como evidência
			so_ruido.append(p)
	caso["pistas"] = so_ruido
	caso["depoimentos"] = []
	assert_gte(Solucionador.coletar_evidencias(caso).size(), 1, "há evidência de ruído")
	var v := Solucionador.validar(caso, _criaturas(), "antigo_religioso")
	var do_paqueta := 0
	for ficha in _criaturas().values():
		if Solucionador.vive_no_bairro(ficha, "antigo_religioso"):
			do_paqueta += 1
	assert_gte(do_paqueta, 4)
	assert_eq(v["candidatos"].size(), do_paqueta, "só com ruído, nenhuma espécie do Paquetá é descartada")


func test_solucionador_um_boletim_nao_vira_padrao() -> void:
	var caso := Gerador.gerar(7).duplicate()
	var um_boletim: Array = []
	for pista in caso["pistas"]:
		if pista["tipo"] == "registro" and not pista.has("tag"):
			um_boletim.append(pista)
			break
	caso["pistas"] = um_boletim
	caso["depoimentos"] = []
	for ev in Solucionador.coletar_evidencias(caso):
		assert_ne(ev["fonte"], "padrao_de_boletins", "um boletim só é coincidência")
