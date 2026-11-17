extends Node3D
## Greybox da Fase 2: uma rua noturna de Santos em blocos cinza, para andar com o caçador.
## Rua, calçadas, casas baixas dos dois lados, um canal no fim, postes com luz e névoa.
## Tudo é montado em código (sem sorteio): o mesmo resultado toda vez.
## Argumento opcional: --captura=caminho.png salva uma imagem depois de alguns quadros e fecha.

const Cacador := preload("res://presentation/personagem/cacador.gd")
const Materiais := preload("res://presentation/ps1/materiais.gd")

const COMPRIMENTO := 60.0
const LARGURA_RUA := 7.0
const LARGURA_CALCADA := 2.5
const ALTURA_CALCADA := 0.15
const DISTANCIA_POSTES := 12.0
const QUADROS_ANTES_DA_CAPTURA := 30

## Casas de um lado da rua: [largura, altura, fundo, cor]. Sem sorteio: sempre igual.
const CASAS := [
	[6.0, 3.2, 8.0, Color(0.62, 0.58, 0.50)],
	[5.0, 6.0, 9.0, Color(0.50, 0.55, 0.58)],
	[7.0, 3.0, 8.0, Color(0.66, 0.52, 0.45)],
	[4.5, 3.6, 7.0, Color(0.55, 0.60, 0.50)],
	[8.0, 7.5, 10.0, Color(0.48, 0.48, 0.52)],
	[5.5, 3.2, 8.0, Color(0.64, 0.60, 0.42)],
	[6.0, 4.0, 8.0, Color(0.52, 0.50, 0.56)],
]

var cacador: CharacterBody3D
var ambiente: WorldEnvironment
var filtro: ColorRect
var postes: Array[OmniLight3D] = []
var _captura := ""
var _quadros := 0


func _ready() -> void:
	if cacador == null:
		montar()
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--captura="):
			_captura = argumento.trim_prefix("--captura=")


## Monta a cena inteira. Pode ser chamado sem estar na árvore (testes).
func montar() -> void:
	_montar_ambiente()
	var meia_rua := LARGURA_RUA / 2.0
	var meia_total := meia_rua + LARGURA_CALCADA
	# Asfalto.
	_bloco(Vector3(LARGURA_RUA, 0.2, COMPRIMENTO), Vector3(0, -0.1, 0), Color(0.22, 0.22, 0.24), 8.0)
	# Calçadas, levemente mais altas.
	for lado in [-1.0, 1.0]:
		var x: float = lado * (meia_rua + LARGURA_CALCADA / 2.0)
		_bloco(Vector3(LARGURA_CALCADA, 0.2 + ALTURA_CALCADA, COMPRIMENTO),
			Vector3(x, -0.1 + ALTURA_CALCADA / 2.0, 0), Color(0.5, 0.49, 0.46), 6.0)
		_fileira_de_casas(lado, meia_total)
	_canal(meia_total)
	# Muros nas pontas, para não cair do mundo.
	_bloco(Vector3(meia_total * 2.0, 3.0, 0.4), Vector3(0, 1.5, COMPRIMENTO / 2.0), Color(0.4, 0.4, 0.42), 4.0)
	_postes(meia_rua)

	cacador = Cacador.new()
	cacador.name = "Cacador"
	cacador.montar()
	cacador.position = Vector3(1.0, 0.1, COMPRIMENTO / 2.0 - 4.0)
	add_child(cacador)

	var camada := CanvasLayer.new()
	add_child(camada)
	filtro = ColorRect.new()
	filtro.set_anchors_preset(Control.PRESET_FULL_RECT)
	filtro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filtro.material = Materiais.tela()
	camada.add_child(filtro)
	var ajuda := Label.new()
	ajuda.text = "WASD andar · Shift correr · mouse olhar · Esc solta o mouse"
	ajuda.position = Vector2(8, 6)
	ajuda.add_theme_font_size_override("font_size", 12)
	ajuda.modulate = Color(0.85, 0.8, 0.6, 0.8)
	camada.add_child(ajuda)


func _montar_ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.34, 0.45)
	env.ambient_light_energy = 0.8
	env.fog_enabled = true
	env.fog_light_color = Color(0.07, 0.08, 0.11)
	env.fog_density = 0.06
	ambiente = WorldEnvironment.new()
	ambiente.environment = env
	add_child(ambiente)
	# Lua fraca, azulada.
	var lua := DirectionalLight3D.new()
	lua.light_color = Color(0.55, 0.6, 0.85)
	lua.light_energy = 0.25
	lua.rotation_degrees = Vector3(-50, 30, 0)
	add_child(lua)


