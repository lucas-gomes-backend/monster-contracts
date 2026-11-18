extends Node3D
## Cena para andar num bairro do mapa real (Fase 3): cidade plana, de dia, com névoa
## esbranquiçada (como Silent Hill), e o caçador. E desce pelo bueiro para as galerias
## (escuras: só a lanterna) e sobe de volta pela escada.
## Argumentos: --bairro=<id> (padrão valongo), --semente=N (padrão 1),
## --captura=caminho.png, --lanterna, --inclinar=G, --virar=G, --vista=cima (para conferir o visual).

const Bairro3D := preload("res://presentation/cidade/bairro_3d.gd")
const Cacador := preload("res://presentation/personagem/cacador.gd")
const Materiais := preload("res://presentation/ps1/materiais.gd")
const Mira := preload("res://presentation/inspecao/mira.gd")

const ALCANCE_DO_BUEIRO := 2.5
const ANGULO_DO_BUEIRO := 35.0

const QUADROS_ANTES_DA_CAPTURA := 40
const COR_DA_NEVOA := Color(0.72, 0.73, 0.74)

var bairro: Node3D
var cacador: CharacterBody3D
var ambiente: WorldEnvironment
var sol: DirectionalLight3D
## "rua" ou "esgoto".
var zona: String = "rua"
var aviso: Label
var _alvo := -1
var _captura := ""
var _quadros := 0


func _ready() -> void:
	var id := "valongo"
	var semente := 1
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--bairro="):
			id = argumento.trim_prefix("--bairro=")
		elif argumento.begins_with("--semente="):
			semente = int(argumento.trim_prefix("--semente="))
	if bairro == null:
		montar(id, semente)
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--captura="):
			_captura = argumento.trim_prefix("--captura=")
		elif argumento == "--lanterna":
			cacador.alternar_lanterna()
		elif argumento.begins_with("--inclinar="):
			cacador.olhar(Vector2(0.0, -float(argumento.trim_prefix("--inclinar=")) / float(cacador.config["sensibilidade_mouse"])))
		elif argumento == "--vista=cima":
			# Câmera alta olhando para baixo: o bairro inteiro numa imagem.
			var caixa: Array = bairro.dados["caixa"]
			var vista := Camera3D.new()
			vista.projection = Camera3D.PROJECTION_ORTHOGONAL
			vista.size = maxf(float(caixa[2]) - float(caixa[0]), float(caixa[3]) - float(caixa[1])) * 1.1
			vista.far = 2000.0
			add_child(vista)
			vista.global_position = Vector3((float(caixa[0]) + float(caixa[2])) / 2.0, 400.0, (float(caixa[1]) + float(caixa[3])) / 2.0)
			vista.rotation_degrees = Vector3(-90, 0, 0)
			vista.current = true
			ambiente.environment.fog_enabled = false
		elif argumento == "--esgoto" and not bairro.bueiros.is_empty():
			usar_bueiro(0)
		elif argumento.begins_with("--virar="):
			cacador.virar_para(deg_to_rad(float(argumento.trim_prefix("--virar="))))


## Monta tudo. Pode ser chamado sem estar na árvore (testes).
func montar(id_bairro: String, semente: int) -> void:
	# Dia nublado: céu e névoa da mesma cor clara, o fundo some na névoa.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = COR_DA_NEVOA
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.86, 0.88)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = COR_DA_NEVOA
	env.fog_density = 0.035
	ambiente = WorldEnvironment.new()
	ambiente.environment = env
	add_child(ambiente)
	sol = DirectionalLight3D.new()
	sol.name = "Sol"
	sol.light_color = Color(1.0, 0.97, 0.9)
	sol.light_energy = 0.9
	sol.rotation_degrees = Vector3(-55, 35, 0)
	add_child(sol)

	bairro = Bairro3D.new()
	bairro.montar(id_bairro, semente)
	add_child(bairro)

	cacador = Cacador.new()
	cacador.name = "Cacador"
	cacador.montar()
	cacador.position = bairro.chegada()
	cacador.virar_para(bairro.giro_chegada)
	add_child(cacador)

	var camada_filtro := CanvasLayer.new()
	camada_filtro.layer = 10
	add_child(camada_filtro)
	camada_filtro.add_child(Materiais.filtro_de_tela())
	var camada := CanvasLayer.new()
	camada.layer = 11
	add_child(camada)
	var titulo := Label.new()
	titulo.text = "%s · mapa real 1:3 · WASD andar · Shift correr · F lanterna" % bairro.dados["nome"]
	titulo.position = Vector2(8, 6)
	titulo.add_theme_font_size_override("font_size", 11)
	titulo.modulate = Color(0.15, 0.13, 0.1, 0.9)
	camada.add_child(titulo)
	var credito := Label.new()
	credito.text = "© colaboradores do OpenStreetMap"
	credito.position = Vector2(8, 460)
	credito.add_theme_font_size_override("font_size", 9)
	credito.modulate = Color(0.2, 0.2, 0.2, 0.8)
	camada.add_child(credito)
	aviso = Label.new()
	aviso.position = Vector2(0, 300)
	aviso.size = Vector2(640, 20)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.add_theme_font_size_override("font_size", 13)
	camada.add_child(aviso)


## Desce pelo bueiro i (ou sobe, se já estiver lá embaixo). Muda a luz da zona.
func usar_bueiro(i: int) -> void:
	var p: Vector3 = bairro.bueiros[i]
	var env: Environment = ambiente.environment
	if zona == "rua":
		zona = "esgoto"
		cacador.position = p + Vector3(0.8, -bairro.profundidade + 0.1, 0)
		sol.visible = false
		env.background_color = Color.BLACK
		env.ambient_light_energy = 0.1
		env.fog_light_color = Color(0.01, 0.01, 0.01)
		env.fog_density = 0.1
	else:
		zona = "rua"
		cacador.position = p + Vector3(1.2, 0.3, 0)
		sol.visible = true
		env.background_color = COR_DA_NEVOA
		env.ambient_light_energy = 0.55
		env.fog_light_color = COR_DA_NEVOA
		env.fog_density = 0.035
	cacador.velocity = Vector3.ZERO


## Bueiro na mira, ou -1. Na rua, o bueiro no chão; embaixo, a escada logo abaixo dele.
func bueiro_na_mira(olho: Vector3, frente: Vector3) -> int:
	var pontos: Array = []
	for p in bairro.bueiros:
		pontos.append(p if zona == "rua" else p + Vector3(0, -bairro.profundidade + 1.2, 0))
	return Mira.escolher_alvo(olho, frente, cacador.position + Vector3(0, 0.9, 0), pontos, ALCANCE_DO_BUEIRO, ANGULO_DO_BUEIRO)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("examinar") and _alvo >= 0:
		usar_bueiro(_alvo)
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	var camera: Camera3D = cacador.camera
	_alvo = bueiro_na_mira(camera.global_position, -camera.global_basis.z)
	if _alvo < 0:
		aviso.text = ""
	else:
		aviso.text = "[E] descer pelo bueiro" if zona == "rua" else "[E] subir para a rua"
	aviso.modulate = Color(0.1, 0.1, 0.1) if zona == "rua" else Color(0.9, 0.85, 0.7)
	if _captura.is_empty():
		return
	_quadros += 1
	if _quadros == QUADROS_ANTES_DA_CAPTURA:
		get_viewport().get_texture().get_image().save_png(_captura)
		get_tree().quit()
