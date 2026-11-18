extends CanvasLayer
## Mapa do bairro (tecla M): ir aos lugares e às casas do caso, pesquisar registros, ligar
## para o cliente, testes de campo e a ação que encerra o caso. Depois de agir, mostra o
## relatório com toda a verdade. Tudo passa pela sessão de investigação do núcleo.

signal foi_para(local: String)
signal ligou_cliente
signal fechou

const RESOLUCOES := ["matar", "banir", "prender", "curar", "apaziguar", "negociar", "expor", "abandonar"]
const COR_FUNDO := Color("#141210")
const COR_TITULO := Color("#d9a441")
const COR_TEXTO := Color("#d9cdb0")

var sessao: RefCounted
var fmt: RefCounted
var criaturas: Dictionary = {}
var aberto: bool = false
var titulo: Label
var lugares: VBoxContainer
var registro: RichTextLabel
var teste: OptionButton
var alvo: OptionButton
var resolucao: OptionButton
var especie: OptionButton
var pessoa: OptionButton
var _acoes: Array[Button] = []


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

	var meio := HBoxContainer.new()
	meio.add_theme_constant_override("separation", 8)
	meio.custom_minimum_size = Vector2(0, 250)
	coluna.add_child(meio)
	var rolagem := ScrollContainer.new()
	rolagem.custom_minimum_size = Vector2(250, 250)
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	meio.add_child(rolagem)
	lugares = VBoxContainer.new()
	lugares.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lugares.add_theme_constant_override("separation", 0)
	rolagem.add_child(lugares)

	var acoes := VBoxContainer.new()
	acoes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acoes.add_theme_constant_override("separation", 2)
	meio.add_child(acoes)
	acoes.add_child(_botao("Pesquisar boletins e registros (delegacia)", pesquisar))
	acoes.add_child(_botao("Ligar para o cliente", func() -> void: ligou_cliente.emit()))
	acoes.add_child(_rotulo("Teste de campo (o tempo passa até o resultado)", 10, COR_TITULO))
	teste = _opcoes(acoes)
	teste.item_selected.connect(func(_i: int) -> void: _preencher_alvos())
	alvo = _opcoes(acoes)
	acoes.add_child(_botao("Fazer o teste", _testar_selecionado))
	acoes.add_child(_rotulo("Agir: ENCERRA o caso", 10, COR_TITULO))
	resolucao = _opcoes(acoes)
	for r in RESOLUCOES:
		resolucao.add_item(r.capitalize())
		resolucao.set_item_metadata(resolucao.item_count - 1, r)
	especie = _opcoes(acoes)
	pessoa = _opcoes(acoes)
	acoes.add_child(_botao("Agir", _agir_selecionado))

	registro = RichTextLabel.new()
	registro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	registro.scroll_following = true
	registro.add_theme_font_size_override("normal_font_size", 10)
	registro.add_theme_color_override("default_color", COR_TEXTO)
	coluna.add_child(registro)
	coluna.add_child(_rotulo("M ou Esc fecha o mapa.", 9, Color("#6d665a")))


func abrir() -> void:
	aberto = true
	visible = true
	atualizar()


func fechar() -> void:
	aberto = false
	visible = false
	fechou.emit()


## Vai a um lugar ou casa: quem monta a cena (rua.gd) ouve o sinal e troca o cenário.
func ir(local: String) -> void:
	if sessao.encerrado():
		return
	foi_para.emit(local)
	fechar()


func pesquisar() -> void:
	if sessao.encerrado():
		return
	var r: Dictionary = sessao.pesquisar()
	var linhas: Array = ["Você pesquisou boletins e registros antigos (%d min)." % int(r["minutos"])]
	for pista in sessao.caderno.pistas():
		if pista["id"] in r["novas"]:
			linhas.append("[anotado] " + fmt.texto_pista(pista))
	if r["novas"].is_empty():
		linhas.append("Nada de novo.")
	escrever("\n".join(linhas))
	atualizar()


func testar(teste_id: String, alvo_id: String) -> void:
	if sessao.encerrado():
		return
	escrever(fmt.texto_teste(sessao.aplicar_teste(teste_id, alvo_id)))
	atualizar()


## Encerra o caso. Depois disso o mapa mostra o resultado e o relatório.
func agir(resolucao_id: String, especie_id: String, pessoa_id: String) -> void:
	var r: Dictionary = sessao.agir(resolucao_id, especie_id, pessoa_id)
	if not r["ok"]:
		escrever("Não deu: %s." % r["erro"])
		return
	escrever("CASO ENCERRADO.\n" + fmt.texto_resultado() + "\n\n" + fmt.texto_relatorio())
	atualizar()


