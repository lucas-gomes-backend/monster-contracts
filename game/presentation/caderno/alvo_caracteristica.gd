extends PanelContainer
## Uma característica do bestiário no caderno. Recebe um cartão de evidência solto em
## cima dela (arrastar e soltar) e mostra as evidências já ligadas, cada uma com um "x"
## para desligar. Não diz se a ligação está certa: isso é trabalho do jogador (docs/05).

signal soltou(fonte: String, tag: String)
signal desligou(fonte: String, tag: String)

const COR_FUNDO := Color("#1d1a15")
const COR_DESTAQUE := Color("#4a3a1c")
const COR_TEXTO := Color("#d9cdb0")
const COR_LIGADA := Color("#9bbf7a")

var tag: String = ""
var _estilo: StyleBoxFlat


## ligadas: [{"fonte": id, "resumo": texto curto}]
func montar(id_tag: String, texto: String, ligadas: Array) -> void:
	tag = id_tag
	name = "Caracteristica_" + id_tag
	_estilo = StyleBoxFlat.new()
	_estilo.bg_color = COR_FUNDO
	_estilo.border_color = Color("#5a4a2a")
	_estilo.set_border_width_all(1)
	_estilo.set_content_margin_all(4)
	add_theme_stylebox_override("panel", _estilo)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 0)
	add_child(coluna)
	var rotulo := Label.new()
	rotulo.text = ("✓ " if not ligadas.is_empty() else "· ") + texto
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.add_theme_font_size_override("font_size", 10)
	rotulo.add_theme_color_override("font_color", COR_LIGADA if not ligadas.is_empty() else COR_TEXTO)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(rotulo)
	for ligada in ligadas:
		var linha := HBoxContainer.new()
		var resumo := Label.new()
		resumo.text = "  ↳ " + str(ligada["resumo"])
		resumo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		resumo.clip_text = true
		resumo.add_theme_font_size_override("font_size", 9)
		resumo.add_theme_color_override("font_color", COR_TEXTO)
		linha.add_child(resumo)
		var tirar := Button.new()
		tirar.text = "x"
		tirar.flat = true
		tirar.tooltip_text = "Desligar"
		tirar.add_theme_font_size_override("font_size", 9)
		var fonte: String = ligada["fonte"]
		tirar.pressed.connect(func() -> void: desligou.emit(fonte, tag))
		linha.add_child(tirar)
		coluna.add_child(linha)


func aceita(dados: Variant) -> bool:
	return dados is Dictionary and dados.get("tipo", "") == "evidencia"


func receber(dados: Variant) -> void:
	if aceita(dados):
		soltou.emit(dados["fonte"], tag)


func _can_drop_data(_posicao: Vector2, dados: Variant) -> bool:
	var ok := aceita(dados)
	_estilo.bg_color = COR_DESTAQUE if ok else COR_FUNDO
	return ok


func _drop_data(_posicao: Vector2, dados: Variant) -> void:
	_estilo.bg_color = COR_FUNDO
	receber(dados)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT or what == NOTIFICATION_DRAG_END:
		if _estilo:
			_estilo.bg_color = COR_FUNDO
