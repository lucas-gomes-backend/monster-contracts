extends CharacterBody3D
## O carro fixo do caçador (docs/08, "Veículo"): um sedã velho. E perto da porta entra e sai;
## W/S acelera e freia (e dá ré), A/D vira. Gasta gasolina pela distância; sem gasolina, não
## anda. O porta-malas abre perto dele (bairro_cena.gd). Números em config/progressao.json.

const Blocos := preload("res://presentation/greybox/blocos.gd")

var velocidade: float = 0.0  # m/s, positivo para a frente
var litros: float = 0.0
var camera: Camera3D
var _cfg: Dictionary


func montar(cfg_carro: Dictionary) -> void:
	name = "Carro"
	_cfg = cfg_carro
	litros = float(_cfg["litros_iniciais"])
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.8, 1.2, 4.2)
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	colisao.position = Vector3(0, 0.7, 0)
	add_child(colisao)
	Blocos.bloco(self, Vector3(1.8, 1.0, 4.2), Vector3(0, 0.6, 0), Color(0.42, 0.12, 0.1), 1.0, false)
	Blocos.bloco(self, Vector3(1.6, 0.6, 2.0), Vector3(0, 1.4, 0.2), Color(0.3, 0.32, 0.35), 1.0, false)
	floor_snap_length = 0.4
	var braco := SpringArm3D.new()
	braco.spring_length = 7.5
	braco.position = Vector3(0, 2.2, 0)
	braco.rotation_degrees = Vector3(-14, 0, 0)
	add_child(braco)
	camera = Camera3D.new()
	camera.near = 0.1
	camera.far = 400.0
	braco.add_child(camera)


## Um passo dirigindo: entrada.y acelera (+) ou freia/ré (-), entrada.x vira.
## Devolve os metros andados.
func dirigir(entrada: Vector2, delta: float) -> float:
	if litros <= 0.0:
		entrada.y = minf(entrada.y, 0.0) if velocidade > 0.0 else 0.0
	var alvo := 0.0
	if entrada.y > 0.0:
		alvo = float(_cfg["velocidade_maxima"]) * entrada.y
	elif entrada.y < 0.0:
		alvo = -float(_cfg["re_maxima"]) * -entrada.y if velocidade <= 0.5 else 0.0
	var taxa: float = float(_cfg["freio"]) if (entrada.y < 0.0 and velocidade > 0.0) or entrada.y == 0.0 else float(_cfg["aceleracao"])
	velocidade = move_toward(velocidade, alvo, taxa * delta)
	# Só vira andando, e vira menos parado.
	var giro: float = float(_cfg["giro"]) * -entrada.x * clampf(absf(velocidade) / 4.0, 0.0, 1.0) * signf(velocidade if velocidade != 0.0 else 1.0)
	rotation.y = wrapf(rotation.y + giro * delta, -PI, PI)
	var frente := Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))
	velocity = frente * velocidade + Vector3(0, velocity.y - 9.8 * delta if not is_on_floor() else 0.0, 0)
	var antes := position
	move_and_slide()
	var andou := Vector2(position.x - antes.x, position.z - antes.z).length()
	litros = maxf(0.0, litros - andou / (float(_cfg["km_por_litro"]) * 1000.0))
	if is_on_wall():
		velocidade *= 0.3
	return andou


## Litros que faltam para encher o tanque.
func faltam_litros() -> float:
	return maxf(0.0, float(_cfg["tanque_litros"]) - litros)


## Onde o caçador fica ao sair: do lado do motorista.
func lado_da_porta() -> Vector3:
	return position + Vector3(cos(rotation.y), 0.0, -sin(rotation.y)) * 1.6 + Vector3(0, 0.3, 0)
