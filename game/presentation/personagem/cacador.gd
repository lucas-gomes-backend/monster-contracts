extends CharacterBody3D
## Caçador em terceira pessoa com câmera por cima do ombro (docs/09, "Câmera e controles").
## Os números vêm de game/data/config/personagem.json. As contas ficam em funções estáticas
## puras, para os testes conferirem sem precisar de física rodando.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Materiais := preload("res://presentation/ps1/materiais.gd")
const Mira := preload("res://presentation/inspecao/mira.gd")

const FOV_NORMAL := 65.0
const ALCANCE_DA_CAMERA := 400.0

const ACOES := {
	"mover_frente": [KEY_W, KEY_UP],
	"mover_tras": [KEY_S, KEY_DOWN],
	"mover_esquerda": [KEY_A, KEY_LEFT],
	"mover_direita": [KEY_D, KEY_RIGHT],
	"correr": [KEY_SHIFT],
	"soltar_mouse": [KEY_ESCAPE],
	"lanterna": [KEY_F],
	"examinar": [KEY_E],
	"caderno": [KEY_TAB],
	"mapa": [KEY_M],
	"recarregar": [KEY_R],
	"menu_radial": [KEY_Q],
	"arma_1": [KEY_1],
	"arma_2": [KEY_2],
	"arma_3": [KEY_3],
	"ritual": [KEY_T],
	"conversar": [KEY_N],
	"mochila": [KEY_I],
	"habilidades": [KEY_H],
	"acao_do_ritual": [KEY_SPACE],
}
const ACOES_MOUSE := {
	"mirar": MOUSE_BUTTON_RIGHT,
	"fotografar": MOUSE_BUTTON_LEFT,
	"atirar": MOUSE_BUTTON_LEFT,
}

var config: Dictionary = {}
var config_inspecao: Dictionary = {}
var lanterna: SpotLight3D
## Mira: botão direito segurado. A câmera aproxima e fecha o campo de visão.
var mirando: bool = false
## Bloqueado enquanto examina uma pista: não anda nem gira a câmera.
var bloqueado: bool = false
## Ferimentos mexem no corpo (core/confronto/ferimentos.gd): perna ferida anda mais devagar,
## tronco ferido corre menos.
var modificadores: Dictionary = {"velocidade": 1.0, "folego": 1.0}
var corpo: Node3D
var pivo: Node3D
var inclinacao: Node3D
var braco: SpringArm3D
var camera: Camera3D
var yaw: float = 0.0
var pitch: float = 0.0


func _ready() -> void:
	if config.is_empty():
		montar()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Monta o corpo, a colisão e a câmera. Pode ser chamado sem estar na árvore (testes).
