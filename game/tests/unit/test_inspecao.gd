extends "res://tests/framework/test_case.gd"
## Fase 2: lanterna, mira, exame de pistas (pegar e girar) e câmera fotográfica.
## Sem abrir janela: as contas são conferidas direto e a rua é montada fora da árvore.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Mira := preload("res://presentation/inspecao/mira.gd")
const Album := preload("res://presentation/inspecao/album.gd")
const Cacador := preload("res://presentation/personagem/cacador.gd")
const Rua := preload("res://presentation/greybox/rua.gd")

var _cfg: Dictionary


func before_each() -> void:
	_cfg = Catalogo.carregar_config_inspecao()["dados"]


## A rua montada para a semente 12, no bar: lá há um caco de vidro (pega) e sangue (não pega).
func _rua_no_bar() -> Node3D:
	var rua := Rua.new()
	rua.montar(12)
	rua.ir_para("paqueta/bar")
	return rua


func _indice(rua: Node3D, pegavel: bool) -> int:
	for i in rua.pistas.size():
		if rua.pistas[i].pegavel == pegavel:
			return i
	return -1


func test_inspecao_config_rua_e_aparencia_das_marcas_sao_validas() -> void:
	assert_eq(Catalogo.carregar_config_inspecao()["erros"].size(), 0)
	var rua := Catalogo.carregar_greybox("rua")
	assert_eq(rua["erros"].size(), 0, str(rua["erros"]))
	assert_gte(rua["dados"]["pontos_de_pista"].size(), 3, "há onde pôr as pistas na rua")
	var aparencia := Catalogo.carregar_aparencia_marcas()
	assert_eq(aparencia["erros"].size(), 0, str(aparencia["erros"]))


func test_mira_escolhe_a_pista_mais_perto_do_centro() -> void:
	var pontos := [Vector3(0.5, 0, -1.5), Vector3(0.05, 0, -1.5), Vector3(-0.6, 0, -1.4)]
	assert_eq(Mira.escolher_alvo(Vector3.ZERO, Vector3.FORWARD, Vector3.ZERO, pontos, 3.0, 30.0), 1)


func test_mira_alcance_conta_do_corpo_e_angulo_do_olho() -> void:
	# A pista está bem no centro da mira, mas longe do corpo: não dá para pegar.
	var pontos := [Vector3(0, 0, -5)]
	assert_eq(Mira.escolher_alvo(Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, 2), pontos, 2.0, 30.0), -1)
	# Perto do corpo e no centro: dá.
	assert_eq(Mira.escolher_alvo(Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, -4), pontos, 2.0, 30.0), 0)
	# Perto do corpo, mas fora do ângulo da mira: não dá.
	assert_eq(Mira.escolher_alvo(Vector3.ZERO, Vector3.RIGHT, Vector3(0, 0, -4), pontos, 2.0, 30.0), -1)


func test_foto_pega_so_o_que_esta_no_quadro_e_no_alcance() -> void:
	var pontos := [Vector3(0, 0, -3), Vector3(0, 0, 3), Vector3(0, 0, -30), Vector3(3, 0, -3)]
	var dentro := Mira.no_quadro(Vector3.ZERO, Vector3.FORWARD, pontos, 8.0, 45.0)
	assert_eq(dentro, [0] as Array[int], "só a da frente, perto e no centro")


func test_girar_limita_a_inclinacao_e_da_a_volta_no_giro() -> void:
	var r := Mira.girar(Vector2.ZERO, Vector2(0, 10000), 0.5)
	assert_eq(r.x, 80.0, "inclinação para no limite")
	r = Mira.girar(Vector2(0, 170), Vector2(40, 0), 0.5)
	assert_almost_eq(r.y, -170.0, 0.0001, "o giro dá a volta")


func test_album_filme_acaba_e_marcas_nao_se_repetem() -> void:
	var album := Album.new(2)
	var foto := album.fotografar(["b", "a", "b"])
	assert_eq(foto["numero"], 1)
	assert_eq(foto["marcas"], ["a", "b"] as Array[String])
	album.fotografar(["c"])
	assert_eq(album.restantes(), 0)
	assert_eq(album.fotografar(["d"]), {}, "sem filme não há foto")
	assert_eq(album.marcas_registradas(), ["a", "b", "c"] as Array[String])


func test_lanterna_comeca_desligada_e_f_liga_mas_nao_durante_o_exame() -> void:
	var cacador := Cacador.new()
	cacador.montar()
	assert_false(cacador.lanterna.visible, "começa desligada")
	assert_almost_eq(cacador.lanterna.spot_range, _cfg["lanterna_alcance"], 0.0001)
	assert_true(cacador.lanterna.get_parent() == cacador.inclinacao, "gira junto com a câmera")
	assert_true(cacador.lanterna.position.z < 0.0, "sai da frente do corpo, não das costas")
	var tecla := InputEventAction.new()
	tecla.action = "lanterna"
	tecla.pressed = true
	cacador._unhandled_input(tecla)
	assert_true(cacador.lanterna.visible, "F liga")
	cacador.bloqueado = true
	cacador._unhandled_input(tecla)
	assert_true(cacador.lanterna.visible, "examinando, F não faz nada")
	for acao in Cacador.ACOES_MOUSE:
		assert_true(InputMap.has_action(acao), "ação %s existe" % acao)
	cacador.free()


