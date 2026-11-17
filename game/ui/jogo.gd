extends Control
## Janela da investigação (Fase 1, "texto e botões"): tudo clicável, sem digitar comandos.
##
## A janela é só uma frente para o interpretador de texto (ui/texto/interpretador.gd): cada
## clique vira um comando já testado, e a resposta aparece no diário embaixo. Assim a lógica
## continua num lugar só.
##
## Rodar: .\tools\jogar.ps1 -Semente 7     (ou abrir o projeto no Godot e apertar F5)

const Gerador := preload("res://core/casos/gerador_casos.gd")
const Sessao := preload("res://core/investigacao/sessao.gd")
const Interpretador := preload("res://ui/texto/interpretador.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")

const RESOLUCOES := ["matar", "banir", "prender", "curar", "apaziguar", "negociar", "expor", "abandonar"]

const COR_FUNDO := Color("#17130f")
const COR_PAINEL := Color("#241d16")
const COR_PAPEL := Color("#e6d8b8")
const COR_TINTA := Color("#2b2017")
const COR_VERMELHO := Color("#a3271c")
const COR_AMBAR := Color("#e0a43c")
const COR_APAGADO := Color("#7d6f5c")

var sessao: RefCounted
var fmt: RefCounted
var semente := 1

var _criaturas: Dictionary
var _textos: Dictionary
var _resultado_mostrado := false

# Referências da interface
var _titulo: Label
var _info: Label
var _semente_campo: SpinBox
var _lugares: VBoxContainer
var _pessoas: VBoxContainer
var _pistas: VBoxContainer
var _depoimentos: VBoxContainer
var _hipoteses: VBoxContainer
var _diario: RichTextLabel
var _teste_opcao: OptionButton
var _alvo_opcao: OptionButton
var _teste_descricao: Label
var _resolucao_opcao: OptionButton
var _especie_opcao: OptionButton
var _pessoa_opcao: OptionButton
var _dialogo: AcceptDialog
var _lixo: Array = []


func _ready() -> void:
	if is_inside_tree():
		var janela := get_window()
		janela.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		janela.title = "Monster Contracts — investigação (Fase 1)"
		# Cabe em qualquer monitor: ocupa a área útil da tela (sem a barra de tarefas).
		janela.min_size = Vector2i(900, 600)
		janela.mode = Window.MODE_MAXIMIZED
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--semente="):
			semente = arg.trim_prefix("--semente=").to_int()
	montar()
	novo_caso(semente)


## Gera um caso e reinicia a investigação.
func novo_caso(nova_semente: int) -> void:
	semente = nova_semente
	var caso := Gerador.gerar(semente)
	_criaturas = Catalogo.carregar_criaturas()["criaturas"]
	_textos = Catalogo.carregar_textos_marcas()["dados"]
	sessao = Sessao.new(caso, _criaturas, Catalogo.carregar_bairro(caso["bairro"])["dados"], Catalogo.carregar_config_investigacao()["dados"])
	fmt = Interpretador.new(sessao, _criaturas, _textos)
	_resultado_mostrado = false
	if _diario:
		_diario.clear()
		_escrever(fmt.abertura().replace("Digite 'ajuda' para ver os comandos.", "Clique nos lugares à esquerda para investigar."))
	if _semente_campo:
		_semente_campo.set_value_no_signal(semente)
	atualizar()


## Executa um comando do interpretador, escreve a resposta no diário e atualiza a tela.
func executar(comando: String) -> String:
	var resposta: String = fmt.executar(comando)
	_escrever(resposta)
	atualizar()
	return resposta


# ---------------------------------------------------------------- montagem