func montar(cfg: Dictionary = {}, cfg_inspecao: Dictionary = {}) -> void:
	config = cfg if not cfg.is_empty() else Catalogo.carregar_config_personagem()["dados"]
	config_inspecao = cfg_inspecao if not cfg_inspecao.is_empty() else Catalogo.carregar_config_inspecao()["dados"]
	garantir_acoes()
	var altura: float = config["altura_do_corpo"]
	var raio: float = config["raio_do_corpo"]

	var forma := CapsuleShape3D.new()
	forma.height = altura
	forma.radius = raio
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	colisao.position.y = altura / 2.0
	add_child(colisao)

	corpo = Node3D.new()
	corpo.name = "Corpo"
	add_child(corpo)
	var malha := CapsuleMesh.new()
	malha.height = altura
	malha.radius = raio
	malha.radial_segments = 8
	malha.rings = 2
	_peca(malha, Vector3(0, altura / 2.0, 0), Color(0.36, 0.30, 0.24))
	# Um "nariz" para ver para onde o corpo está virado.
	var nariz := BoxMesh.new()
	nariz.size = Vector3(0.12, 0.08, 0.2)
	_peca(nariz, Vector3(0, altura * 0.88, -raio), Color(0.7, 0.55, 0.45))

	pivo = Node3D.new()
	pivo.name = "Pivo"
	pivo.position.y = config["camera_altura"]
	add_child(pivo)
	inclinacao = Node3D.new()
	pivo.add_child(inclinacao)
	braco = SpringArm3D.new()
	braco.spring_length = config["camera_distancia"]
	braco.position.x = config["camera_ombro"]
	braco.margin = 0.1
	braco.add_excluded_object(get_rid())
	floor_snap_length = float(config["altura_degrau"]) + 0.05
	inclinacao.add_child(braco)
	camera = Camera3D.new()
	camera.fov = FOV_NORMAL
	# Alcance curto: mais precisão de profundidade (chão sem piscar). A névoa cobre o fundo.
	camera.near = 0.1
	camera.far = ALCANCE_DA_CAMERA
	camera.current = true
	braco.add_child(camera)
	# A lanterna sai do ombro, na frente do corpo, e aponta para onde a câmera olha
	# (gira junto com a inclinação). Começa desligada.
	lanterna = SpotLight3D.new()
	lanterna.name = "Lanterna"
	lanterna.spot_range = config_inspecao["lanterna_alcance"]
	lanterna.spot_angle = config_inspecao["lanterna_angulo"]
	lanterna.light_energy = config_inspecao["lanterna_energia"]
	lanterna.light_color = Color(1.0, 0.95, 0.82)
	lanterna.visible = false
	lanterna.position = Vector3(config["camera_ombro"] * 0.5, 0.0, -config["raio_do_corpo"] - 0.2)
	lanterna.rotation_degrees.x = config_inspecao["lanterna_inclinacao"]
	inclinacao.add_child(lanterna)


func _peca(malha: Mesh, posicao: Vector3, cor: Color) -> void:
	var instancia := MeshInstance3D.new()
	instancia.mesh = malha
	instancia.position = posicao
	instancia.material_override = Materiais.objeto(cor)
	corpo.add_child(instancia)


## Cria as ações de teclado se o projeto ainda não as tiver.
static func garantir_acoes() -> void:
	for acao in ACOES:
		if InputMap.has_action(acao):
			continue
		InputMap.add_action(acao)
		for tecla in ACOES[acao]:
			var evento := InputEventKey.new()
			evento.physical_keycode = tecla
			InputMap.action_add_event(acao, evento)
	for acao in ACOES_MOUSE:
		if InputMap.has_action(acao):
			continue
		InputMap.add_action(acao)
		var clique := InputEventMouseButton.new()
		clique.button_index = ACOES_MOUSE[acao]
		InputMap.action_add_event(acao, clique)


## Direção no chão para uma entrada (x = direita, y = frente) com a câmera virada em yaw.
static func direcao_no_chao(entrada: Vector2, yaw_rad: float) -> Vector3:
	if entrada.length() > 1.0:
		entrada = entrada.normalized()
	var frente := Vector3(-sin(yaw_rad), 0.0, -cos(yaw_rad))
	var direita := Vector3(cos(yaw_rad), 0.0, -sin(yaw_rad))
	return direita * entrada.x + frente * entrada.y


## Velocidade no chão que o caçador quer ter (andando ou correndo).
static func velocidade_alvo(entrada: Vector2, yaw_rad: float, correndo: bool, cfg: Dictionary) -> Vector3:
	var rapidez: float = cfg["velocidade_correr"] if correndo else cfg["velocidade_andar"]
	return direcao_no_chao(entrada, yaw_rad) * rapidez


## Aproxima a velocidade no chão do alvo, sem passar dele, e mantém a vertical.
static func acelerar(atual: Vector3, alvo: Vector3, aceleracao: float, delta: float) -> Vector3:
	var plano := Vector3(atual.x, 0.0, atual.z).move_toward(alvo, aceleracao * delta)
	return Vector3(plano.x, atual.y, plano.z)


## Inclinação da câmera (graus) presa entre os limites do config.
static func limitar_inclinacao(graus: float, cfg: Dictionary) -> float:
	return clampf(graus, cfg["inclinacao_minima"], cfg["inclinacao_maxima"])


