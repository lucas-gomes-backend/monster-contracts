extends Node3D
## Greybox da Fase 2: uma rua noturna de Santos em blocos cinza, para andar com o caçador.
## Rua, calçadas, casas baixas dos dois lados, um canal no fim, postes com luz e névoa.
## Tudo é montado em código (sem sorteio): o mesmo resultado toda vez.
## Pistas de exemplo (game/data/greybox/rua.json) para examinar, pegar, girar e fotografar.
## Um caso de verdade é gerado (--semente=N, padrão 12) e o cliente espera na calçada para
## conversar; a conversa usa a sessão de investigação do núcleo.
## Argumentos opcionais: --captura=caminho.png salva uma imagem depois de alguns quadros e fecha;
## --lanterna começa com a lanterna ligada; --inclinar=G inclina a câmera G graus; --exame=N abre o exame da pista N (para conferir o visual).

const Cacador := preload("res://presentation/personagem/cacador.gd")
const Materiais := preload("res://presentation/ps1/materiais.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Mira := preload("res://presentation/inspecao/mira.gd")
const Album := preload("res://presentation/inspecao/album.gd")
const Pista3D := preload("res://presentation/inspecao/pista_3d.gd")
const Exame := preload("res://presentation/inspecao/exame.gd")
const Gerador := preload("res://core/casos/gerador_casos.gd")
const Sessao := preload("res://core/investigacao/sessao.gd")
const Interpretador := preload("res://ui/texto/interpretador.gd")
const Conversa := preload("res://presentation/dialogo/conversa.gd")
const JanelaDialogo := preload("res://presentation/dialogo/janela_dialogo.gd")
const Morador := preload("res://presentation/personagem/morador.gd")
const CadernoTela := preload("res://presentation/caderno/caderno_tela.gd")

const SEMENTE_PADRAO := 12
const LUGAR_DO_CLIENTE := Vector3(4.6, 0.15, 19.0)

const COMPRIMENTO := 60.0
const LARGURA_RUA := 7.0
const LARGURA_CALCADA := 2.5
const ALTURA_CALCADA := 0.15
const DISTANCIA_POSTES := 12.0
const QUADROS_ANTES_DA_CAPTURA := 30
const DURACAO_DO_FLASH := 0.15

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
var pistas: Array[Node3D] = []
var album: RefCounted
var exame: CanvasLayer
var config_inspecao: Dictionary = {}
var aviso: Label
var contador_fotos: Label
var mensagem: Label
var flash: ColorRect
var sessao: RefCounted
var fmt: RefCounted
var conversa: RefCounted
var dialogo: CanvasLayer
var moradores: Array[Node3D] = []
var caderno: CanvasLayer
var _criaturas: Dictionary = {}
var relogio: Label
var camada_interface: CanvasLayer
var _alvo := -1
var _tempo_da_mensagem := 0.0
var _captura := ""
var _quadros := 0


func _ready() -> void:
	var semente := SEMENTE_PADRAO
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--semente="):
			semente = int(argumento.trim_prefix("--semente="))
	if cacador == null:
		montar(semente)
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--conversa"):
			conversar(moradores[0])
		elif argumento == "--caderno":
			for pista in pistas:
				anotar_pista_da_rua(pista.marca)
			sessao.caderno.ligar("rua_pegadas_cao_grande", "pegadas_cao_grande")
			abrir_caderno()
		elif argumento.begins_with("--captura="):
			_captura = argumento.trim_prefix("--captura=")
		elif argumento == "--lanterna":
			cacador.alternar_lanterna()
		elif argumento.begins_with("--inclinar="):
			var graus := float(argumento.trim_prefix("--inclinar="))
			cacador.olhar(Vector2(0.0, -graus / float(cacador.config["sensibilidade_mouse"])))
		elif argumento.begins_with("--exame="):
			examinar(int(argumento.trim_prefix("--exame=")))


## Monta a cena inteira para o caso da semente. Pode ser chamado sem estar na árvore (testes).
func montar(semente: int = SEMENTE_PADRAO) -> void:
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

	config_inspecao = Catalogo.carregar_config_inspecao()["dados"]
	cacador = Cacador.new()
	cacador.name = "Cacador"
	cacador.montar({}, config_inspecao)
	cacador.position = Vector3(1.0, 0.1, COMPRIMENTO / 2.0 - 4.0)
	add_child(cacador)
	_colocar_pistas()
	album = Album.new(int(config_inspecao["filme"]))

	exame = Exame.new()
	exame.montar(config_inspecao["girar_sensibilidade"])
	add_child(exame)
	_comecar_caso(semente)
	dialogo = JanelaDialogo.new()
	dialogo.montar()
	dialogo.escolheu.connect(_ao_escolher)
	dialogo.fechou.connect(_ao_fechar_dialogo)
	add_child(dialogo)
	caderno = CadernoTela.new()
	caderno.montar(sessao, fmt, _criaturas)
	caderno.fechou.connect(_destravar)
	add_child(caderno)
	# O filtro PS1 fica por cima da cena e do exame; os textos de ajuda, por cima dele.
	var camada_filtro := CanvasLayer.new()
	camada_filtro.layer = 10
	add_child(camada_filtro)
	filtro = ColorRect.new()
	filtro.set_anchors_preset(Control.PRESET_FULL_RECT)
	filtro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filtro.material = Materiais.tela()
	camada_filtro.add_child(filtro)
	_montar_interface()


## Gera o caso, abre a sessão de investigação e põe o cliente na calçada.
func _comecar_caso(semente: int) -> void:
	var caso := Gerador.gerar(semente)
	var criaturas: Dictionary = Catalogo.carregar_criaturas()["criaturas"]
	_criaturas = criaturas
	var textos: Dictionary = Catalogo.carregar_textos_marcas()["dados"]
	sessao = Sessao.new(caso, criaturas, Catalogo.carregar_bairro(caso["bairro"])["dados"],
		Catalogo.carregar_config_investigacao()["dados"])
	fmt = Interpretador.new(sessao, criaturas, textos)
	conversa = Conversa.new(sessao, fmt)
	var cliente: String = caso["contrato"]["cliente"]
	var morador := Morador.new()
	morador.montar(cliente, fmt.nome(cliente))
	morador.position = LUGAR_DO_CLIENTE
	morador.rotation.y = -PI / 2.0
	add_child(morador)
	moradores.append(morador)


func _colocar_pistas() -> void:
	var textos: Dictionary = Catalogo.carregar_textos_marcas()["dados"]
	for dados in Catalogo.carregar_greybox("rua")["dados"]["pistas"]:
		var pista := Pista3D.new()
		pista.montar(dados, textos)
		add_child(pista)
		pistas.append(pista)


func _montar_interface() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 11
	add_child(camada)
	camada_interface = camada
	flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(flash)
	var ajuda := _rotulo(camada, Vector2(8, 6), 11)
	ajuda.text = "WASD andar · Shift correr · F lanterna · E examinar ou conversar · Tab caderno\nbotão direito: mira · esquerdo (mirando): fotografa · Esc solta o mouse"
	ajuda.modulate = Color(0.85, 0.8, 0.6, 0.8)
	aviso = _rotulo(camada, Vector2(0, 300), 13)
	aviso.size = Vector2(640, 20)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contador_fotos = _rotulo(camada, Vector2(540, 456), 12)
	relogio = _rotulo(camada, Vector2(8, 456), 12)
	mensagem = _rotulo(camada, Vector2(20, 420), 12)
	mensagem.size = Vector2(600, 30)
	mensagem.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_atualizar_interface()


func _rotulo(pai: Node, posicao: Vector2, tamanho_fonte: int) -> Label:
	var rotulo := Label.new()
	rotulo.position = posicao
	rotulo.add_theme_font_size_override("font_size", tamanho_fonte)
	pai.add_child(rotulo)
	return rotulo


func _atualizar_interface() -> void:
	contador_fotos.text = "filme: %d/%d" % [album.restantes(), album.filme]
	relogio.text = fmt.data(sessao.minuto)
	# O caderno ocupa a tela toda: a ajuda, o relógio e o filme da rua saem da frente.
	camada_interface.visible = not caderno.aberto
	aviso.text = ""
	if _alvo < 0 or ocupado():
		return
	if _alvo >= pistas.size():
		aviso.text = "[E] conversar com %s" % moradores[_alvo - pistas.size()].nome
		return
	var pista: Node3D = pistas[_alvo]
	aviso.text = "[E] pegar e examinar" if pista.pegavel else "[E] examinar"


## Examinando, conversando ou com o caderno aberto: o caçador não anda e o mundo não reage à mira.
func ocupado() -> bool:
	return exame.aberto or dialogo.aberta or caderno.aberto


func abrir_caderno() -> void:
	if ocupado():
		return
	caderno.abrir()
	_travar()


func _travar() -> void:
	cacador.bloqueado = true
	if is_inside_tree():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_atualizar_interface()


func _destravar() -> void:
	cacador.bloqueado = false
	if is_inside_tree():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_atualizar_interface()


## Provisório até as pistas do caso irem para a rua (tarefa "ligar o núcleo às cenas"):
## as pistas de exemplo examinadas ou fotografadas entram no caderno como pistas da rua.
func anotar_pista_da_rua(marca: String) -> void:
	sessao.caderno.anotar_pista({"id": "rua_" + marca, "tipo": "marca", "tag": marca, "local": "",
		"onde": "Rua (exemplo)", "minuto": sessao.minuto, "valida_ate": -1, "detectar": "olho_nu"})


func _avisar(texto: String) -> void:
	mensagem.text = texto
	_tempo_da_mensagem = 4.0


## Posições das pistas no mundo.
func _pontos_das_pistas() -> Array:
	var pontos: Array = []
	for pista in pistas:
		pontos.append(pista.position)
	return pontos


## O que está na mira agora, ou -1. Os índices começam pelas pistas e seguem pelas pessoas.
## Olho e frente vêm da câmera; o alcance conta do corpo.
func alvo_na_mira(olho: Vector3, frente: Vector3) -> int:
	var corpo := cacador.position + Vector3(0, 0.9, 0)
	var pontos := _pontos_das_pistas()
	for morador in moradores:
		pontos.append(morador.ponto_de_conversa())
	return Mira.escolher_alvo(olho, frente, corpo, pontos,
		config_inspecao["examinar_alcance"], config_inspecao["examinar_angulo"])


## Começa a conversa com uma pessoa: o caçador para e o mouse fica solto para as opções.
func conversar(morador: Node3D) -> void:
	if ocupado():
		return
	dialogo.mostrar(conversa.abrir(morador.npc_id))
	_travar()


func _ao_escolher(opcao: String) -> void:
	dialogo.mostrar(conversa.escolher(opcao))
	_atualizar_interface()


func _ao_fechar_dialogo() -> void:
	_destravar()


## Abre o exame de uma pista: o caçador para e o mouse fica solto para girar.
func examinar(indice: int) -> void:
	if indice < 0 or indice >= pistas.size() or ocupado():
		return
	exame.abrir(pistas[indice])
	anotar_pista_da_rua(pistas[indice].marca)
	_travar()


func fechar_exame() -> void:
	exame.fechar()
	_destravar()


## Tira uma foto do que a câmera vê. Devolve a foto, ou {} sem filme.
func fotografar(olho: Vector3, frente: Vector3, fov: float) -> Dictionary:
	var marcas: Array = []
	for i in Mira.no_quadro(olho, frente, _pontos_das_pistas(), config_inspecao["foto_alcance"], fov):
		if pistas[i].visible:
			marcas.append(pistas[i].marca)
	var imagem: Image = null
	if is_inside_tree():
		imagem = get_viewport().get_texture().get_image()
	var foto: Dictionary = album.fotografar(marcas, imagem)
	for marca in foto.get("marcas", []):
		anotar_pista_da_rua(marca)
	if foto.is_empty():
		_avisar("O filme acabou.")
	elif foto["marcas"].is_empty():
		_avisar("Foto %d: nada que pareça uma pista." % foto["numero"])
	else:
		var nomes: Array[String] = []
		for pista in pistas:
			if foto["marcas"].has(pista.marca):
				nomes.append(pista.texto)
		_avisar("Foto %d: %s" % [foto["numero"], " ".join(nomes)])
	if not foto.is_empty():
		flash.color.a = 0.9
	_atualizar_interface()
	return foto


func _unhandled_input(evento: InputEvent) -> void:
	if caderno.aberto:
		return
	if dialogo.aberta:
		if evento.is_action_pressed("soltar_mouse"):
			dialogo.fechar()
			get_viewport().set_input_as_handled()
		return
	if exame.aberto:
		if evento.is_action_pressed("examinar") or evento.is_action_pressed("soltar_mouse"):
			fechar_exame()
			get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed("caderno"):
		abrir_caderno()
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("examinar") and _alvo >= 0:
		if _alvo >= pistas.size():
			conversar(moradores[_alvo - pistas.size()])
		else:
			examinar(_alvo)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("fotografar") and cacador.mirando:
		var camera: Camera3D = cacador.camera
		fotografar(camera.global_position, -camera.global_basis.z, camera.fov)
		get_viewport().set_input_as_handled()


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


func _process(delta: float) -> void:
	if not ocupado():
		var camera: Camera3D = cacador.camera
		var alvo := alvo_na_mira(camera.global_position, -camera.global_basis.z)
		if alvo != _alvo:
			_alvo = alvo
			_atualizar_interface()
	flash.color.a = maxf(0.0, flash.color.a - delta / DURACAO_DO_FLASH)
	if _tempo_da_mensagem > 0.0:
		_tempo_da_mensagem -= delta
		if _tempo_da_mensagem <= 0.0:
			mensagem.text = ""
	if _captura.is_empty():
		return
	_quadros += 1
	if _quadros == QUADROS_ANTES_DA_CAPTURA:
		get_viewport().get_texture().get_image().save_png(_captura)
		get_tree().quit()