func _fileira_de_casas(lado: float, inicio_x: float) -> void:
	var z := -COMPRIMENTO / 2.0 + 1.0
	var i := 0
	# Um lado começa a lista pelo meio, para as duas fileiras não ficarem iguais.
	if lado > 0.0:
		i = 3
	while true:
		var casa: Array = CASAS[i % CASAS.size()]
		var largura: float = casa[0]
		if z + largura > COMPRIMENTO / 2.0 - 0.5:
			break
		var altura: float = casa[1]
		var fundo: float = casa[2]
		var x: float = lado * (inicio_x + fundo / 2.0)
		_bloco(Vector3(fundo, altura, largura), Vector3(x, altura / 2.0, z + largura / 2.0), casa[3], 2.0)
		# Porta: um bloco escuro saliente na fachada.
		var porta_x: float = lado * (inicio_x - 0.03)
		_bloco(Vector3(0.12, 2.1, 1.0), Vector3(porta_x, 1.05 + ALTURA_CALCADA, z + largura / 2.0),
			Color(0.18, 0.13, 0.1), 1.0, false)
		z += largura + 0.4
		i += 1


## Um canal de Santos atravessando o fim da rua, com uma ponte baixa.
func _canal(meia_total: float) -> void:
	var z := -COMPRIMENTO / 2.0 - 2.5
	var largura_total := meia_total * 2.0 + 30.0
	_bloco(Vector3(largura_total, 0.2, 4.0), Vector3(0, -1.6, z), Color(0.08, 0.12, 0.12), 6.0)
	for lado in [-1.0, 1.0]:
		_bloco(Vector3(largura_total, 1.6, 0.5), Vector3(0, -0.8, z + lado * 2.25), Color(0.45, 0.45, 0.43), 6.0)
	_bloco(Vector3(LARGURA_RUA, 0.3, 5.0), Vector3(0, -0.15, z), Color(0.3, 0.3, 0.32), 3.0)
	# Guarda-corpo da ponte e muro do outro lado do canal.
	for lado in [-1.0, 1.0]:
		_bloco(Vector3(0.2, 1.0, 5.0), Vector3(lado * LARGURA_RUA / 2.0, 0.5, z), Color(0.5, 0.5, 0.5), 2.0)
	_bloco(Vector3(largura_total, 3.0, 0.4), Vector3(0, 1.5, z - 2.7), Color(0.4, 0.4, 0.42), 4.0)
	# Mureta na beira do canal, fora da ponte: só se atravessa pela ponte.
	var comprimento_mureta := largura_total / 2.0 - LARGURA_RUA / 2.0
	for lado in [-1.0, 1.0]:
		var x: float = lado * (LARGURA_RUA / 2.0 + comprimento_mureta / 2.0)
		_bloco(Vector3(comprimento_mureta, 1.0, 0.3), Vector3(x, 0.5, z + 2.25), Color(0.5, 0.5, 0.5), 2.0)


func _postes(meia_rua: float) -> void:
	var z := -COMPRIMENTO / 2.0 + 4.0
	var lado := -1.0
	while z < COMPRIMENTO / 2.0:
		var x := lado * (meia_rua + 0.4)
		_bloco(Vector3(0.15, 4.5, 0.15), Vector3(x, 2.25, z), Color(0.3, 0.3, 0.3), 1.0)
		_bloco(Vector3(0.5, 0.15, 0.3), Vector3(x - lado * 0.3, 4.5, z), Color(0.9, 0.8, 0.5), 1.0, false)
		var luz := OmniLight3D.new()
		luz.light_color = Color(1.0, 0.78, 0.45)
		luz.light_energy = 1.6
		luz.omni_range = 9.0
		luz.position = Vector3(x - lado * 0.3, 4.2, z)
		add_child(luz)
		postes.append(luz)
		z += DISTANCIA_POSTES
		lado = -lado


## Um bloco cinza com colisão (ou só visual, com colide = false).
func _bloco(tamanho: Vector3, posicao: Vector3, cor: Color, escala_uv: float, colide: bool = true) -> void:
	var malha := BoxMesh.new()
	malha.size = tamanho
	var visual := MeshInstance3D.new()
	visual.mesh = malha
	visual.material_override = Materiais.objeto(cor, escala_uv)
	if not colide:
		visual.position = posicao
		add_child(visual)
		return
	var corpo := StaticBody3D.new()
	corpo.position = posicao
	var forma := BoxShape3D.new()
	forma.size = tamanho
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	corpo.add_child(colisao)
	corpo.add_child(visual)
	add_child(corpo)


func _process(_delta: float) -> void:
	if _captura.is_empty():
		return
	_quadros += 1
	if _quadros == QUADROS_ANTES_DA_CAPTURA:
		get_viewport().get_texture().get_image().save_png(_captura)
		get_tree().quit()
