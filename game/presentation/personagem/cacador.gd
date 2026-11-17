extends CharacterBody3D
## Caçador em terceira pessoa com câmera por cima do ombro (docs/09, "Câmera e controles").
## Os números vêm de game/data/config/personagem.json. As contas ficam em funções estáticas
## puras, para os testes conferirem sem precisar de física rodando.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Materiais := preload("res://presentation/ps1/materiais.gd")

const ACOES := {
	"mover_frente": [KEY_W, KEY_UP],
	"mover_tras": [KEY_S, KEY_DOWN],
	"mover_esquerda": [KEY_A, KEY_LEFT],
	"mover_direita": [KEY_D, KEY_RIGHT],
	"correr": [KEY_SHIFT],
	"soltar_mouse": [KEY_ESCAPE],
}

var config: Dictionary = {}
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
func montar(cfg: Dictionary = {}) -> void:
	config = cfg if not cfg.is_empty() else Catalogo.carregar_config_personagem()["dados"]
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
	inclinacao.add_child(braco)
	camera = Camera3D.new()
	camera.fov = 65.0
	camera.current = true
	braco.add_child(camera)


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


## Gira a câmera pelo movimento do mouse (em pixels).
func olhar(movimento: Vector2) -> void:
	var sensibilidade: float = config["sensibilidade_mouse"]
	yaw = wrapf(yaw - deg_to_rad(movimento.x * sensibilidade), -PI, PI)
	pitch = limitar_inclinacao(pitch - movimento.y * sensibilidade, config)
	pivo.rotation.y = yaw
	inclinacao.rotation.x = deg_to_rad(pitch)


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		olhar(evento.relative)
	elif evento is InputEventMouseButton and evento.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif evento.is_action_pressed("soltar_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	var entrada := Input.get_vector("mover_esquerda", "mover_direita", "mover_tras", "mover_frente")
	var alvo := velocidade_alvo(entrada, yaw, Input.is_action_pressed("correr"), config)
	velocity = acelerar(velocity, alvo, config["aceleracao"], delta)
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= float(config["gravidade"]) * delta
	move_and_slide()
	# O corpo vira, suave, para onde está andando; a câmera não gira junto.
	var plano := Vector2(velocity.x, velocity.z)
	if plano.length() > 0.2:
		var destino := atan2(-velocity.x, -velocity.z)
		corpo.rotation.y = lerp_angle(corpo.rotation.y, destino, minf(1.0, float(config["giro_do_corpo"]) * delta))
