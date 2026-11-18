extends "res://tests/framework/test_case.gd"
## Fase 2: caçador em terceira pessoa, câmera por cima do ombro, materiais PS1 e a rua cinza.
## Monta tudo sem abrir janela; as contas de movimento e câmera são conferidas direto.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Cacador := preload("res://presentation/personagem/cacador.gd")
const Rua := preload("res://presentation/greybox/rua.gd")
const Materiais := preload("res://presentation/ps1/materiais.gd")

var _cfg: Dictionary


func before_each() -> void:
	_cfg = Catalogo.carregar_config_personagem()["dados"]


func _todos(no: Node, tipo: String) -> Array:
	var lista: Array = []
	for filho in no.get_children():
		if filho.is_class(tipo):
			lista.append(filho)
		lista.append_array(_todos(filho, tipo))
	return lista


func _perto(a: Vector3, b: Vector3, mensagem: String) -> void:
	assert_true(a.distance_to(b) < 0.0001, "%s: %s, esperado %s" % [mensagem, a, b])


func test_personagem_config_valida_contra_o_esquema() -> void:
	var resultado := Catalogo.carregar_config_personagem()
	assert_eq(resultado["erros"].size(), 0, str(resultado["erros"]))
	assert_true(_cfg["velocidade_correr"] > _cfg["velocidade_andar"], "correr é mais rápido que andar")


func test_cacador_frente_sem_giro_anda_para_menos_z() -> void:
	_perto(Cacador.direcao_no_chao(Vector2(0, 1), 0.0), Vector3(0, 0, -1), "frente")
	_perto(Cacador.direcao_no_chao(Vector2(1, 0), 0.0), Vector3(1, 0, 0), "direita")


func test_cacador_anda_para_onde_a_camera_olha() -> void:
	# Câmera virada 90 graus para a esquerda: "frente" passa a ser -X, "direita" passa a ser -Z.
	_perto(Cacador.direcao_no_chao(Vector2(0, 1), PI / 2.0), Vector3(-1, 0, 0), "frente girada")
	_perto(Cacador.direcao_no_chao(Vector2(1, 0), PI / 2.0), Vector3(0, 0, -1), "direita girada")


func test_cacador_diagonal_nao_e_mais_rapida() -> void:
	assert_almost_eq(Cacador.direcao_no_chao(Vector2(1, 1), 0.3).length(), 1.0, 0.0001)


func test_cacador_correr_usa_a_velocidade_do_config() -> void:
	var andando := Cacador.velocidade_alvo(Vector2(0, 1), 0.0, false, _cfg)
	var correndo := Cacador.velocidade_alvo(Vector2(0, 1), 0.0, true, _cfg)
	assert_almost_eq(andando.length(), _cfg["velocidade_andar"], 0.0001)
	assert_almost_eq(correndo.length(), _cfg["velocidade_correr"], 0.0001)


func test_cacador_acelera_sem_passar_do_alvo_e_mantem_a_queda() -> void:
	var alvo := Vector3(0, 0, -2.6)
	var um_passo := Cacador.acelerar(Vector3(0, -3.0, 0), alvo, 14.0, 0.1)
	assert_almost_eq(um_passo.z, -1.4, 0.0001, "anda aceleracao * delta")
	assert_almost_eq(um_passo.y, -3.0, 0.0001, "a velocidade vertical não muda")
	var muitos := Cacador.acelerar(Vector3.ZERO, alvo, 14.0, 10.0)
	assert_almost_eq(muitos.z, -2.6, 0.0001, "para no alvo")


func test_camera_inclinacao_fica_nos_limites() -> void:
	assert_eq(Cacador.limitar_inclinacao(-200.0, _cfg), _cfg["inclinacao_minima"])
	assert_eq(Cacador.limitar_inclinacao(200.0, _cfg), _cfg["inclinacao_maxima"])
	assert_eq(Cacador.limitar_inclinacao(10.0, _cfg), 10.0)


