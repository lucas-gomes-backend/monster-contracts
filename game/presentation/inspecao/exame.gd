extends CanvasLayer
## Tela de exame (docs/09, "Inspeção de pistas"): a pista aparece em close, num mundo 3D
## só dela, e gira com o mouse arrastado, como em survival horror clássico.
## Pistas que não dá para pegar (pegadas, sangue) mostram só a descrição.

const Mira := preload("res://presentation/inspecao/mira.gd")
const Materiais := preload("res://presentation/ps1/materiais.gd")

const TAMANHO_NA_TELA := 0.55

var sensibilidade: float = 0.5
var pista: Node3D
var rotacao := Vector2.ZERO
var objeto: MeshInstance3D
var visor: SubViewportContainer
var descricao: Label
var aberto: bool = false


func montar(sensibilidade_girar: float) -> void:
	sensibilidade = sensibilidade_girar
	layer = 5
	visible = false
	var fundo := ColorRect.new()
	fundo.color = Color(0.02, 0.02, 0.03, 0.85)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	visor = SubViewportContainer.new()
	visor.stretch = true
	visor.size = Vector2(320, 240)
	visor.position = Vector2(160, 70)
	add_child(visor)
	var mundo := SubViewport.new()
	mundo.own_world_3d = true
	mundo.transparent_bg = true
	visor.add_child(mundo)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0, 1.2)
	camera.fov = 40.0
	mundo.add_child(camera)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-35, 25, 0)
	luz.light_energy = 1.6
	mundo.add_child(luz)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.75, 0.8)
	var ambiente := WorldEnvironment.new()
	ambiente.environment = env
	mundo.add_child(ambiente)
	objeto = MeshInstance3D.new()
	objeto.material_override = Materiais.objeto(Color.WHITE)
	mundo.add_child(objeto)

	descricao = Label.new()
	descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descricao.position = Vector2(80, 330)
	descricao.size = Vector2(480, 80)
	descricao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	descricao.add_theme_font_size_override("font_size", 14)
	add_child(descricao)
	var ajuda := Label.new()
	ajuda.text = "arraste com o botão esquerdo para girar · E ou Esc para soltar"
	ajuda.position = Vector2(0, 440)
	ajuda.size = Vector2(640, 20)
	ajuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ajuda.add_theme_font_size_override("font_size", 11)
	ajuda.modulate = Color(0.8, 0.75, 0.6)
	add_child(ajuda)


## Abre o exame de uma pista (pista_3d.gd).
func abrir(alvo: Node3D) -> void:
	pista = alvo
	aberto = true
	visible = true
	rotacao = Vector2(25.0, 30.0)
	descricao.text = alvo.texto
	visor.visible = alvo.pegavel
	if alvo.pegavel:
		objeto.mesh = alvo.malha
		var cor: Variant = alvo.get_child(0).material_override.get_shader_parameter("cor")
		objeto.material_override.set_shader_parameter("cor", cor)
		var maior: float = alvo.malha.get_aabb().get_longest_axis_size()
		objeto.scale = Vector3.ONE * (TAMANHO_NA_TELA / maxf(maior, 0.01))
		alvo.na_mao(true)
	_aplicar_rotacao()


func fechar() -> void:
	if pista != null and pista.pegavel:
		pista.na_mao(false)
	pista = null
	aberto = false
	visible = false


## Gira a pista pelo arraste do mouse (pixels).
func girar_por(arraste: Vector2) -> void:
	rotacao = Mira.girar(rotacao, arraste, sensibilidade)
	_aplicar_rotacao()


func _aplicar_rotacao() -> void:
	objeto.rotation_degrees = Vector3(rotacao.x, rotacao.y, 0.0)


func _input(evento: InputEvent) -> void:
	if not aberto:
		return
	if evento is InputEventMouseMotion and (evento.button_mask & MOUSE_BUTTON_MASK_LEFT):
		girar_por(evento.relative)
		get_viewport().set_input_as_handled()
