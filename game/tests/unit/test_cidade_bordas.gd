extends "res://tests/framework/test_case.gd"
## Fase 3: bordas entre bairros como em Final Fantasy XII (uma linha no chão, o vizinho à
## vista, carrega ao cruzar) e o minimapa do canto (presentation/cidade).

const Cena := preload("res://presentation/cidade/bairro_cena.gd")
const Minimapa := preload("res://presentation/cidade/minimapa.gd")

var _cena: Node3D


func before_each() -> void:
	_cena = Cena.new()
	_cena.montar("valongo", 1)


func after_each() -> void:
	_cena.free()


func _ids() -> Array:
	var ids: Array = _cena.carregados.keys()
	ids.sort()
	return ids


func _bairros_da_rede() -> Array:
	var ids := {}
	for id in _cena.subterraneo.galerias["corredores_de"]:
		ids[id] = true
	var lista: Array = ids.keys()
	lista.sort()
	return lista


func _cruzar_para(id: String) -> void:
	_cena.cacador.position = _cena.carregados[id].chegada()
	_cena.verificar_fronteira()


func test_comeca_no_bairro_com_o_vizinho_carregado_do_outro_lado() -> void:
	assert_eq(_cena.bairro.dados["id"], "valongo")
	assert_eq(_ids(), ["centro", "valongo"], "o vizinho já está à vista")
	assert_true(_cena.carregados["valongo"].borda.visible, "a linha marca o bairro atual")
	assert_false(_cena.carregados["centro"].borda.visible, "a do vizinho não")
	assert_eq(_bairros_da_rede(), ["centro", "valongo"], "as galerias cobrem o atual e o vizinho, numa rede só")
	assert_eq(_cena.nome_do_lugar.text, "Valongo")


func test_cruzar_a_linha_troca_o_bairro_e_carrega_os_vizinhos_dele() -> void:
	_cruzar_para("centro")
	assert_eq(_cena.bairro.dados["id"], "centro")
	assert_eq(_ids(), ["centro", "monte_serrat", "paqueta", "valongo"])
	assert_true(_cena.carregados["centro"].borda.visible)
	assert_false(_cena.carregados["valongo"].borda.visible)
	# O Monte Serrat só tem escadarias e trilhas: não tem galeria embaixo.
	assert_eq(_bairros_da_rede(), ["centro", "paqueta", "valongo"], "a rede acompanha os bairros carregados")
	assert_eq(_cena.nome_do_lugar.text, "Centro", "o nome do bairro aparece")


func test_quem_fica_longe_e_descarregado() -> void:
	_cruzar_para("centro")
	_cruzar_para("paqueta")
	assert_eq(_ids(), ["centro", "paqueta"], "o Valongo e o Monte Serrat não fazem divisa com o Paquetá")


func test_dentro_do_mesmo_bairro_nada_muda() -> void:
	var antes: Node3D = _cena.bairro
	_cena.cacador.position = _cena.bairro.chegada()
	_cena.verificar_fronteira()
	assert_true(_cena.bairro == antes)


func test_no_esgoto_nao_troca_de_bairro() -> void:
	_cena.usar_bueiro(0)
	_cena.cacador.position = _cena.carregados["centro"].chegada() + Vector3(0, -10, 0)
	_cena.verificar_fronteira()
	assert_eq(_cena.bairro.dados["id"], "valongo", "embaixo da terra, as galerias são do bairro de cima")


func test_minimapa_no_canto_superior_direito() -> void:
	var m: Control = _cena.minimapa
	m._posicionar()
	assert_true(m.position.x + m.size.x <= 640.0 and m.position.x > 320.0, "à direita")
	assert_true(m.position.y < 40.0, "em cima")
	assert_almost_eq(m.size.x, m.size.y, 0.001, "quadrado")


func test_minimapa_gira_com_a_camera() -> void:
	var meio := Vector2(Minimapa.TAMANHO, Minimapa.TAMANHO) / 2.0
	for giro in [0.0, 0.7, PI / 2.0, -2.0]:
		var centro := Vector2(30, -12)
		var frente := Vector2(-sin(giro), -cos(giro))
		assert_true(Minimapa.para_minimapa(centro, centro, giro).distance_to(meio) < 0.001, "o caçador no meio")
		var adiante := Minimapa.para_minimapa(centro + frente * 20.0, centro, giro)
		assert_almost_eq(adiante.x, meio.x, 0.01, "o que está à frente fica na vertical do meio (giro %.1f)" % giro)
		assert_true(adiante.y < meio.y, "e acima dele: para a frente é para cima (giro %.1f)" % giro)