func montar() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var tema := Theme.new()
	tema.default_font_size = 15
	theme = tema

	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 12)
	add_child(margem)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 10)
	margem.add_child(raiz)

	raiz.add_child(_montar_topo())

	var meio := HBoxContainer.new()
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meio.add_theme_constant_override("separation", 10)
	raiz.add_child(meio)
	meio.add_child(_coluna("Bairro", 1.0, _montar_bairro()))
	meio.add_child(_coluna("Caderno", 2.2, _montar_caderno()))
	meio.add_child(_coluna("Hipóteses", 1.2, _montar_hipoteses()))

	_diario = RichTextLabel.new()
	_diario.custom_minimum_size = Vector2(0, 130)
	_diario.scroll_following = true
	_diario.selection_enabled = true
	_diario.add_theme_color_override("default_color", COR_PAPEL)
	raiz.add_child(_painel(_diario, COR_PAINEL))

	_dialogo = AcceptDialog.new()
	_dialogo.title = "Desfecho do caso"
	_dialogo.dialog_autowrap = true
	add_child(_dialogo)


func _montar_topo() -> Control:
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 16)
	_titulo = Label.new()
	_titulo.add_theme_font_size_override("font_size", 22)
	_titulo.add_theme_color_override("font_color", COR_AMBAR)
	topo.add_child(_titulo)
	_info = Label.new()
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.add_theme_color_override("font_color", COR_PAPEL)
	topo.add_child(_info)
	var rotulo := Label.new()
	rotulo.text = "Caso nº"
	rotulo.add_theme_color_override("font_color", COR_APAGADO)
	topo.add_child(rotulo)
	_semente_campo = SpinBox.new()
	_semente_campo.min_value = 1
	_semente_campo.max_value = 999999
	topo.add_child(_semente_campo)
	var novo := Button.new()
	novo.text = "Novo caso"
	novo.pressed.connect(func() -> void: novo_caso(int(_semente_campo.value)))
	topo.add_child(novo)
	var sorteio := Button.new()
	sorteio.text = "Caso aleatório"
	sorteio.pressed.connect(func() -> void: novo_caso(randi_range(1, 99999)))
	topo.add_child(sorteio)
	return topo


func _montar_bairro() -> Control:
	var caixa := VBoxContainer.new()
	caixa.add_child(_subtitulo("Lugares e casas (clique para ir e examinar)"))
	_lugares = VBoxContainer.new()
	caixa.add_child(_lugares)
	var pesquisar := _botao("Pesquisar boletins e registros (2h30)", func() -> void: executar("pesquisar"))
	caixa.add_child(pesquisar)
	caixa.add_child(_subtitulo("Quem está aqui agora"))
	_pessoas = VBoxContainer.new()
	caixa.add_child(_pessoas)
	caixa.add_child(_botao("Falar com o cliente", func() -> void: executar("entrevistar cliente")))
	return caixa


func _montar_caderno() -> Control:
	var abas := TabContainer.new()
	abas.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_pistas = VBoxContainer.new()
	_pistas.name = "Pistas"
	abas.add_child(_rolagem(_pistas, "Pistas"))

	_depoimentos = VBoxContainer.new()
	abas.add_child(_rolagem(_depoimentos, "Depoimentos"))

	var testes := VBoxContainer.new()
	testes.name = "Testes de campo"
	testes.add_child(_texto_ajuda("Um teste provoca a criatura. O resultado sai na manhã seguinte à espera, e o tempo passa."))
	_teste_opcao = OptionButton.new()
	_teste_opcao.item_selected.connect(func(_i: int) -> void: _atualizar_alvos())
	testes.add_child(_teste_opcao)
	_teste_descricao = _texto_ajuda("")
	testes.add_child(_teste_descricao)
	_alvo_opcao = OptionButton.new()
	testes.add_child(_alvo_opcao)
	testes.add_child(_botao("Fazer o teste", _fazer_teste))
	abas.add_child(testes)

	var encerrar := VBoxContainer.new()
	encerrar.name = "Encerrar o caso"
	encerrar.add_child(_texto_ajuda("Quando tiver certeza, aja. Isso ENCERRA o caso: a criatura certa, o jeito certo e, quando preciso, a pessoa certa."))
	_resolucao_opcao = OptionButton.new()
	for r in RESOLUCOES:
		_resolucao_opcao.add_item(r.capitalize())
		_resolucao_opcao.set_item_metadata(_resolucao_opcao.item_count - 1, r)
	encerrar.add_child(_rotulado("O que fazer", _resolucao_opcao))
	_especie_opcao = OptionButton.new()
	encerrar.add_child(_rotulado("Com qual criatura", _especie_opcao))
	_pessoa_opcao = OptionButton.new()
	encerrar.add_child(_rotulado("Com quem (se for o caso)", _pessoa_opcao))
	var agir := _botao("Agir e encerrar o caso", _agir)
	agir.add_theme_color_override("font_color", COR_VERMELHO)
	encerrar.add_child(agir)
	abas.add_child(encerrar)
	return abas


