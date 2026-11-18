extends Node3D
## Criação de personagem (docs/09): o boneco girando à direita e, à esquerda, os sliders de
## corpo e rosto, a pele, o cabelo, a barba e uma roupa por parte. "Aleatório" sorteia tudo;
## "Começar" leva para a cidade com essa aparência (guardada em ui/inicio.gd).

const Catalogo := preload("res://core/dados/catalogo.gd")
const Aparencia := preload("res://core/personagem/aparencia.gd")
const Corpo := preload("res://presentation/personagem/corpo.gd")
const Rng := preload("res://core/rng.gd")
const Inicio := preload("res://ui/inicio.gd")

const LISTAS := [["peles", "Pele"], ["cabelos", "Cabelo"], ["cores_de_cabelo", "Cor do cabelo"], ["barbas", "Barba"],
	["cabeca", "Na cabeça"], ["tronco", "Tronco"], ["pernas", "Pernas"], ["pes", "Pés"]]

var aparencia: RefCounted
var boneco: Node3D
var disfarce: Label
var _controles: Dictionary = {}  # id -> HSlider ou OptionButton
var _sorteios := 0


func _ready() -> void:
	aparencia = Aparencia.new(Catalogo.carregar_config_aparencia()["dados"])
	if not Inicio.aparencia_escolhida.is_empty():
		aparencia.de_dados(Inicio.aparencia_escolhida)
	_montar_palco()
	_montar_controles()
	atualizar()
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--captura="):
			_captura = argumento.trim_prefix("--captura=")
		elif argumento == "--agente":
			for parte in ["tronco", "pernas", "pes"]:
				aparencia.escolher(parte, {"tronco": "terno", "pernas": "calca_social", "pes": "sapato_social"}[parte])
			atualizar()


var _captura := ""
var _quadros := 0


func _process(delta: float) -> void:
	boneco.rotation.y += delta * 0.6
	# --captura=<png>: tira uma foto da tela e fecha (para conferir sem abrir o jogo).
	if not _captura.is_empty():
		_quadros += 1
		if _quadros == 30:
			get_viewport().get_texture().get_image().save_png(_captura)
			get_tree().quit()


func _montar_palco() -> void:
	var ambiente := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#17130f")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.68, 0.62)
	ambiente.environment = env
	add_child(ambiente)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-35, 30, 0)
	add_child(luz)
	boneco = Node3D.new()
	boneco.name = "Boneco"
	add_child(boneco)
	var camera := Camera3D.new()
	camera.position = Vector3(-0.75, 1.05, 2.7)
	camera.fov = 45.0
	add_child(camera)
	camera.look_at(Vector3(-0.75, 0.95, 0))


func _montar_controles() -> void:
	var camada := CanvasLayer.new()
	add_child(camada)
	var rolagem := ScrollContainer.new()
	rolagem.position = Vector2(8, 8)
	rolagem.size = Vector2(300, 464)
	camada.add_child(rolagem)
	var coluna := VBoxContainer.new()
	coluna.custom_minimum_size = Vector2(284, 0)
	rolagem.add_child(coluna)
	var titulo := Label.new()
	titulo.text = "CRIAR O CAÇADOR"
	titulo.add_theme_font_size_override("font_size", 18)
	coluna.add_child(titulo)
	var cfg: Dictionary = Catalogo.carregar_config_aparencia()["dados"]
	for id in cfg["sliders"]:
		var rotulo := Label.new()
		rotulo.text = cfg["sliders"][id]["nome"]
		rotulo.add_theme_font_size_override("font_size", 11)
		coluna.add_child(rotulo)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = aparencia.sliders[id]
		slider.value_changed.connect(func(v): aparencia.definir_slider(id, v); atualizar())
		coluna.add_child(slider)
		_controles["slider:" + id] = slider
	for par in LISTAS:
		var lista: String = par[0]
		var rotulo := Label.new()
		rotulo.text = par[1]
		rotulo.add_theme_font_size_override("font_size", 11)
		coluna.add_child(rotulo)
		var escolha := OptionButton.new()
		var opcoes: Array = aparencia.opcoes(lista)
		for o in opcoes:
			escolha.add_item(o["nome"])
		escolha.selected = _indice(lista)
		escolha.item_selected.connect(func(i): aparencia.escolher(lista, opcoes[i]["id"]); atualizar())
		coluna.add_child(escolha)
		_controles["lista:" + lista] = escolha
	disfarce = Label.new()
	disfarce.autowrap_mode = TextServer.AUTOWRAP_WORD
	disfarce.add_theme_font_size_override("font_size", 11)
	disfarce.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	coluna.add_child(disfarce)
	var aleatorio := Button.new()
	aleatorio.text = "Aleatório"
	aleatorio.pressed.connect(sortear)
	coluna.add_child(aleatorio)
	var comecar := Button.new()
	comecar.text = "Começar na cidade"
	comecar.pressed.connect(comecar_na_cidade)
	coluna.add_child(comecar)
	var voltar := Button.new()
	voltar.text = "Voltar"
	voltar.pressed.connect(func(): guardar(); get_tree().change_scene_to_file("res://ui/inicio.tscn"))
	coluna.add_child(voltar)


## O índice da opção atual numa lista (para o OptionButton).
func _indice(lista: String) -> int:
	var atual: String
	match lista:
		"peles":
			atual = aparencia.pele
		"cabelos":
			atual = aparencia.cabelo
		"cores_de_cabelo":
			atual = aparencia.cor_do_cabelo
		"barbas":
			atual = aparencia.barba
		_:
			atual = aparencia.roupas.get(lista, "")
	var opcoes: Array = aparencia.opcoes(lista)
	for i in opcoes.size():
		if opcoes[i]["id"] == atual:
			return i
	return 0


## Remonta o boneco e mostra se as roupas formam um disfarce.
func atualizar() -> void:
	Corpo.montar(boneco, aparencia)
	var d: Dictionary = aparencia.disfarce()
	disfarce.text = "Disfarce: %s. %s" % [d["nome"], d["descricao"]] if not d.is_empty() else "Sem disfarce. (Terno, calça social e sapato social = agente federal.)"


## Sorteia tudo (sliders e listas). Determinístico: cada clique usa o próximo stream.
func sortear() -> void:
	_sorteios += 1
	var g: RandomNumberGenerator = Rng.new(_sorteios).stream("aparencia")
	for id in aparencia.sliders:
		aparencia.definir_slider(id, g.randf())
		_controles["slider:" + id].set_value_no_signal(aparencia.sliders[id])
	for par in LISTAS:
		var opcoes: Array = aparencia.opcoes(par[0])
		var i := g.randi_range(0, opcoes.size() - 1)
		aparencia.escolher(par[0], opcoes[i]["id"])
		_controles["lista:" + par[0]].selected = i
	atualizar()


func guardar() -> void:
	Inicio.aparencia_escolhida = aparencia.como_dados()


func comecar_na_cidade() -> void:
	guardar()
	Inicio.bairro_inicial = "valongo"
	get_tree().change_scene_to_file("res://presentation/cidade/bairro.tscn")