## Distância e campo de visão que a câmera procura ter: (distância, fov).
static func camera_alvo(mira: bool, cfg: Dictionary, cfg_inspecao: Dictionary) -> Vector2:
	if mira:
		return Vector2(cfg_inspecao["mira_distancia"], cfg_inspecao["mira_fov"])
	return Vector2(cfg["camera_distancia"], FOV_NORMAL)


func alternar_lanterna() -> void:
	lanterna.visible = not lanterna.visible


## Vira a câmera (e o corpo) para um giro absoluto, em radianos. Usado ao passar por portas e bueiros.
func virar_para(giro: float) -> void:
	yaw = wrapf(giro, -PI, PI)
	pivo.rotation.y = yaw
	corpo.rotation.y = yaw


## Gira a câmera pelo movimento do mouse (em pixels).
func olhar(movimento: Vector2) -> void:
	var sensibilidade: float = config["sensibilidade_mouse"]
	yaw = wrapf(yaw - deg_to_rad(movimento.x * sensibilidade), -PI, PI)
	pitch = limitar_inclinacao(pitch - movimento.y * sensibilidade, config)
	pivo.rotation.y = yaw
	inclinacao.rotation.x = deg_to_rad(pitch)


func _unhandled_input(evento: InputEvent) -> void:
	if bloqueado:
		return
	if evento.is_action_pressed("lanterna"):
		alternar_lanterna()
	elif evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		olhar(evento.relative)
	elif evento is InputEventMouseButton and evento.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif evento.is_action_pressed("soltar_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Um passo de física: acelera, cai, sobe degrau baixo (meio-fio) e anda.
## Separado do _physics_process para os testes andarem o caçador sem teclado.
func passo(entrada: Vector2, correndo: bool, delta: float) -> void:
	var alvo := velocidade_alvo(entrada, yaw, correndo, config)
	alvo *= float(modificadores.get("velocidade", 1.0)) * (float(modificadores.get("folego", 1.0)) if correndo else 1.0)
	velocity = acelerar(velocity, alvo, config["aceleracao"], delta)
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= float(config["gravidade"]) * delta
	_subir_degrau(delta)
	move_and_slide()


## O corpo de física trata um degrau como parede. Se o caminho à frente está bloqueado,
## mas logo acima (até altura_degrau) está livre, o caçador sobe; o encaixe no chão
## (floor_snap_length) assenta ele no degrau.
func _subir_degrau(delta: float) -> void:
	var avanco := Vector3(velocity.x, 0.0, velocity.z) * delta
	if avanco.length() < 0.0001 or not is_on_floor():
		return
	if not test_move(global_transform, avanco):
		return
	var subida := Vector3(0.0, float(config["altura_degrau"]), 0.0)
	if test_move(global_transform, subida):
		return
	if test_move(global_transform.translated(subida), avanco):
		return
	global_position += subida


func _physics_process(delta: float) -> void:
	var entrada := Vector2.ZERO
	if not bloqueado:
		entrada = Input.get_vector("mover_esquerda", "mover_direita", "mover_tras", "mover_frente")
	mirando = not bloqueado and Input.is_action_pressed("mirar")
	var correndo := Input.is_action_pressed("correr") and not mirando
	passo(entrada, correndo, delta)
	# O corpo vira, suave, para onde está andando (ou para onde mira); a câmera não gira junto.
	var plano := Vector2(velocity.x, velocity.z)
	var giro := minf(1.0, float(config["giro_do_corpo"]) * delta)
	if mirando:
		corpo.rotation.y = lerp_angle(corpo.rotation.y, yaw, giro)
	elif plano.length() > 0.2:
		corpo.rotation.y = lerp_angle(corpo.rotation.y, atan2(-velocity.x, -velocity.z), giro)
	var desejo := camera_alvo(mirando, config, config_inspecao)
	var rapidez: float = config_inspecao["mira_velocidade"]
	braco.spring_length = Mira.suavizar(braco.spring_length, desejo.x, rapidez, delta)
	camera.fov = Mira.suavizar(camera.fov, desejo.y, rapidez, delta)