func _montar_hipoteses() -> Control:
	var caixa := VBoxContainer.new()
	var modo := OptionButton.new()
	for m in ["padrao", "assistido", "puro"]:
		modo.add_item({"padrao": "Modo padrão (filtra)", "assistido": "Modo assistido (sugere)", "puro": "Modo puro (sem filtro)"}[m])
		modo.set_item_metadata(modo.item_count - 1, m)
	modo.item_selected.connect(func(i: int) -> void: executar("modo %s" % modo.get_item_metadata(i)))
	caixa.add_child(modo)
	_hipoteses = VBoxContainer.new()
	caixa.add_child(_hipoteses)
	return _rolagem(caixa, "Hipóteses")


# ---------------------------------------------------------------- atualização

func atualizar() -> void:
	if sessao == null or _lugares == null:
		return
	_esvaziar_lixo()
	var caso: Dictionary = sessao.caso
	var contrato: Dictionary = caso["contrato"]
	_titulo.text = "Caso nº %d · %s" % [semente, sessao.bairro.dados["nome"]]
	_info.text = "Agora: %s   |   Prazo: %s   |   Recompensa: R$ %d   |   Suspeita: %d" % [fmt.data(sessao.minuto), fmt.data(int(contrato["prazo_minuto"])), int(contrato["recompensa"]), sessao.suspeita]
	_atualizar_lugares()
	_atualizar_pessoas()
	_atualizar_pistas()
	_atualizar_depoimentos()
	_atualizar_hipoteses()
	_atualizar_acoes()
	if sessao.encerrado() and not _resultado_mostrado:
		_resultado_mostrado = true
		_dialogo.dialog_text = fmt.executar("resultado")
		if _dialogo.is_inside_tree():
			_dialogo.popup_centered(Vector2i(560, 260))


func _atualizar_lugares() -> void:
	_limpar(_lugares)
	for local in sessao.locais():
		_lugares.add_child(_botao_lugar(local, fmt.nome_local(local)))
	for casa in sessao.casas():
		var familia: String = casa["familia"]
		_lugares.add_child(_botao_lugar(casa["local"], "%s%s" % [fmt.nome_local(casa["local"]), " · família %s" % familia if not familia.is_empty() else " · vazia"]))


func _botao_lugar(local: String, texto: String) -> Button:
	var b := _botao(("➤ " if local == sessao.local_atual() else "") + texto, func() -> void: executar("ir %s" % local))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if local == sessao.local_atual():
		b.add_theme_color_override("font_color", COR_AMBAR)
	return b


func _atualizar_pessoas() -> void:
	_limpar(_pessoas)
	var aqui: Array = sessao.pessoas_aqui()
	if sessao.local_atual().is_empty():
		_pessoas.add_child(_texto_ajuda("Vá a um lugar para ver quem está lá."))
	elif aqui.is_empty():
		_pessoas.add_child(_texto_ajuda("Ninguém acordado por aqui agora."))
	for npc_id in aqui:
		var linha := HBoxContainer.new()
		var rotulo := Label.new()
		rotulo.text = fmt.descrever_pessoa(sessao.npc(npc_id))
		rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rotulo.add_theme_color_override("font_color", COR_PAPEL)
		linha.add_child(rotulo)
		var conversar := _botao("Conversar", func() -> void: executar("entrevistar %s" % npc_id))
		conversar.disabled = sessao.fechado(npc_id) or sessao.encerrado()
		linha.add_child(conversar)
		_pessoas.add_child(linha)


