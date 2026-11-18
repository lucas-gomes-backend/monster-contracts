extends Control
## Menu de pausa (Esc na cidade): o jogo para, e dá para continuar, ver os controles, mexer nas
## opções (sensibilidade do mouse, volume, tela cheia), voltar ao menu principal ou sair.
## As opções ficam guardadas em user://opcoes.cfg e valem nas próximas vezes.

const ARQUIVO := "user://opcoes.cfg"
const CONTROLES := """WASD: andar · Shift: liga/desliga a corrida · Mouse: olhar
Botão direito: mirar · Esquerdo: atirar · R: recarregar · 1-3: arma
F: lanterna · E: carro, bueiro, motel e benzedeira
Q (segurar): bolsos · I: mochila · T: ritual · N: conversar
H: habilidades · M: mapa de viagem (no carro) · Esc: pausa"""

var cena: Node  # bairro_cena
var _pagina := "principal"
var _caixa: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.03, 0.03, 0.82)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	_caixa = VBoxContainer.new()
	_caixa.position = Vector2(190, 70)
	_caixa.custom_minimum_size = Vector2(260, 0)
	_caixa.add_theme_constant_override("separation", 8)
	add_child(_caixa)
	mostrar("principal")


## Esc no menu: volta à página principal ou continua o jogo. (Com o jogo pausado, só esta
## tela recebe teclas.)
func _input(evento: InputEvent) -> void:
	if not visible or not evento.is_action_pressed("soltar_mouse"):
		return
	if _pagina != "principal":
		mostrar("principal")
	else:
		cena.fechar_pausa()
	get_viewport().set_input_as_handled()


## Troca a página do menu: "principal", "controles" ou "opcoes".
func mostrar(pagina: String) -> void:
	_pagina = pagina
	if _caixa == null:
		return
	for filho in _caixa.get_children():
		_caixa.remove_child(filho)
		filho.queue_free()
	_titulo({"principal": "PAUSA", "controles": "CONTROLES", "opcoes": "OPÇÕES"}[pagina])
	match pagina:
		"principal":
			_botao("Continuar", func(): cena.fechar_pausa())
			_botao("Controles", func(): mostrar("controles"))
			_botao("Opções", func(): mostrar("opcoes"))
			_botao("Menu principal", func(): cena.ir_para_o_menu())
			_botao("Sair do jogo", func(): get_tree().quit())
		"controles":
			var texto := Label.new()
			texto.text = CONTROLES
			texto.add_theme_font_size_override("font_size", 11)
			_caixa.add_child(texto)
			_botao("Voltar", func(): mostrar("principal"))
		"opcoes":
			var o := ler()
			_slider("Sensibilidade do mouse", 0.03, 0.4, float(o["sensibilidade"]), func(v): aplicar("sensibilidade", v))
			_slider("Volume", 0.0, 1.0, float(o["volume"]), func(v): aplicar("volume", v))
			var cheia := CheckBox.new()
			cheia.text = "Tela cheia"
			cheia.button_pressed = bool(o["tela_cheia"])
			cheia.toggled.connect(func(v): aplicar("tela_cheia", v))
			_caixa.add_child(cheia)
			_botao("Voltar", func(): mostrar("principal"))


func _titulo(texto: String) -> void:
	var t := Label.new()
	t.text = texto
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", Color("#e6d8b8"))
	_caixa.add_child(t)


func _botao(texto: String, acao: Callable) -> void:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(260, 32)
	b.pressed.connect(acao)
	_caixa.add_child(b)


func _slider(nome: String, minimo: float, maximo: float, valor: float, acao: Callable) -> void:
	var r := Label.new()
	r.text = nome
	r.add_theme_font_size_override("font_size", 11)
	_caixa.add_child(r)
	var s := HSlider.new()
	s.min_value = minimo
	s.max_value = maximo
	s.step = 0.01
	s.value = valor
	s.value_changed.connect(acao)
	_caixa.add_child(s)


## As opções guardadas (ou as padrão).
static func ler() -> Dictionary:
	var o := {"sensibilidade": 0.15, "volume": 0.8, "tela_cheia": false}
	var arquivo := ConfigFile.new()
	if arquivo.load(ARQUIVO) == OK:
		for chave in o:
			o[chave] = arquivo.get_value("opcoes", chave, o[chave])
	return o


## Muda uma opção, guarda e aplica.
func aplicar(chave: String, valor: Variant) -> void:
	var arquivo := ConfigFile.new()
	arquivo.load(ARQUIVO)
	arquivo.set_value("opcoes", chave, valor)
	arquivo.save(ARQUIVO)
	aplicar_todas(cena)


## Aplica as opções guardadas: sensibilidade no caçador, volume e tela cheia.
static func aplicar_todas(cena_da_cidade: Node) -> void:
	var o := ler()
	if cena_da_cidade != null and cena_da_cidade.cacador != null:
		cena_da_cidade.cacador.config["sensibilidade_mouse"] = float(o["sensibilidade"])
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(o["volume"]), 0.0001)))
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(o["tela_cheia"]) else DisplayServer.WINDOW_MODE_WINDOWED)
