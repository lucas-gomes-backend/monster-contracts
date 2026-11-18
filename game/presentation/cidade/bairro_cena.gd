extends Node3D
## Cena para andar num bairro do mapa real (Fase 3): cidade plana, noite, névoa densa, filtro PS1 e o caçador.
## Argumentos: --bairro=<id> (padrão valongo), --semente=N (padrão 1),
## --captura=caminho.png, --lanterna, --inclinar=G, --virar=G, --vista=cima (para conferir o visual).

const Bairro3D := preload("res://presentation/cidade/bairro_3d.gd")
const Cacador := preload("res://presentation/personagem/cacador.gd")
const Materiais := preload("res://presentation/ps1/materiais.gd")

const QUADROS_ANTES_DA_CAPTURA := 40

var bairro: Node3D
var cacador: CharacterBody3D
var ambiente: WorldEnvironment
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
		elif argumento.begins_with("--virar="):
			cacador.virar_para(deg_to_rad(float(argumento.trim_prefix("--virar="))))


## Monta tudo. Pode ser chamado sem estar na árvore (testes).
func montar(id_bairro: String, semente: int) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.34, 0.45)
	env.ambient_light_energy = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.07, 0.08, 0.11)
	env.fog_density = 0.045
	ambiente = WorldEnvironment.new()
	ambiente.environment = env
	add_child(ambiente)
	var lua := DirectionalLight3D.new()
	lua.light_color = Color(0.55, 0.6, 0.85)
	lua.light_energy = 0.45
	lua.rotation_degrees = Vector3(-50, 30, 0)
	add_child(lua)

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
	var filtro := ColorRect.new()
	filtro.set_anchors_preset(Control.PRESET_FULL_RECT)
	filtro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filtro.material = Materiais.tela()
	camada_filtro.add_child(filtro)
	var camada := CanvasLayer.new()
	camada.layer = 11
	add_child(camada)
	var titulo := Label.new()
	titulo.text = "%s · mapa real 1:3 · WASD andar · Shift correr · F lanterna" % bairro.dados["nome"]
	titulo.position = Vector2(8, 6)
	titulo.add_theme_font_size_override("font_size", 11)
	titulo.modulate = Color(0.85, 0.8, 0.6, 0.85)
	camada.add_child(titulo)
	var credito := Label.new()
	credito.text = "© colaboradores do OpenStreetMap"
	credito.position = Vector2(8, 460)
	credito.add_theme_font_size_override("font_size", 9)
	credito.modulate = Color(0.7, 0.7, 0.7, 0.7)
	camada.add_child(credito)


func _process(_delta: float) -> void:
	if _captura.is_empty():
		return
	_quadros += 1
	if _quadros == QUADROS_ANTES_DA_CAPTURA:
		get_viewport().get_texture().get_image().save_png(_captura)
		get_tree().quit()