func test_camera_mouse_gira_e_inclina_sem_girar_o_corpo() -> void:
	var cacador := Cacador.new()
	cacador.montar()
	cacador.olhar(Vector2(100, 0))
	assert_true(cacador.yaw < 0.0, "mouse para a direita gira a câmera para a direita")
	assert_almost_eq(cacador.pivo.rotation.y, cacador.yaw, 0.0001)
	cacador.olhar(Vector2(0, -100000))
	assert_eq(cacador.pitch, _cfg["inclinacao_maxima"], "olhar para cima tem limite")
	assert_almost_eq(cacador.corpo.rotation.y, 0.0, 0.0001, "o corpo não gira com o mouse")
	cacador.free()


func test_cacador_monta_corpo_e_camera_por_cima_do_ombro() -> void:
	var cacador := Cacador.new()
	cacador.montar()
	var formas := _todos(cacador, "CollisionShape3D")
	assert_eq(formas.size(), 1, "uma colisão")
	assert_almost_eq(formas[0].shape.height, _cfg["altura_do_corpo"], 0.0001)
	assert_almost_eq(cacador.braco.spring_length, _cfg["camera_distancia"], 0.0001)
	assert_almost_eq(cacador.braco.position.x, _cfg["camera_ombro"], 0.0001, "câmera deslocada para o ombro")
	assert_true(cacador.camera.get_parent() == cacador.braco, "a câmera fica na ponta do braço")
	for acao in Cacador.ACOES:
		assert_true(InputMap.has_action(acao), "ação %s existe" % acao)
	cacador.free()


func test_materiais_ps1_usam_os_shaders_do_projeto() -> void:
	var objeto := Materiais.objeto(Color.RED, 2.0)
	assert_true(objeto.shader == Materiais.SHADER_OBJETO, "shader de objeto")
	assert_eq(objeto.get_shader_parameter("escala_uv"), 2.0)
	assert_true(Materiais.tela().shader == Materiais.SHADER_TELA, "shader de tela")
	assert_has(Materiais.SHADER_OBJETO.code, "POSITION", "o shader prende os vértices")
	assert_has(Materiais.SHADER_TELA.code, "BAYER", "o filtro de tela pontilha")


func test_visual_config_valida_e_efeito_ps1_desligado_tira_tremor_e_textura_torta() -> void:
	var r := Catalogo.carregar_config_visual()
	assert_eq(r["erros"].size(), 0, str(r["erros"]))
	var material := Materiais.objeto(Color.RED, 1.0, 1.0)
	if Materiais.efeito_ps1():
		assert_eq(material.get_shader_parameter("afim"), 1.0, "ligado: a textura entorta")
	else:
		assert_eq(material.get_shader_parameter("afim"), 0.0, "desligado: a textura não entorta")
		assert_eq(material.get_shader_parameter("grade"), Materiais.GRADE_SEM_TREMOR, "desligado: os vértices não tremem")
		var filtro := Materiais.filtro_de_tela()
		assert_false(filtro.visible, "desligado: sem pontilhado na tela")
		filtro.free()


func test_rua_tem_chao_sob_o_cacador_nevoa_postes_e_filtro() -> void:
	var rua := Rua.new()
	rua.montar()
	assert_true(rua.cacador != null, "o caçador está na rua")
	assert_true(rua.ambiente.environment.fog_enabled, "névoa ligada")
	assert_gte(rua.postes.size(), 3, "postes com luz")
	assert_true(rua.filtro.material.shader == Materiais.SHADER_TELA, "filtro PS1 na tela")
	assert_eq(rua.filtro.visible, Materiais.efeito_ps1(), "o filtro só aparece com o efeito PS1 ligado")
	var pe := rua.cacador.position
	var tem_chao := false
	for corpo in _todos(rua, "StaticBody3D"):
		var caixa: BoxShape3D = corpo.get_child(0).shape
		var meio: Vector3 = caixa.size / 2.0
		var dentro: bool = absf(pe.x - corpo.position.x) <= meio.x and absf(pe.z - corpo.position.z) <= meio.z
		if dentro and corpo.position.y + meio.y <= pe.y:
			tem_chao = true
	assert_true(tem_chao, "há chão com colisão debaixo do caçador")
	for malha in _todos(rua, "MeshInstance3D"):
		var material: ShaderMaterial = malha.material_override
		assert_true(material != null and material.shader == Materiais.SHADER_OBJETO, "%s usa o material PS1" % malha.name)
	rua.free()
