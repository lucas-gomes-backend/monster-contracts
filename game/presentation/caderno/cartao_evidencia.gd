extends PanelContainer
## Cartão de papel com uma evidência do caderno (pista ou depoimento). Dá para arrastar
## e soltar numa característica do bestiário (alvo_caracteristica.gd) para ligar as duas.

const COR_PAPEL := Color("#d9cdb0")
const COR_TINTA := Color("#2a241c")
const COR_VERMELHO := Color("#8a2b1d")

var fonte: String = ""


func montar(id: String, cabecalho: String, texto: String, ligacoes: int) -> void:
	fonte = id
	name = "Cartao_" + id
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COR_PAPEL
	estilo.set_content_margin_all(4)
	add_theme_stylebox_override("panel", estilo)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 0)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(coluna)
	var topo := _rotulo(cabecalho, 9, COR_VERMELHO)
	coluna.add_child(topo)
	coluna.add_child(_rotulo(texto, 10, COR_TINTA))
	if ligacoes > 0:
		coluna.add_child(_rotulo("↳ %d %s" % [ligacoes, "ligação" if ligacoes == 1 else "ligações"], 9, Color("#3b5a2a")))


func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rotulo


## O que vai junto com o mouse ao arrastar: o id da evidência.
func dados_do_arraste() -> Dictionary:
	return {"tipo": "evidencia", "fonte": fonte}


func _get_drag_data(_posicao: Vector2) -> Variant:
	# Uma cópia pequena do cartão segue o mouse.
	var copia := Label.new()
	copia.text = (get_child(0).get_child(1) as Label).text.left(40)
	copia.add_theme_font_size_override("font_size", 10)
	copia.add_theme_color_override("font_color", COR_TINTA)
	var fundo := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COR_PAPEL
	fundo.add_theme_stylebox_override("panel", estilo)
	fundo.add_child(copia)
	set_drag_preview(fundo)
	return dados_do_arraste()