func _atualizar_pistas() -> void:
	_limpar(_pistas)
	var pistas: Array = sessao.caderno.pistas()
	if pistas.is_empty():
		_pistas.add_child(_texto_ajuda("Nenhuma pista ainda. Vá aos lugares e pesquise os registros."))
	for pista in pistas:
		var local: String = pista["local"]
		var vence := "não vence" if int(pista["valida_ate"]) < 0 else "some em %s" % fmt.data(int(pista["valida_ate"]))
		var cabecalho := "%s · %s" % [fmt.nome_local(local) if not local.is_empty() else "Registros", vence]
		_pistas.add_child(_cartao(pista["id"], cabecalho, fmt.texto_pista(pista), false))


func _atualizar_depoimentos() -> void:
	_limpar(_depoimentos)
	var deps: Array = sessao.caderno.depoimentos()
	if deps.is_empty():
		_depoimentos.add_child(_texto_ajuda("Ninguém contou nada ainda. Converse com as pessoas e com o cliente."))
	for dep in deps:
		_depoimentos.add_child(_cartao(dep["id"], "Contado por %s" % fmt.nome(dep["npc"]), fmt.texto_depoimento(dep), true))


## Cartão de papel com uma pista ou depoimento, as ligações feitas e os seletores.
func _cartao(id: String, cabecalho: String, texto: String, e_depoimento: bool) -> Control:
	var caixa := VBoxContainer.new()
	var topo := Label.new()
	topo.text = cabecalho
	topo.add_theme_font_size_override("font_size", 12)
	topo.add_theme_color_override("font_color", COR_VERMELHO)
	caixa.add_child(topo)
	var corpo := Label.new()
	corpo.text = texto
	corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	corpo.add_theme_color_override("font_color", COR_TINTA)
	caixa.add_child(corpo)

	for tag in sessao.caderno.ligacoes().get(id, []):
		var linha := HBoxContainer.new()
		var lig := Label.new()
		lig.text = "↳ ligada a: %s" % fmt.texto_caracteristica(tag)
		lig.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lig.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lig.add_theme_color_override("font_color", Color("#3b5a2a"))
		linha.add_child(lig)
		linha.add_child(_botao("desligar", func() -> void: executar("desligar %s %s" % [id, tag])))
		caixa.add_child(linha)

	var ligar := OptionButton.new()
	ligar.add_item("Ligar a uma característica do bestiário…")
	ligar.set_item_disabled(0, true)
	for tag in sessao.caderno.vocabulario():
		ligar.add_item(fmt.texto_caracteristica(tag))
		ligar.set_item_metadata(ligar.item_count - 1, tag)
	ligar.item_selected.connect(func(i: int) -> void: executar("ligar %s %s" % [id, ligar.get_item_metadata(i)]))
	ligar.disabled = sessao.encerrado()
	caixa.add_child(ligar)

	var pessoas: Dictionary = sessao.caderno.pessoas()
	if not pessoas.is_empty():
		var confrontar := OptionButton.new()
		confrontar.add_item("Usar como prova contra…")
		confrontar.set_item_disabled(0, true)
		for npc_id in pessoas:
			confrontar.add_item(fmt.nome(npc_id))
			confrontar.set_item_metadata(confrontar.item_count - 1, npc_id)
		confrontar.item_selected.connect(func(i: int) -> void: executar("confrontar %s %s" % [confrontar.get_item_metadata(i), id]))
		confrontar.disabled = sessao.encerrado()
		caixa.add_child(confrontar)
	return _painel(caixa, COR_PAPEL)


