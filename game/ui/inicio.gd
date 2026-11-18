extends Control
## Tela inicial da versão para testar (o .exe): escolhe o que jogar no corte vertical.
## A cidade 3D (presentation/cidade/bairro.tscn) ou o caso pelo caderno (ui/jogo.tscn).

const CIDADE := "res://presentation/cidade/bairro.tscn"
const CASO := "res://ui/jogo.tscn"
const COR_FUNDO := Color("#17130f")
const COR_PAPEL := Color("#e6d8b8")

const CRIACAO := "res://presentation/personagem/criacao.tscn"

## Bairro onde a cidade começa (lido por bairro_cena.gd, se a cena for aberta por aqui).
static var bairro_inicial := "valongo"
## A aparência feita na criação de personagem ({} = a padrão).
static var aparencia_escolhida: Dictionary = {}


func _ready() -> void:
	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var coluna := VBoxContainer.new()
	coluna.set_anchors_preset(Control.PRESET_CENTER)
	coluna.position = Vector2(170, 90)
	coluna.custom_minimum_size = Vector2(300, 0)
	coluna.add_theme_constant_override("separation", 10)
	add_child(coluna)
	var titulo := Label.new()
	titulo.text = "MONSTER CONTRACTS"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.add_theme_color_override("font_color", COR_PAPEL)
	coluna.add_child(titulo)
	var sub := Label.new()
	sub.text = "Corte vertical · versão de teste"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.75, 0.7, 0.6))
	coluna.add_child(sub)
	coluna.add_child(_botao("Criar o caçador", func(): get_tree().change_scene_to_file(CRIACAO)))
	coluna.add_child(_botao("Andar pela cidade: Valongo", func(): abrir_cidade("valongo")))
	coluna.add_child(_botao("Andar pela cidade: Centro", func(): abrir_cidade("centro")))
	coluna.add_child(_botao("Investigar um caso (caderno)", func(): get_tree().change_scene_to_file(CASO)))
	coluna.add_child(_botao("Sair", func(): get_tree().quit()))
	var dica := Label.new()
	dica.text = "Na cidade: clique para prender o mouse, Esc solta.\nWASD andar · E carro, bueiro e motel · M mapa (no carro) · I mochila"
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.add_theme_font_size_override("font_size", 11)
	dica.add_theme_color_override("font_color", Color(0.65, 0.6, 0.52))
	coluna.add_child(dica)


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(300, 36)
	b.pressed.connect(acao)
	return b


func abrir_cidade(id: String) -> void:
	bairro_inicial = id
	get_tree().change_scene_to_file(CIDADE)