func test_mira_aproxima_a_camera_e_fecha_o_campo() -> void:
	var personagem: Dictionary = Catalogo.carregar_config_personagem()["dados"]
	var normal := Cacador.camera_alvo(false, personagem, _cfg)
	var mirando := Cacador.camera_alvo(true, personagem, _cfg)
	assert_true(mirando.x < normal.x, "a câmera chega mais perto")
	assert_true(mirando.y < normal.y, "o campo de visão fecha")


func test_rua_cada_pista_do_caso_no_lugar_esta_no_mundo_com_o_texto_da_marca() -> void:
	var rua := _rua_no_bar()
	var no_local: Array = rua.sessao.pistas_no_local()
	var textos: Dictionary = Catalogo.carregar_textos_marcas()["dados"]
	assert_gte(no_local.size(), 2, "o bar da semente 12 tem pistas")
	assert_eq(rua.pistas.size(), no_local.size(), "uma pista no mundo para cada pista do caso no lugar")
	for i in no_local.size():
		assert_eq(rua.pistas[i].pista_id, no_local[i]["id"])
		assert_eq(rua.pistas[i].texto, textos[no_local[i]["tag"]]["pista"], "texto da marca %s" % no_local[i]["tag"])
	rua.free()


func test_rua_pegar_pista_abre_o_exame_trava_o_cacador_e_soltar_devolve() -> void:
	var rua := _rua_no_bar()
	var i := _indice(rua, true)
	var pista: Node3D = rua.pistas[i]
	rua.examinar(i)
	assert_true(rua.exame.aberto, "exame aberto")
	assert_true(rua.cacador.bloqueado, "o caçador para")
	assert_false(pista.visible, "a pista está na mão")
	assert_true(rua.exame.visor.visible, "aparece em close")
	assert_eq(rua.exame.descricao.text, pista.texto)
	var antes: Vector3 = rua.exame.objeto.rotation_degrees
	rua.exame.girar_por(Vector2(30, 10))
	assert_ne(rua.exame.objeto.rotation_degrees, antes, "arrastar gira a pista")
	rua.fechar_exame()
	assert_false(rua.exame.aberto)
	assert_false(rua.cacador.bloqueado)
	assert_true(pista.visible, "a pista volta ao lugar")
	rua.free()


func test_rua_pista_do_chao_e_examinada_no_lugar() -> void:
	var rua := _rua_no_bar()
	var i := _indice(rua, false)
	rua.examinar(i)
	assert_true(rua.exame.aberto)
	assert_false(rua.exame.visor.visible, "sem close: não dá para pegar pegadas")
	assert_true(rua.pistas[i].visible, "continua no chão")
	rua.fechar_exame()
	rua.free()


func test_rua_pista_ao_alcance_e_na_mira_vira_alvo() -> void:
	var rua := _rua_no_bar()
	var pista: Node3D = rua.pistas[0]
	rua.cacador.position = pista.position + Vector3(0, 0, 1.0)
	var olho: Vector3 = pista.position + Vector3(0, 1.8, 3.5)
	assert_eq(rua.alvo_na_mira(olho, (pista.position - olho).normalized()), 0, "olhando para ela")
	assert_eq(rua.alvo_na_mira(olho, Vector3.UP), -1, "olhando para o céu")
	rua.cacador.position = pista.position + Vector3(0, 0, 20.0)
	assert_eq(rua.alvo_na_mira(olho, (pista.position - olho).normalized()), -1, "longe demais para pegar")
	rua.free()


func test_rua_foto_registra_a_pista_enquadrada_e_gasta_filme() -> void:
	var rua := _rua_no_bar()
	var pista: Node3D = rua.pistas[0]
	var olho: Vector3 = pista.position + Vector3(0, 1.5, 3.0)
	var foto: Dictionary = rua.fotografar(olho, (pista.position - olho).normalized(), 45.0)
	assert_has(foto["marcas"], pista.marca, "a pista saiu na foto")
	var vazia: Dictionary = rua.fotografar(olho, Vector3.UP, 45.0)
	assert_eq(vazia["marcas"].size(), 0, "foto do céu não registra nada")
	assert_eq(rua.album.restantes(), int(_cfg["filme"]) - 2, "cada foto gasta filme")
	assert_has(rua.album.marcas_registradas(), pista.marca)
	rua.free()