func _atualizar_hipoteses() -> void:
	_limpar(_hipoteses)
	var caderno: RefCounted = sessao.caderno
	var compativeis: Array = caderno.compativeis()
	var ligadas: Array = caderno.tags_ligadas()
	for especie in caderno.especies():
		var caixa := VBoxContainer.new()
		var nome := Label.new()
		var riscada: bool = especie in caderno.riscadas()
		var marca := "★ " if caderno.circulada() == especie else ""
		nome.text = "%s%s%s" % [marca, _criaturas[especie]["nome"], " (riscada)" if riscada else ("" if especie in compativeis else " (não explica as ligações)")]
		nome.add_theme_font_size_override("font_size", 17)
		nome.add_theme_color_override("font_color", COR_APAGADO if riscada or not especie in compativeis else COR_AMBAR)
		caixa.add_child(nome)
		for tag in caderno.caracteristicas_de(especie):
			var c := Label.new()
			c.text = ("✓ " if tag in ligadas else "· ") + fmt.texto_caracteristica(tag)
			c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			c.add_theme_font_size_override("font_size", 13)
			c.add_theme_color_override("font_color", COR_PAPEL if tag in ligadas else COR_APAGADO)
			caixa.add_child(c)
		var botoes := HBoxContainer.new()
		botoes.add_child(_botao("Riscar", func() -> void: executar("riscar %s" % especie)))
		botoes.add_child(_botao("Circular", func() -> void: executar("circular %s" % especie)))
		caixa.add_child(botoes)
		_hipoteses.add_child(_painel(caixa, COR_PAINEL))
	for s in caderno.sugestoes():
		_hipoteses.add_child(_texto_ajuda("Sugestão: ligar \"%s\" a \"%s\"." % [_resumo_fonte(s["fonte"]), fmt.texto_caracteristica(s["tag"])]))


func _resumo_fonte(id: String) -> String:
	for p in sessao.caderno.pistas():
		if p["id"] == id:
			return fmt.texto_pista(p).left(50)
	for d in sessao.caderno.depoimentos():
		if d["id"] == id:
			return fmt.texto_depoimento(d).left(50)
	return id


func _atualizar_acoes() -> void:
	var teste_atual := _teste_opcao.selected
	_teste_opcao.clear()
	for t in sessao.testes_disponiveis():
		_teste_opcao.add_item(t["nome"])
		_teste_opcao.set_item_metadata(_teste_opcao.item_count - 1, t)
	if teste_atual >= 0 and teste_atual < _teste_opcao.item_count:
		_teste_opcao.select(teste_atual)
	_atualizar_alvos()

	var especie_atual := _especie_opcao.selected
	_especie_opcao.clear()
	for especie in sessao.caderno.especies():
		_especie_opcao.add_item(_criaturas[especie]["nome"])
		_especie_opcao.set_item_metadata(_especie_opcao.item_count - 1, especie)
	if especie_atual >= 0 and especie_atual < _especie_opcao.item_count:
		_especie_opcao.select(especie_atual)

	var pessoa_atual := _pessoa_opcao.selected
	_pessoa_opcao.clear()
	_pessoa_opcao.add_item("(ninguém)")
	_pessoa_opcao.set_item_metadata(0, "")
	for npc in sessao.caso["npcs"]:
		_pessoa_opcao.add_item(fmt.descrever_pessoa(npc))
		_pessoa_opcao.set_item_metadata(_pessoa_opcao.item_count - 1, npc["id"])
	if pessoa_atual >= 0 and pessoa_atual < _pessoa_opcao.item_count:
		_pessoa_opcao.select(pessoa_atual)