func escrever(texto: String) -> void:
	registro.append_text(texto + "\n\n")


func atualizar() -> void:
	titulo.text = "Mapa do bairro %s · %s" % [sessao.bairro.dados["nome"], fmt.data(sessao.minuto)]
	for filho in lugares.get_children():
		lugares.remove_child(filho)
		filho.queue_free()
	lugares.add_child(_rotulo("Lugares", 10, COR_TITULO))
	for local in sessao.locais():
		lugares.add_child(_botao_lugar(local, fmt.nome_local(local)))
	lugares.add_child(_rotulo("Casas", 10, COR_TITULO))
	for c in sessao.casas():
		var familia: String = "família " + c["familia"] if not str(c["familia"]).is_empty() else "vazia"
		lugares.add_child(_botao_lugar(c["local"], "%s (%s)" % [fmt.nome_local(c["local"]), familia]))
	_preencher_testes()
	_preencher_desfecho()
	var encerrado: bool = sessao.encerrado()
	for botao in _acoes:
		botao.disabled = encerrado
	for filho in lugares.get_children():
		if filho is Button:
			filho.disabled = encerrado


func _botao_lugar(local: String, texto: String) -> Button:
	var aqui: bool = sessao.local_atual() == local
	var botao := _botao(("▶ " if aqui else "") + texto, func() -> void: ir(local), false)
	botao.name = "Lugar_" + local.replace("/", "_")
	botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return botao


func _preencher_testes() -> void:
	var escolhido := teste.selected
	teste.clear()
	for t in sessao.testes_disponiveis():
		teste.add_item(t["nome"])
		teste.set_item_metadata(teste.item_count - 1, t)
	if escolhido >= 0 and escolhido < teste.item_count:
		teste.select(escolhido)
	_preencher_alvos()


func _preencher_alvos() -> void:
	alvo.clear()
	if teste.selected < 0:
		return
	var t: Dictionary = teste.get_item_metadata(teste.selected)
	if t["alvo"] == "pessoa":
		for npc in sessao.caso["npcs"]:
			alvo.add_item(fmt.descrever_pessoa(npc))
			alvo.set_item_metadata(alvo.item_count - 1, npc["id"])
	else:
		for local in sessao.locais():
			alvo.add_item(fmt.nome_local(local))
			alvo.set_item_metadata(alvo.item_count - 1, local)
		for c in sessao.casas():
			alvo.add_item(fmt.nome_local(c["local"]))
			alvo.set_item_metadata(alvo.item_count - 1, c["local"])


func _preencher_desfecho() -> void:
	var escolhida := especie.selected
	especie.clear()
	for e in sessao.caderno.especies():
		especie.add_item(criaturas[e]["nome"])
		especie.set_item_metadata(especie.item_count - 1, e)
	if escolhida >= 0 and escolhida < especie.item_count:
		especie.select(escolhida)
	var quem := pessoa.selected
	pessoa.clear()
	pessoa.add_item("(ninguém)")
	pessoa.set_item_metadata(0, "")
	for npc in sessao.caso["npcs"]:
		pessoa.add_item(fmt.descrever_pessoa(npc))
		pessoa.set_item_metadata(pessoa.item_count - 1, npc["id"])
	if quem >= 0 and quem < pessoa.item_count:
		pessoa.select(quem)


func _testar_selecionado() -> void:
	if teste.selected < 0 or alvo.selected < 0:
		escrever("Escolha um teste e um alvo.")
		return
	testar(teste.get_item_metadata(teste.selected)["id"], alvo.get_item_metadata(alvo.selected))


func _agir_selecionado() -> void:
	var r: String = resolucao.get_item_metadata(maxi(resolucao.selected, 0))
	var e: String = especie.get_item_metadata(especie.selected) if especie.selected >= 0 else ""
	var p: String = pessoa.get_item_metadata(pessoa.selected) if pessoa.selected >= 0 else ""
	agir(r, e, p)


func _opcoes(pai: Control) -> OptionButton:
	var opcoes := OptionButton.new()
	opcoes.add_theme_font_size_override("font_size", 10)
	opcoes.clip_text = true
	opcoes.custom_minimum_size = Vector2(340, 0)
	pai.add_child(opcoes)
	return opcoes


func _rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	return rotulo


func _botao(texto: String, acao: Callable, e_acao: bool = true) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.add_theme_font_size_override("font_size", 10)
	botao.pressed.connect(acao)
	if e_acao:
		_acoes.append(botao)
	return botao


func _input(evento: InputEvent) -> void:
	if aberto and (evento.is_action_pressed("mapa") or evento.is_action_pressed("soltar_mouse")):
		fechar()
		get_viewport().set_input_as_handled()
