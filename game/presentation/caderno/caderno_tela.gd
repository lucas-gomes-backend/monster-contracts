extends CanvasLayer
## Caderno do caçador em tela cheia (docs/05, "O quadro de hipóteses"):
##   esquerda - evidências (pistas e depoimentos), em cartões que dá para arrastar
##   direita  - características do bestiário; soltar um cartão numa delas liga as duas
##   embaixo  - as espécies, compatíveis ou não com as ligações, para riscar e circular
## Tudo o que muda passa pelo caderno do núcleo (core/caderno/caderno.gd).

signal fechou

const CartaoEvidencia := preload("res://presentation/caderno/cartao_evidencia.gd")
const AlvoCaracteristica := preload("res://presentation/caderno/alvo_caracteristica.gd")

const COR_FUNDO := Color("#141210")
const COR_TITULO := Color("#d9a441")
const COR_APAGADO := Color("#6d665a")
const LIMITE_DO_RESUMO := 46

var sessao: RefCounted
var fmt: RefCounted
var criaturas: Dictionary = {}
var aberto: bool = false
var evidencias: VBoxContainer
var caracteristicas: VBoxContainer
var especies: HBoxContainer
var titulo: Label


func montar(sessao_investigacao: RefCounted, interpretador: RefCounted, fichas: Dictionary) -> void:
	sessao = sessao_investigacao
	fmt = interpretador
	criaturas = fichas
	layer = 7
	visible = false
	var fundo := PanelContainer.new()
	fundo.position = Vector2(8, 8)
	fundo.size = Vector2(624, 464)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COR_FUNDO
	estilo.border_color = Color("#5a4a2a")
	estilo.set_border_width_all(1)
	estilo.set_content_margin_all(6)
	fundo.add_theme_stylebox_override("panel", estilo)
	add_child(fundo)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 4)
	fundo.add_child(coluna)
	titulo = _rotulo("", 13, COR_TITULO)
	coluna.add_child(titulo)
	coluna.add_child(_rotulo("Arraste uma evidência e solte numa característica para ligar. O caderno não diz se a ligação está certa. Tab ou Esc fecha.", 9, COR_APAGADO))

	var meio := HBoxContainer.new()
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meio.add_theme_constant_override("separation", 6)
	coluna.add_child(meio)
	evidencias = _lista(meio, "Evidências", 0.48)
	caracteristicas = _lista(meio, "Bestiário: características", 0.52)

	coluna.add_child(_rotulo("Espécies (riscar descarta, circular marca a suspeita principal)", 10, COR_TITULO))
	var rolagem := ScrollContainer.new()
	rolagem.custom_minimum_size = Vector2(0, 74)
	rolagem.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(rolagem)
	especies = HBoxContainer.new()
	especies.add_theme_constant_override("separation", 4)
	rolagem.add_child(especies)


func abrir() -> void:
	aberto = true
	visible = true
	atualizar()


func fechar() -> void:
	aberto = false
	visible = false
	fechou.emit()


## Liga uma evidência a uma característica (o que acontece ao soltar o cartão).
func ligar(fonte: String, tag: String) -> String:
	var erro: String = sessao.caderno.ligar(fonte, tag)
	atualizar()
	return erro


func desligar(fonte: String, tag: String) -> void:
	sessao.caderno.desligar(fonte, tag)
	atualizar()


func riscar(especie: String) -> void:
	if especie in sessao.caderno.riscadas():
		sessao.caderno.desriscar(especie)
	else:
		sessao.caderno.riscar(especie)
	atualizar()


func circular(especie: String) -> void:
	sessao.caderno.circular(especie)
	atualizar()