func _atualizar_alvos() -> void:
	_alvo_opcao.clear()
	if _teste_opcao.selected < 0:
		return
	var teste: Dictionary = _teste_opcao.get_item_metadata(_teste_opcao.selected)
	_teste_descricao.text = teste["descricao"]
	if teste["alvo"] == "pessoa":
		for npc in sessao.caso["npcs"]:
			_alvo_opcao.add_item(fmt.descrever_pessoa(npc))
			_alvo_opcao.set_item_metadata(_alvo_opcao.item_count - 1, npc["id"])
	else:
		for local in sessao.locais():
			_alvo_opcao.add_item(fmt.nome_local(local))
			_alvo_opcao.set_item_metadata(_alvo_opcao.item_count - 1, local)
		for casa in sessao.casas():
			_alvo_opcao.add_item(fmt.nome_local(casa["local"]))
			_alvo_opcao.set_item_metadata(_alvo_opcao.item_count - 1, casa["local"])


func _fazer_teste() -> void:
	if _teste_opcao.selected < 0 or _alvo_opcao.selected < 0:
		_escrever("Escolha um teste e um alvo.")
		return
	var teste: Dictionary = _teste_opcao.get_item_metadata(_teste_opcao.selected)
	executar("testar %s %s" % [teste["id"], _alvo_opcao.get_item_metadata(_alvo_opcao.selected)])


func _agir() -> void:
	var resolucao: String = _resolucao_opcao.get_item_metadata(_resolucao_opcao.selected)
	if resolucao == "abandonar":
		executar("agir abandonar")
		return
	if _especie_opcao.selected < 0:
		_escrever("Escolha a criatura.")
		return
	var especie: String = _especie_opcao.get_item_metadata(_especie_opcao.selected)
	var pessoa: String = _pessoa_opcao.get_item_metadata(_pessoa_opcao.selected) if _pessoa_opcao.selected >= 0 else ""
	executar(("agir %s %s %s" % [resolucao, especie, pessoa]).strip_edges())


# ---------------------------------------------------------------- peças

func _escrever(texto: String) -> void:
	if _diario and not texto.is_empty():
		_diario.append_text(texto + "\n\n")


func _coluna(titulo: String, peso: float, conteudo: Control) -> Control:
	var caixa := VBoxContainer.new()
	caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caixa.size_flags_stretch_ratio = peso
	var t := Label.new()
	t.text = titulo.to_upper()
	t.add_theme_font_size_override("font_size", 13)
	t.add_theme_color_override("font_color", COR_APAGADO)
	caixa.add_child(t)
	conteudo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if conteudo is ScrollContainer or conteudo is TabContainer:
		caixa.add_child(conteudo)
	else:
		caixa.add_child(_rolagem(conteudo, titulo))
	return caixa


func _rolagem(conteudo: Control, nome: String) -> ScrollContainer:
	var rolagem := ScrollContainer.new()
	rolagem.name = nome
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(conteudo)
	return rolagem


func _painel(conteudo: Control, cor: Color) -> PanelContainer:
	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(3)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	estilo.content_margin_top = 8
	estilo.content_margin_bottom = 8
	painel.add_theme_stylebox_override("panel", estilo)
	painel.add_child(conteudo)
	return painel


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.pressed.connect(acao)
	return b


func _subtitulo(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_color_override("font_color", COR_AMBAR)
	return l


func _texto_ajuda(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", COR_APAGADO)
	return l


func _rotulado(texto: String, controle: Control) -> Control:
	var caixa := VBoxContainer.new()
	var l := Label.new()
	l.text = texto
	l.add_theme_color_override("font_color", COR_PAPEL)
	caixa.add_child(l)
	caixa.add_child(controle)
	return caixa


## Tira os elementos antigos da tela. Eles só são destruídos no PRÓXIMO redesenho: o botão
## que acabou de ser clicado pode estar entre eles, ainda avisando do clique, e destruir um
## objeto nesse momento é erro (e pode travar o jogo).
func _limpar(caixa: Node) -> void:
	for filho in caixa.get_children():
		caixa.remove_child(filho)
		_lixo.append(filho)


func _esvaziar_lixo() -> void:
	for velho in _lixo:
		if is_instance_valid(velho):
			velho.free()
	_lixo.clear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_esvaziar_lixo()
