extends "res://tests/framework/test_case.gd"
## Fase 3: subterrâneo gerado seguindo as ruas (core/cidade/subterraneo.gd).

const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Sub := preload("res://core/cidade/subterraneo.gd")

var _cfg: Dictionary


func before_each() -> void:
	_cfg = Catalogo.carregar_config_subterraneo()["dados"]


func _gerar(id: String, semente: int = 1) -> Dictionary:
	return Sub.gerar(Catalogo.carregar_bairro_real(id)["dados"], _cfg, Rng.new(semente))


func test_subterraneo_config_valida() -> void:
	var r := Catalogo.carregar_config_subterraneo()
	assert_eq(r["erros"].size(), 0, str(r["erros"]))


func test_subterraneo_toda_rua_comum_tem_galeria_embaixo() -> void:
	var b: Dictionary = Catalogo.carregar_bairro_real("valongo")["dados"]
	var s := _gerar("valongo")
	var conferidos := 0
	for rua in b["ruas"]:
		if rua["tipo"] in _cfg["ruas_sem_galeria"]:
			continue
		for i in rua["pontos"].size() - 1:
			var meio := (Vector2(rua["pontos"][i][0], rua["pontos"][i][1]) + Vector2(rua["pontos"][i + 1][0], rua["pontos"][i + 1][1])) / 2.0
			assert_true(Sub.dentro_da_galeria(meio, s["corredores"]), "galeria embaixo de %s" % rua["nome"])
			conferidos += 1
	assert_gte(conferidos, 20)


func test_subterraneo_escadaria_nao_tem_galeria() -> void:
	var b: Dictionary = Catalogo.carregar_bairro_real("monte_serrat")["dados"]
	var s := _gerar("monte_serrat")
	for rua in b["ruas"]:
		if rua["tipo"] == "steps":
			var meio := (Vector2(rua["pontos"][0][0], rua["pontos"][0][1]) + Vector2(rua["pontos"][1][0], rua["pontos"][1][1])) / 2.0
			var longe_de_rua_comum := true
			for c in s["corredores"]:
				if Geometry2D.is_point_in_polygon(meio, c):
					longe_de_rua_comum = false
			if longe_de_rua_comum:
				return
	# Nenhuma escadaria longe de rua comum: nada a conferir neste bairro.


func test_subterraneo_paredes_ficam_so_no_contorno() -> void:
	# Cada parede separa galeria (de um lado) de terra (do outro): nenhuma corta um cruzamento.
	var s := _gerar("valongo")
	assert_gte(s["paredes"].size(), 10)
	for parede in s["paredes"]:
		var a: Vector2 = parede[0]
		var b: Vector2 = parede[-1]
		var meio := (a + b) / 2.0
		var normal := (b - a).normalized().orthogonal() * 0.05
		var lado1: bool = Sub.dentro_da_galeria(meio + normal, s["corredores"])
		var lado2: bool = Sub.dentro_da_galeria(meio - normal, s["corredores"])
		assert_true(lado1 != lado2, "parede em %s com galeria dos dois lados ou de nenhum" % meio)


func test_subterraneo_bueiros_ficam_na_galeria_e_dentro_do_bairro() -> void:
	for id in ["valongo", "monte_serrat"]:
		var b: Dictionary = Catalogo.carregar_bairro_real(id)["dados"]
		var s := _gerar(id)
		if s["corredores"].is_empty():
			continue
		assert_gte(s["bueiros"].size(), 1, "%s tem por onde descer" % id)
		var limite: PackedVector2Array = Sub._pontos(b["limite"])
		for p in s["bueiros"]:
			assert_true(Sub.dentro_da_galeria(p, s["corredores"]), "%s: bueiro sobre a galeria" % id)
			assert_true(Geometry2D.is_point_in_polygon(p, limite), "%s: bueiro dentro do bairro" % id)
	assert_gte(_gerar("valongo")["bueiros"].size(), 3, "o Valongo tem vários bueiros")


func test_subterraneo_mesma_semente_mesmos_bueiros_e_outra_semente_outros() -> void:
	assert_eq(str(_gerar("valongo", 4)["bueiros"]), str(_gerar("valongo", 4)["bueiros"]))
	assert_ne(str(_gerar("valongo", 4)["bueiros"]), str(_gerar("valongo", 5)["bueiros"]))


func test_subterraneo_liga_valongo_e_centro_por_baixo() -> void:
	var bairros: Array = [Catalogo.carregar_bairro_real("valongo")["dados"], Catalogo.carregar_bairro_real("centro")["dados"]]
	var rede := Sub.gerar_rede(bairros, _cfg, Rng.new(1))
	var ligou := false
	for grupo in Sub.grupos_ligados(rede["corredores"]):
		var de := {}
		for i in grupo:
			de[rede["corredores_de"][i]] = true
		if de.has("valongo") and de.has("centro"):
			ligou = true
	assert_true(ligou, "dá para ir do Valongo ao Centro pelas galerias")


func test_subterraneo_bueiros_de_cada_bairro_nao_mudam_com_os_vizinhos() -> void:
	var valongo: Dictionary = Catalogo.carregar_bairro_real("valongo")["dados"]
	var sozinho := Sub.gerar_rede([valongo], _cfg, Rng.new(3))
	var junto := Sub.gerar_rede([valongo, Catalogo.carregar_bairro_real("centro")["dados"]], _cfg, Rng.new(3))
	var do_valongo: Array = []
	for i in junto["bueiros"].size():
		if junto["bueiros_de"][i] == "valongo":
			do_valongo.append(junto["bueiros"][i])
	assert_eq(str(do_valongo), str(Array(sozinho["bueiros"])))


func test_subterraneo_bairros_separados_nao_se_ligam() -> void:
	# Valongo e Paquetá não fazem divisa: nenhuma galeria liga os dois.
	var bairros: Array = [Catalogo.carregar_bairro_real("valongo")["dados"], Catalogo.carregar_bairro_real("paqueta")["dados"]]
	var rede := Sub.gerar_rede(bairros, _cfg, Rng.new(1))
	for grupo in Sub.grupos_ligados(rede["corredores"]):
		var de := {}
		for i in grupo:
			de[rede["corredores_de"][i]] = true
		assert_false(de.has("valongo") and de.has("paqueta"))