## Redesenha tudo a partir do caderno do núcleo.
func atualizar() -> void:
	var caderno: RefCounted = sessao.caderno
	titulo.text = "Caderno · %s" % fmt.data(sessao.minuto)
	_limpar(evidencias)
	_limpar(caracteristicas)
	_limpar(especies)
	var ligacoes: Dictionary = caderno.ligacoes()
	for pista in caderno.pistas():
		var cartao := CartaoEvidencia.new()
		var origem: String = pista.get("onde", "Registros") if str(pista.get("local", "")).is_empty() else fmt.nome_local(pista["local"])
		cartao.montar(pista["id"], "Pista · " + origem, fmt.texto_pista(pista), ligacoes.get(pista["id"], []).size())
		evidencias.add_child(cartao)
	for dep in caderno.depoimentos():
		var cartao := CartaoEvidencia.new()
		cartao.montar(dep["id"], "Contado por " + fmt.nome(dep["npc"]), fmt.texto_depoimento(dep), ligacoes.get(dep["id"], []).size())
		evidencias.add_child(cartao)
	if evidencias.get_child_count() == 0:
		evidencias.add_child(_rotulo("Nada anotado ainda. Examine pistas, fotografe e converse com as pessoas.", 10, COR_APAGADO))
	for tag in caderno.vocabulario():
		var ligadas: Array = []
		for fonte in ligacoes:
			if tag in ligacoes[fonte]:
				ligadas.append({"fonte": fonte, "resumo": _resumo(fonte)})
		var alvo := AlvoCaracteristica.new()
		alvo.montar(tag, fmt.texto_caracteristica(tag), ligadas)
		alvo.soltou.connect(func(f: String, t: String) -> void: ligar(f, t))
		alvo.desligou.connect(func(f: String, t: String) -> void: desligar(f, t))
		caracteristicas.add_child(alvo)
	var compativeis: Array = caderno.compativeis()
	for especie in caderno.especies():
		especies.add_child(_ficha_especie(especie, especie in compativeis))


func _ficha_especie(especie: String, compativel: bool) -> Control:
	var caderno: RefCounted = sessao.caderno
	var riscada: bool = especie in caderno.riscadas()
	var circulada: bool = caderno.circulada() == especie
	var caixa := VBoxContainer.new()
	caixa.name = "Especie_" + especie
	caixa.custom_minimum_size = Vector2(118, 0)
	caixa.add_theme_constant_override("separation", 0)
	var nome: String = "(%s)" % criaturas[especie]["nome"] if circulada else criaturas[especie]["nome"]
	var cor := COR_TITULO if compativel and not riscada else COR_APAGADO
	caixa.add_child(_rotulo(nome, 11, cor))
	var estado := "riscada" if riscada else ("compatível" if compativel else "não explica")
	caixa.add_child(_rotulo(estado, 9, COR_APAGADO))
	var botoes := HBoxContainer.new()
	botoes.add_child(_botao("desriscar" if riscada else "riscar", func() -> void: riscar(especie)))
	botoes.add_child(_botao("circular", func() -> void: circular(especie)))
	caixa.add_child(botoes)
	return caixa


func _resumo(fonte: String) -> String:
	var texto := fonte
	for p in sessao.caderno.pistas():
		if p["id"] == fonte:
			texto = fmt.texto_pista(p)
	for d in sessao.caderno.depoimentos():
		if d["id"] == fonte:
			texto = fmt.texto_depoimento(d)
	return texto if texto.length() <= LIMITE_DO_RESUMO else texto.left(LIMITE_DO_RESUMO - 3) + "..."


func _lista(pai: Control, nome: String, peso: float) -> VBoxContainer:
	var coluna := VBoxContainer.new()
	coluna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coluna.size_flags_stretch_ratio = peso
	pai.add_child(coluna)
	coluna.add_child(_rotulo(nome, 10, COR_TITULO))
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	coluna.add_child(rolagem)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 3)
	rolagem.add_child(lista)
	return lista


func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	return rotulo


func _botao(texto: String, acao: Callable) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.add_theme_font_size_override("font_size", 9)
	botao.pressed.connect(acao)
	return botao


func _limpar(caixa: Node) -> void:
	for filho in caixa.get_children():
		caixa.remove_child(filho)
		filho.queue_free()


func _input(evento: InputEvent) -> void:
	if aberto and (evento.is_action_pressed("caderno") or evento.is_action_pressed("soltar_mouse")):
		fechar()
		get_viewport().set_input_as_handled()
