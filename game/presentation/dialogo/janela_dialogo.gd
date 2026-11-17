extends CanvasLayer
## Janela de diálogo: caixa na parte de baixo da tela com o nome, as falas e as opções
## numeradas (clique ou tecla 1 a 9). Só mostra o estado que conversa.gd devolve.

signal escolheu(opcao: String)
signal fechou

var aberta: bool = false
var nome: Label
var descricao: Label
var falas: RichTextLabel
var opcoes: VBoxContainer
var _ids: Array[String] = []
var _acabou: bool = false


func montar() -> void:
	layer = 6
	visible = false
	var painel := PanelContainer.new()
	painel.position = Vector2(16, 196)
	painel.size = Vector2(608, 252)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.03, 0.03, 0.04, 0.9)
	estilo.border_color = Color(0.55, 0.45, 0.25)
	estilo.set_border_width_all(1)
	estilo.set_content_margin_all(8)
	painel.add_theme_stylebox_override("panel", estilo)
	add_child(painel)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 4)
	painel.add_child(coluna)
	nome = Label.new()
	nome.add_theme_font_size_override("font_size", 14)
	nome.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	coluna.add_child(nome)
	descricao = Label.new()
	descricao.add_theme_font_size_override("font_size", 10)
	descricao.modulate = Color(0.7, 0.7, 0.7)
	coluna.add_child(descricao)
	falas = RichTextLabel.new()
	falas.fit_content = false
	falas.scroll_following = true
	falas.custom_minimum_size = Vector2(590, 84)
	falas.add_theme_font_size_override("normal_font_size", 12)
	coluna.add_child(falas)
	# Muitas provas no caderno viram uma lista com rolagem, sem sair da caixa.
	var rolagem := ScrollContainer.new()
	rolagem.custom_minimum_size = Vector2(590, 104)
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(rolagem)
	opcoes = VBoxContainer.new()
	opcoes.add_theme_constant_override("separation", 0)
	opcoes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(opcoes)


## Mostra um estado de conversa ({"nome", "descricao", "falas", "opcoes", "acabou"}).
func mostrar(estado: Dictionary) -> void:
	aberta = true
	visible = true
	_acabou = estado["acabou"]
	nome.text = estado["nome"]
	descricao.text = estado["descricao"]
	falas.clear()
	for fala in estado["falas"]:
		falas.append_text(str(fala) + "\n")
	for filho in opcoes.get_children():
		opcoes.remove_child(filho)
		filho.queue_free()
	_ids.clear()
	var lista: Array = estado["opcoes"]
	if _acabou:
		lista = [{"id": "fim", "texto": "(Encerrar a conversa.)"}]
	for i in lista.size():
		var botao := Button.new()
		botao.text = "%d. %s" % [i + 1, lista[i]["texto"]]
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.flat = true
		botao.add_theme_font_size_override("font_size", 12)
		botao.pressed.connect(escolher_numero.bind(i))
		opcoes.add_child(botao)
		_ids.append(lista[i]["id"])


## Escolhe a opção pela posição (0 = a primeira).
func escolher_numero(i: int) -> void:
	if i < 0 or i >= _ids.size():
		return
	if _ids[i] == "fim":
		fechar()
		return
	escolheu.emit(_ids[i])


func fechar() -> void:
	aberta = false
	visible = false
	fechou.emit()


func ids_das_opcoes() -> Array[String]:
	return _ids.duplicate()


func _input(evento: InputEvent) -> void:
	if not aberta or not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	var tecla: int = evento.physical_keycode
	if tecla >= KEY_1 and tecla <= KEY_9:
		escolher_numero(tecla - KEY_1)
		get_viewport().set_input_as_handled()
