extends Node3D
## A cidade do mapa real para andar (Fase 3): plana, de dia, com névoa esbranquiçada (como
## Silent Hill). Os bairros se encaixam (mesma origem do mapa), num chão só.
##
## Bordas como em Final Fantasy XII: uma linha no chão marca o limite do bairro atual, e os
## bairros vizinhos ficam carregados do outro lado, à vista. Quando o caçador cruza a linha,
## o vizinho vira o atual, os vizinhos dele são carregados e quem ficou longe é descarregado.
## O nome do bairro aparece na tela. As galerias são uma rede só para todos os bairros
## carregados: por baixo da terra, o esgoto liga um bairro ao outro.
## E desce pelo bueiro (escuro: só a lanterna) e sobe pela escada. Minimapa no canto.
## Um relógio corre na cidade, e os moradores dos bairros (com dados em data/neighborhoods)
## seguem a rotina: aparecem nas portas dos lugares e andam pelas ruas (populacao_3d.gd).
## Suspeita e polícia básicas: quem sai do esgoto fica sujo, e ser visto assim faz a
## suspeita subir; observado, a polícia patrulha; procurado, um policial vem atrás e, se
## alcançar, o caçador é detido (perde horas e sai na porta da delegacia). A maré sobe e
## desce: a água das galerias acompanha, e na maré alta não dá para descer.
##
## Argumentos: --bairro=<id> (padrão valongo), --semente=N (padrão 1), --captura=caminho.png,
## --lanterna, --inclinar=G, --virar=G, --vista=cima, --esgoto, --ir=<id> (para conferir o visual).

const Bairro3D := preload("res://presentation/cidade/bairro_3d.gd")
const Cacador := preload("res://presentation/personagem/cacador.gd")
const Materiais := preload("res://presentation/ps1/materiais.gd")
const Mira := preload("res://presentation/inspecao/mira.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Viz := preload("res://core/cidade/vizinhanca.gd")
const Lotes := preload("res://core/cidade/lotes.gd")
const Minimapa := preload("res://presentation/cidade/minimapa.gd")
const Sub := preload("res://core/cidade/subterraneo.gd")
const Subterraneo3D := preload("res://presentation/cidade/subterraneo_3d.gd")
const Rng := preload("res://core/rng.gd")
const Relogio := preload("res://core/tempo/relogio.gd")
const Populacao3D := preload("res://presentation/cidade/populacao_3d.gd")
const Transeuntes3D := preload("res://presentation/cidade/transeuntes_3d.gd")
const Policia3D := preload("res://presentation/cidade/policia_3d.gd")
const Suspeita := preload("res://core/mundo/suspeita.gd")
const Mare := preload("res://core/tempo/mare.gd")
const Ferimentos := preload("res://core/confronto/ferimentos.gd")
const Medo := preload("res://core/confronto/medo.gd")
const Arsenal := preload("res://core/confronto/arsenal.gd")
const Bolsos := preload("res://core/confronto/bolsos.gd")
const Circulo := preload("res://core/confronto/circulo_de_sal.gd")
const Criatura3D := preload("res://presentation/cidade/criatura_3d.gd")
const MenuRadial := preload("res://presentation/cidade/menu_radial.gd")
const Ritual := preload("res://core/confronto/ritual.gd")
const RitualTela := preload("res://presentation/cidade/ritual_tela.gd")
const EstadoCriatura := preload("res://core/confronto/estado_criatura.gd")
const Negociacao := preload("res://core/confronto/negociacao.gd")
const ConversaTela := preload("res://presentation/cidade/conversa_tela.gd")
const TECLAS_DE_OPCAO := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]
const Grade := preload("res://core/inventario/grade.gd")
const Blocos := preload("res://presentation/greybox/blocos.gd")
const Progresso := preload("res://core/progressao/progresso.gd")
const Carro3D := preload("res://presentation/cidade/carro_3d.gd")
const MotelTela := preload("res://presentation/cidade/motel_tela.gd")
const ViagemTela := preload("res://presentation/cidade/viagem_tela.gd")
const Habilidades := preload("res://core/progressao/habilidades.gd")
const HabilidadesTela := preload("res://presentation/cidade/habilidades_tela.gd")
const Condicao := preload("res://core/condicoes/condicao.gd")
const Espiritos3D := preload("res://presentation/cidade/espiritos_3d.gd")
const Interludio := preload("res://core/progressao/interludio.gd")
const PausaTela := preload("res://presentation/cidade/pausa_tela.gd")
const Sons := preload("res://presentation/audio/sons.gd")
const MochilaTela := preload("res://presentation/cidade/mochila_tela.gd")
const TEXTO_DO_EFEITO := {"prende": "Pegou: a criatura está contida!", "fere": "Pegou: a criatura está ferida e vulnerável!",
	"revela": "Pegou: a forma verdadeira apareceu!", "afasta": "Pegou: a criatura recuou!",
	"destroi": "Destruída.", "cura": "Curada: a maldição se quebrou.", "bane": "Banida.", "apazigua": "Apaziguada: foi embora em paz.",
	"negocia": "Acordo feito."}
## Quanto tempo a lanterna fica apagada quando falha de medo (segundos).
const PISCADA_DA_LANTERNA := 0.25
const CORES_DA_SUSPEITA := {"normal": Color(0.15, 0.3, 0.15), "observado": Color(0.6, 0.45, 0.05),
	"procurado": Color(0.7, 0.2, 0.1), "barrado": Color(0.5, 0.05, 0.05)}

const ALCANCE_DO_BUEIRO := 2.5
const ANGULO_DO_BUEIRO := 35.0
const QUADROS_ANTES_DA_CAPTURA := 40
const COR_DA_NEVOA := Color(0.72, 0.73, 0.74)
const MARGEM_DO_CHAO := 60.0
const TEMPO_DO_NOME := 3.0
const NOMES_DOS_DIAS := {"domingo": "Domingo", "segunda": "Segunda", "terca": "Terça", "quarta": "Quarta",
	"quinta": "Quinta", "sexta": "Sexta", "sabado": "Sábado"}

## O bairro atual (onde o caçador está).
var bairro: Node3D
## Bairros montados agora: o atual e os vizinhos dele. {id: Bairro3D}
var carregados: Dictionary = {}
## Limites e divisas de todos os bairros importados (dados leves, sempre na memória).
var limites: Dictionary = {}
var vizinhos: Dictionary = {}
var semente: int = 1
## As galerias dos bairros carregados, numa rede só (Subterraneo3D).
var subterraneo: Node3D
var _ids_da_rede: Array = []
## Relógio da cidade (minutos do mundo) e a gente de cada bairro carregado.
var minuto: int = 0
var minutos_por_segundo: float = 1.0
var populacoes: Dictionary = {}
## Figurantes andando a esmo em cada bairro carregado.
var transeuntes: Dictionary = {}
var relogio: Label
var _sobra_de_minuto := 0.0
## Suspeita (núcleo), maré (núcleo) e a polícia do bairro atual.
var suspeita: RefCounted
var mare: RefCounted
var policia: Node3D
var detencoes: int = 0
var painel: Label
var _alcance_de_quem_ve: float = 12.0
var _minutos_detido: int = 240
var cacador: CharacterBody3D
## Ferimentos e medo do caçador (núcleo, docs/06). Sem criatura no mapa ainda, o medo sobe
## no escuro sem lanterna (noite, galerias) e desce com luz.
var ferimentos: RefCounted
var medo: RefCounted
var _lanterna_apagada := 0.0
## Armas, bolsos e círculos de sal (núcleo); a criatura no campo e o menu radial.
var arsenal: RefCounted
var bolsos: RefCounted
var circulos: Array = []
var criatura: Node3D
var menu: Control
var hud: Label
var _cfg_armas: Dictionary
var _cfg_confronto: Dictionary
## Ritual: a lista do config, o ritual em andamento (ou null), o tempo do passo e a tela.
var rituais: Array = []
var ritual: RefCounted
var tempo_do_passo := 0.0
var segurando := false
var ritual_tela: Control
var _cfg_rituais: Dictionary
## Negociação em andamento (ou null), o gatilho do caso que a criatura cobra e os acordos
## feitos (com a traição escondida, para o relatório e casos futuros).
var negociacao: RefCounted
var gatilho_do_caso: String = ""
var acordos: Array = []
var conversa_tela: Control
var _cfg_negociacao: Dictionary
## Mochila e porta-malas (grades do núcleo), o carro parado, a tela e o que está na mão.
var itens: Dictionary = {}
var mochila: RefCounted
var porta_malas: RefCounted
var carro: Node3D
var mochila_tela: Control
var cursor := Vector2i.ZERO
var na_mao: Dictionary = {}
## Qual grade o cursor está: "mochila" ou "outra" (porta-malas perto do carro, guarda perto do motel).
var foco := "mochila"
var _mouse_antes := Input.MOUSE_MODE_VISIBLE
var _abrindo_mochila := 0.0
var _cfg_inventario: Dictionary
var _g_quebra: RandomNumberGenerator
## Dinheiro, reputação e qualidade (núcleo); o motel (guarda e menu) e o carro dirigível.
var progresso: RefCounted
var guarda_do_motel: RefCounted
var motel_tela: Control
var menu_do_motel := "principal"
var dirigindo := false
var _camadas_do_cacador := Vector2i(1, 1)
var viagem_tela: Control
## Todas as regiões da cidade (contorno), para o mapa de viagem.
var mapa_geral: Array = []
## Habilidades humanas (núcleo) e a tela delas.
var habilidades: RefCounted
var habilidades_tela: Control
## Condição paranormal (uma por vez; no corte vertical, o Sensitivo) e os espíritos errantes.
var condicao: RefCounted
var espiritos: Node3D
var _cfg_condicoes: Dictionary
var _sentidas: Dictionary = {}  # criaturas cuja presença já foi sentida (conta uso uma vez)
var _g_sussurro: RandomNumberGenerator
var _proximo_sussurro := 0.0
## Menu de pausa (Esc): para o jogo; fica numa camada que roda mesmo pausada.
var pausa_tela: Control
## Arte e áudio (docs/09): ciclo de luz, postes acesos perto do caçador, faróis e sons.
var noite: float = 0.0  # 0 = dia, 1 = noite (janelas, postes, faróis)
var luzes_dos_postes: Array[OmniLight3D] = []
var farol: SpotLight3D
var som_ambiente: AudioStreamPlayer
var som_passos: AudioStreamPlayer
var som_tiros: AudioStreamPlayer
var som_sussurro: AudioStreamPlayer
var som_motor: AudioStreamPlayer
var passos_tocados: int = 0
var _cfg_arte: Dictionary
var _andado := 0.0
var _ultima_posicao := Vector3.INF
var _cfg_progressao: Dictionary
var _energia_da_lanterna := 1.0
var ambiente: WorldEnvironment
var sol: DirectionalLight3D
## "rua" ou "esgoto".
var zona: String = "rua"
var aviso: Label
var nome_do_lugar: Label
var minimapa: Control
var _tempo_do_nome := 0.0
var _alvo := -1
var _captura := ""
var _quadros := 0


func _ready() -> void:
	# Aberta pela tela inicial (ui/inicio.gd), começa no bairro escolhido lá.
	var id: String = load("res://ui/inicio.gd").bairro_inicial
	var s := 1
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--bairro="):
			id = argumento.trim_prefix("--bairro=")
		elif argumento.begins_with("--semente="):
			s = int(argumento.trim_prefix("--semente="))
	if bairro == null:
		montar(id, s)
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--captura="):
			_captura = argumento.trim_prefix("--captura=")
			# Na captura o mouse da janela não pode girar a câmera.
			cacador.bloqueado = true
		elif argumento.begins_with("--criatura="):
			trazer_criatura(argumento.trim_prefix("--criatura="))
		elif argumento.begins_with("--hora="):
			minuto = (minuto / 1440) * 1440 + int(argumento.trim_prefix("--hora=")) * 60
			aplicar_luz()
		elif argumento == "--sensitivo":
			condicao.adquirir("sensitivo")
			_sensitivo(0.0, false, INF)
			for e in espiritos.espiritos:
				e.position = cacador.position + (e.position - cacador.position).normalized() * 6.0
		elif argumento == "--dirigir":
			entrar_no_carro()
		elif argumento == "--mapa-de-viagem":
			entrar_no_carro()
			abrir_mapa_de_viagem()
		elif argumento == "--mochila":
			abrir_mochila()
			_mochila_aberta()
		elif argumento == "--lanterna":
			cacador.alternar_lanterna()
		elif argumento.begins_with("--inclinar="):
			cacador.olhar(Vector2(0.0, -float(argumento.trim_prefix("--inclinar=")) / float(cacador.config["sensibilidade_mouse"])))
		elif argumento.begins_with("--ir="):
			var outro: Node3D = carregados.get(argumento.trim_prefix("--ir="))
			if outro:
				cacador.position = outro.chegada()
				verificar_fronteira()
		elif argumento == "--vista=cima":
			_vista_de_cima()
		elif argumento == "--esgoto" and not subterraneo.bueiros.is_empty():
			usar_bueiro(0)
		elif argumento.begins_with("--virar="):
			cacador.virar_para(deg_to_rad(float(argumento.trim_prefix("--virar="))))


## Monta a cidade começando no bairro pedido. Pode ser chamado sem estar na árvore (testes).
func montar(id_bairro: String, semente_do_mundo: int) -> void:
	semente = semente_do_mundo
	var cfg_relogio: Dictionary = Catalogo.carregar_config_relogio_da_cidade()["dados"]
	var inicio: Dictionary = cfg_relogio["inicio"]
	minuto = Relogio.minutos_de(int(inicio["ano"]), int(inicio["mes"]), int(inicio["dia"]), int(inicio["hora"]), int(inicio["minuto"]))
	minutos_por_segundo = cfg_relogio["minutos_por_segundo"]
	var cfg_suspeita: Dictionary = Catalogo.carregar_config_suspeita()["dados"]
	suspeita = Suspeita.new(cfg_suspeita)
	_alcance_de_quem_ve = cfg_suspeita["sujeira"]["alcance_de_quem_ve"]
	_minutos_detido = cfg_suspeita["detencao"]["minutos_perdidos"]
	mare = Mare.new(Catalogo.carregar_config_mare()["dados"])
	var cfg_confronto: Dictionary = Catalogo.carregar_config_confronto()["dados"]
	_cfg_confronto = cfg_confronto
	ferimentos = Ferimentos.new(cfg_confronto["ferimentos"])
	medo = Medo.new(cfg_confronto["medo"], Rng.new(semente).stream("medo"))
	_cfg_armas = Catalogo.carregar_config_armas()["dados"]
	arsenal = Arsenal.new(_cfg_armas, Rng.new(semente).stream("armas"))
	bolsos = Bolsos.new(_cfg_armas["bolsos"])
	_cfg_rituais = Catalogo.carregar_config_rituais()["dados"]
	rituais = _cfg_rituais["rituais"]
	_cfg_negociacao = Catalogo.carregar_config_negociacao()["dados"]
	itens = Catalogo.carregar_itens()["dados"]
	_cfg_inventario = Catalogo.carregar_config_inventario()["dados"]
	_cfg_progressao = Catalogo.carregar_config_progressao()["dados"]
	mapa_geral = Catalogo.carregar_mapa_geral()["dados"]["regioes"]
	habilidades = Habilidades.new(Catalogo.carregar_config_habilidades()["dados"])
	_cfg_condicoes = Catalogo.carregar_config_condicoes()["dados"]
	condicao = Condicao.new(_cfg_condicoes)
	_g_sussurro = Rng.new(semente).stream("sussurros")
	progresso = Progresso.new(_cfg_progressao)
	var tamanho: Vector2i = progresso.tamanho_da_mochila()
	mochila = Grade.new(tamanho.x, tamanho.y, itens)
	var guarda: Array = _cfg_progressao["motel"]["guarda"]
	guarda_do_motel = Grade.new(int(guarda[0]), int(guarda[1]), itens)
	_aplicar_qualidade()
	porta_malas = Grade.new(int(_cfg_inventario["porta_malas"]["largura"]), int(_cfg_inventario["porta_malas"]["altura"]), itens)
	for c in _cfg_inventario["mochila_inicial"]:
		mochila.adicionar(c["item"], int(c["quantidade"]))
	for c in _cfg_inventario["porta_malas_inicial"]:
		porta_malas.adicionar(c["item"], int(c["quantidade"]))
	_g_quebra = Rng.new(semente).stream("frageis")
	# Dia nublado: céu e névoa da mesma cor clara, o fundo some na névoa.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = COR_DA_NEVOA
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.86, 0.88)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = COR_DA_NEVOA
	env.fog_density = 0.035
	ambiente = WorldEnvironment.new()
	ambiente.environment = env
	add_child(ambiente)
	sol = DirectionalLight3D.new()
	sol.name = "Sol"
	sol.light_color = Color(1.0, 0.97, 0.9)
	sol.light_energy = 0.9
	sol.rotation_degrees = Vector3(-55, 35, 0)
	add_child(sol)

	var caixa_da_cidade := Rect2()
	var primeira := true
	for id in Catalogo.bairros_reais():
		var dados: Dictionary = Catalogo.carregar_bairro_real(id)["dados"]
		limites[id] = Lotes._pontos(dados["limite"])
		var c: Array = dados["caixa"]
		var caixa := Rect2(float(c[0]), float(c[1]), float(c[2]) - float(c[0]), float(c[3]) - float(c[1]))
		caixa_da_cidade = caixa if primeira else caixa_da_cidade.merge(caixa)
		primeira = false
	vizinhos = Viz.vizinhos(limites)
	_montar_chao(caixa_da_cidade.grow(MARGEM_DO_CHAO))

	cacador = Cacador.new()
	cacador.name = "Cacador"
	cacador.montar()
	add_child(cacador)
	_montar_interface()
	entrar_em(id_bairro)
	cacador.position = bairro.chegada()
	cacador.virar_para(bairro.giro_chegada)
	_estacionar_carro()
	_montar_arte_e_audio()
	# A aparência feita na criação de personagem (tela inicial), se houver.
	var escolhida: Dictionary = load("res://ui/inicio.gd").aparencia_escolhida
	if not escolhida.is_empty():
		var a = cacador.aparencia
		a.de_dados(escolhida)
		cacador.vestir(a)


## O bairro vira o atual: linha da borda, galerias e bueiros nele; vizinhos carregados.
func entrar_em(id: String) -> void:
	if bairro != null:
		bairro.borda.visible = false
	bairro = _carregar(id)
	bairro.borda.visible = true
	var queridos: Array = [id] + vizinhos.get(id, [])
	for outro in queridos:
		_carregar(outro)
	for velho in carregados.keys():
		if not velho in queridos:
			var no: Node3D = carregados[velho]
			carregados.erase(velho)
			populacoes.erase(velho)
			transeuntes.erase(velho)
			remove_child(no)
			no.queue_free()
	_montar_rede()
	_montar_policia(id)
	nome_do_lugar.text = bairro.dados["nome"]
	nome_do_lugar.add_theme_font_size_override("font_size", 26)
	_tempo_do_nome = TEMPO_DO_NOME
	minimapa.queue_redraw()


## A polícia é a do bairro atual: patrulha pelas ruas dele.
func _montar_policia(id: String) -> void:
	if policia != null:
		remove_child(policia)
		policia.queue_free()
	policia = Policia3D.new()
	policia.montar(id, bairro.dados, semente)
	add_child(policia)
	policia.atualizar(suspeita.nivel(id))


## Uma rede de galerias para todos os bairros carregados (só refaz se o conjunto mudou).
func _montar_rede() -> void:
	var ids: Array = carregados.keys()
	ids.sort()
	if ids == _ids_da_rede and subterraneo != null:
		return
	_ids_da_rede = ids
	if subterraneo != null:
		remove_child(subterraneo)
		subterraneo.queue_free()
	var cfg: Dictionary = Catalogo.carregar_config_subterraneo()["dados"]
	var dados: Array = []
	var area := Rect2()
	for i in ids.size():
		var d: Dictionary = carregados[ids[i]].dados
		dados.append(d)
		var c: Array = d["caixa"]
		var caixa := Rect2(float(c[0]), float(c[1]), float(c[2]) - float(c[0]), float(c[3]) - float(c[1]))
		area = caixa if i == 0 else area.merge(caixa)
	subterraneo = Subterraneo3D.new()
	subterraneo.montar(Sub.gerar_rede(dados, cfg, Rng.new(semente)), cfg, area.grow(10.0))
	add_child(subterraneo)


func _carregar(id: String) -> Node3D:
	if not carregados.has(id):
		var novo := Bairro3D.new()
		novo.montar(id, semente, {"chao": false, "subterraneo": false})
		add_child(novo)
		carregados[id] = novo
		if Catalogo.tem_bairro_abstrato(id):
			var gente := Populacao3D.new()
			gente.montar(id, novo.dados, novo.lotes, semente)
			novo.add_child(gente)
			gente.atualizar(minuto)
			populacoes[id] = gente
		var passantes := Transeuntes3D.new()
		passantes.montar(id, novo.dados, semente)
		novo.add_child(passantes)
		passantes.atualizar(Relogio.data_de(minuto)["hora"])
		transeuntes[id] = passantes
	return carregados[id]


## Cruzou a linha? Se o caçador está num bairro vizinho, ele vira o atual.
func verificar_fronteira() -> void:
	if zona != "rua":
		return
	var id_atual := str(bairro.dados["id"])
	var onde := Viz.bairro_em(Vector2(cacador.position.x, cacador.position.z), limites, id_atual)
	if not onde.is_empty() and onde != id_atual and carregados.has(onde):
		entrar_em(onde)


func _montar_chao(area: Rect2) -> void:
	var tamanho := Vector3(area.size.x, 1.0, area.size.y)
	var malha := BoxMesh.new()
	malha.size = tamanho
	var visual := MeshInstance3D.new()
	visual.mesh = malha
	visual.material_override = Materiais.objeto(Bairro3D.COR_TERRENO, tamanho.x / 8.0, Bairro3D.AFIM_DO_CHAO)
	var chao := StaticBody3D.new()
	chao.name = "ChaoDaCidade"
	chao.position = Vector3(area.get_center().x, -0.5, area.get_center().y)
	var forma := BoxShape3D.new()
	forma.size = tamanho
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	chao.add_child(colisao)
	chao.add_child(visual)
	add_child(chao)


func _montar_interface() -> void:
	var camada_filtro := CanvasLayer.new()
	camada_filtro.layer = 10
	add_child(camada_filtro)
	camada_filtro.add_child(Materiais.filtro_de_tela())
	var camada := CanvasLayer.new()
	camada.layer = 11
	add_child(camada)
	var ajuda := Label.new()
	ajuda.text = "WASD andar · Shift liga/desliga corrida · F lanterna · E bueiro · I mochila\nBotão direito mirar, esquerdo atirar · R recarregar · 1-3 arma\nQ bolsos · T ritual · N conversar · E carro e motel · H habilidades · Esc pausa"
	ajuda.position = Vector2(8, 6)
	ajuda.add_theme_font_size_override("font_size", 11)
	ajuda.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	ajuda.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	ajuda.add_theme_constant_override("outline_size", 3)
	camada.add_child(ajuda)
	var credito := Label.new()
	credito.text = "© colaboradores do OpenStreetMap"
	credito.position = Vector2(8, 460)
	credito.add_theme_font_size_override("font_size", 9)
	credito.modulate = Color(0.2, 0.2, 0.2, 0.8)
	camada.add_child(credito)
	aviso = Label.new()
	aviso.position = Vector2(0, 300)
	aviso.size = Vector2(640, 20)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.add_theme_font_size_override("font_size", 13)
	camada.add_child(aviso)
	painel = Label.new()
	painel.position = Vector2(498, 164)
	painel.size = Vector2(134, 58)
	painel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	painel.add_theme_font_size_override("font_size", 10)
	camada.add_child(painel)
	relogio = Label.new()
	relogio.position = Vector2(498, 150)
	relogio.size = Vector2(134, 16)
	relogio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relogio.add_theme_font_size_override("font_size", 11)
	relogio.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	relogio.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.06))
	relogio.add_theme_constant_override("outline_size", 3)
	camada.add_child(relogio)
	nome_do_lugar = Label.new()
	nome_do_lugar.position = Vector2(0, 120)
	nome_do_lugar.size = Vector2(640, 40)
	nome_do_lugar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome_do_lugar.add_theme_font_size_override("font_size", 26)
	nome_do_lugar.add_theme_color_override("font_color", Color(0.98, 0.95, 0.85))
	nome_do_lugar.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.05))
	nome_do_lugar.add_theme_constant_override("outline_size", 4)
	camada.add_child(nome_do_lugar)
	minimapa = Minimapa.new()
	minimapa.cena = self
	camada.add_child(minimapa)
	hud = Label.new()
	hud.position = Vector2(8, 366)
	hud.size = Vector2(300, 90)
	hud.add_theme_font_size_override("font_size", 12)
	hud.add_theme_color_override("font_color", Color(0.98, 0.95, 0.85))
	hud.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.05))
	hud.add_theme_constant_override("outline_size", 3)
	camada.add_child(hud)
	menu = MenuRadial.new()
	menu.bolsos = bolsos
	menu.position = Vector2(170, 90)
	menu.size = Vector2(300, 300)
	menu.visible = false
	camada.add_child(menu)
	ritual_tela = RitualTela.new()
	ritual_tela.cena = self
	ritual_tela.position = Vector2(120, 300)
	ritual_tela.size = Vector2(400, 110)
	ritual_tela.visible = false
	camada.add_child(ritual_tela)
	conversa_tela = ConversaTela.new()
	conversa_tela.cena = self
	conversa_tela.position = Vector2(70, 270)
	conversa_tela.size = Vector2(500, 150)
	conversa_tela.visible = false
	camada.add_child(conversa_tela)
	mochila_tela = MochilaTela.new()
	mochila_tela.cena = self
	mochila_tela.position = Vector2(10, 62)
	mochila_tela.size = Vector2(620, 330)
	mochila_tela.visible = false
	camada.add_child(mochila_tela)
	motel_tela = MotelTela.new()
	motel_tela.cena = self
	motel_tela.position = Vector2(90, 90)
	motel_tela.size = Vector2(460, 230)
	motel_tela.visible = false
	camada.add_child(motel_tela)
	viagem_tela = ViagemTela.new()
	viagem_tela.cena = self
	viagem_tela.position = Vector2(10, 44)
	viagem_tela.size = Vector2(620, 400)
	viagem_tela.visible = false
	camada.add_child(viagem_tela)
	habilidades_tela = HabilidadesTela.new()
	habilidades_tela.cena = self
	habilidades_tela.position = Vector2(40, 60)
	habilidades_tela.size = Vector2(560, 300)
	habilidades_tela.visible = false
	camada.add_child(habilidades_tela)
	var camada_pausa := CanvasLayer.new()
	camada_pausa.layer = 20
	camada_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camada_pausa)
	pausa_tela = PausaTela.new()
	pausa_tela.cena = self
	pausa_tela.size = Vector2(640, 480)
	pausa_tela.visible = false
	camada_pausa.add_child(pausa_tela)
	PausaTela.aplicar_todas(self)


## Desce pelo bueiro i (ou sobe, se já estiver lá embaixo). Muda a luz da zona.
func usar_bueiro(i: int) -> void:
	var p: Vector3 = subterraneo.bueiros[i]
	var env: Environment = ambiente.environment
	if zona == "rua":
		if mare.galerias_alagadas(minuto):
			_avisar("Maré alta: a galeria está alagada.")
			return
		zona = "esgoto"
		cacador.position = p + Vector3(0.8, -subterraneo.profundidade + 0.1, 0)
		sol.visible = false
		env.background_color = Color.BLACK
		env.ambient_light_energy = 0.1
		env.fog_light_color = Color(0.01, 0.01, 0.01)
		env.fog_density = 0.1
	else:
		zona = "rua"
		cacador.position = p + Vector3(1.2, 0.3, 0)
		# Roupa e cheiro de esgoto: quem vê desconfia.
		suspeita.sujar(minuto)
		sol.visible = true
		env.background_color = COR_DA_NEVOA
		env.ambient_light_energy = 0.55
		env.fog_light_color = COR_DA_NEVOA
		env.fog_density = 0.035
	aplicar_luz()
	cacador.velocity = Vector3.ZERO
	minimapa.queue_redraw()


## Bueiro na mira, ou -1. Na rua, o bueiro no chão; embaixo, a escada logo abaixo dele.
func bueiro_na_mira(olho: Vector3, frente: Vector3) -> int:
	var pontos: Array = []
	for p in subterraneo.bueiros:
		pontos.append(p if zona == "rua" else p + Vector3(0, -subterraneo.profundidade + 1.2, 0))
	return Mira.escolher_alvo(olho, frente, cacador.position + Vector3(0, 0.9, 0), pontos, ALCANCE_DO_BUEIRO, ANGULO_DO_BUEIRO)


func _vista_de_cima() -> void:
	var caixa: Array = bairro.dados["caixa"]
	var vista := Camera3D.new()
	vista.projection = Camera3D.PROJECTION_ORTHOGONAL
	vista.size = maxf(float(caixa[2]) - float(caixa[0]), float(caixa[3]) - float(caixa[1])) * 1.6
	vista.far = 2000.0
	add_child(vista)
	vista.global_position = Vector3((float(caixa[0]) + float(caixa[2])) / 2.0, 400.0, (float(caixa[1]) + float(caixa[3])) / 2.0)
	vista.rotation_degrees = Vector3(-90, 0, 0)
	vista.current = true
	ambiente.environment.fog_enabled = false


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("examinar") and dirigindo:
		sair_do_carro()
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("examinar") and entrar_no_carro():
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("examinar") and _alvo < 0 and abrir_benzedeira():
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("examinar") and _alvo < 0 and abrir_motel():
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("examinar") and _alvo >= 0:
		usar_bueiro(_alvo)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("atirar") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not menu.visible:
		atirar()
	elif evento.is_action_pressed("recarregar"):
		recarregar_da_mochila()
	elif evento.is_action_pressed("arma_1") or evento.is_action_pressed("arma_2") or evento.is_action_pressed("arma_3"):
		for i in 3:
			if evento.is_action_pressed("arma_%d" % (i + 1)) and i < arsenal.ordem.size():
				equipar(arsenal.ordem[i])


## O menu radial pega o mouse antes da câmera enquanto está aberto. O ritual pega as
## teclas enquanto a tela dele está aberta.
func _input(evento: InputEvent) -> void:
	if menu == null:
		return
	if pausa_tela.visible:
		if evento.is_action_pressed("soltar_mouse"):
			fechar_pausa()
			get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed("soltar_mouse") and not (mochila_tela.visible or ritual_tela.visible or conversa_tela.visible or motel_tela.visible or habilidades_tela.visible or viagem_tela.visible or menu.visible):
		abrir_pausa()
		get_viewport().set_input_as_handled()
		return
	if ritual_tela.visible:
		_input_do_ritual(evento)
		return
	if conversa_tela.visible:
		_input_da_conversa(evento)
		return
	if mochila_tela.visible:
		_input_da_mochila(evento)
		return
	if motel_tela.visible:
		if evento.is_action_pressed("soltar_mouse"):
			if menu_do_motel == "principal":
				fechar_motel()
			else:
				menu_do_motel = "principal"
			get_viewport().set_input_as_handled()
		elif evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode >= KEY_1 and evento.physical_keycode <= KEY_9:
			escolher_no_motel(evento.physical_keycode - KEY_1)
			get_viewport().set_input_as_handled()
		return
	if habilidades_tela.visible:
		if evento.is_action_pressed("habilidades") or evento.is_action_pressed("soltar_mouse"):
			habilidades_tela.visible = false
			get_viewport().set_input_as_handled()
		elif evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode >= KEY_1 and evento.physical_keycode <= KEY_9:
			aprender_habilidade(evento.physical_keycode - KEY_1)
			get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed("habilidades"):
		habilidades_tela.visible = true
		get_viewport().set_input_as_handled()
		return
	if viagem_tela.visible:
		if evento.is_action_pressed("mapa") or evento.is_action_pressed("soltar_mouse"):
			fechar_mapa_de_viagem()
			get_viewport().set_input_as_handled()
		elif evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_Z:
			viagem_tela.perto = not viagem_tela.perto
			get_viewport().set_input_as_handled()
		elif evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode >= KEY_0 and evento.physical_keycode <= KEY_9:
			viajar(9 if evento.physical_keycode == KEY_0 else evento.physical_keycode - KEY_1)
			get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed("mapa"):
		abrir_mapa_de_viagem()
		get_viewport().set_input_as_handled()
		return
	if dirigindo:
		return
	if evento.is_action_pressed("mochila") and _abrindo_mochila <= 0.0:
		abrir_mochila()
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed("conversar"):
		conversar()
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed("ritual"):
		abrir_rituais()
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed("menu_radial"):
		menu.abrir()
		get_viewport().set_input_as_handled()
	elif evento.is_action_released("menu_radial") and menu.visible:
		menu.visible = false
		if menu.escolhida >= 0:
			usar_bolso(menu.escolhida)
		get_viewport().set_input_as_handled()
	elif menu.visible and evento is InputEventMouseMotion:
		menu.mover(evento.relative)
		get_viewport().set_input_as_handled()


func _input_do_ritual(evento: InputEvent) -> void:
	var numero := -1
	for i in 3:
		if evento.is_action_pressed("arma_%d" % (i + 1)):
			numero = i
	if evento.is_action_pressed("soltar_mouse") or (ritual == null and evento.is_action_pressed("ritual")):
		fechar_ritual()
	elif ritual == null and numero >= 0:
		comecar_ritual(numero)
	elif ritual != null and numero >= 0:
		escolher_palavra(numero)
	elif ritual != null and evento.is_action_pressed("acao_do_ritual"):
		apertar_no_ritual()
	elif ritual != null and evento.is_action_released("acao_do_ritual"):
		soltar_no_ritual()
	else:
		return
	get_viewport().set_input_as_handled()


func _input_da_conversa(evento: InputEvent) -> void:
	if evento.is_action_pressed("soltar_mouse") or evento.is_action_pressed("conversar"):
		fechar_conversa()
	elif evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode in TECLAS_DE_OPCAO:
		oferecer(TECLAS_DE_OPCAO.find(evento.physical_keycode))
	else:
		return
	get_viewport().set_input_as_handled()


func _input_da_mochila(evento: InputEvent) -> void:
	if evento.is_action_pressed("mochila") or evento.is_action_pressed("soltar_mouse"):
		fechar_mochila()
	elif evento.is_action_pressed("mover_frente", true):
		mover_cursor(Vector2i(0, -1))
	elif evento.is_action_pressed("mover_tras", true):
		mover_cursor(Vector2i(0, 1))
	elif evento.is_action_pressed("mover_esquerda", true):
		mover_cursor(Vector2i(-1, 0))
	elif evento.is_action_pressed("mover_direita", true):
		mover_cursor(Vector2i(1, 0))
	elif evento.is_action_pressed("acao_do_ritual"):
		pegar_ou_soltar()
	elif evento.is_action_pressed("recarregar"):
		girar_na_mao()
	elif evento.is_action_pressed("caderno"):
		trocar_grade()
	elif evento is InputEventKey and evento.pressed and evento.physical_keycode == KEY_B:
		por_no_bolso()
	elif evento is InputEventKey and evento.pressed and evento.physical_keycode == KEY_O:
		organizar()
	elif evento is InputEventKey and evento.pressed and evento.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
		pegar_ou_soltar()
	else:
		return
	get_viewport().set_input_as_handled()


## I: abrir a mochila leva tempo; o caçador fica parado (perigoso no confronto).
func abrir_mochila() -> void:
	_abrindo_mochila = float(_cfg_inventario["abrir_mochila_segundos"])
	cacador.bloqueado = true
	_avisar("Abrindo a mochila...")
	if _abrindo_mochila <= 0.0:
		_mochila_aberta()


func _mochila_aberta() -> void:
	_abrindo_mochila = 0.0
	foco = "mochila"
	_mouse_antes = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_tempo_do_nome = 0.0
	nome_do_lugar.text = ""
	cursor = Vector2i.ZERO
	mochila_tela.visible = true


func fechar_mochila() -> void:
	if not na_mao.is_empty():
		grade_aberta().adicionar(na_mao["item"], int(na_mao["quantidade"]))
		na_mao = {}
	var estava_aberta: bool = mochila_tela.visible
	mochila_tela.visible = false
	_abrindo_mochila = 0.0
	if estava_aberta:
		Input.mouse_mode = _mouse_antes
	_conferir_arma_equipada()
	if not ferimentos.morto:
		cacador.bloqueado = false


func grade_aberta() -> RefCounted:
	return outra_grade() if foco == "outra" and outra_grade() != null else mochila


## A grade que fica do lado da mochila: o porta-malas perto do carro, ou a guarda perto do motel.
func outra_grade() -> RefCounted:
	if perto_do_carro():
		return porta_malas
	if perto_do_motel():
		return guarda_do_motel
	return null


func nome_da_outra() -> String:
	return "PORTA-MALAS" if perto_do_carro() else "MOTEL"


func perto_do_carro() -> bool:
	return carro != null and zona == "rua" and Vector2(carro.position.x, carro.position.z).distance_to(Vector2(cacador.position.x, cacador.position.z)) <= float(_cfg_inventario["alcance_do_porta_malas"])


func trocar_grade() -> void:
	if outra_grade() != null:
		foco = "mochila" if foco == "outra" else "outra"
		cursor = Vector2i(0, mini(cursor.y, grade_aberta().altura - 1))


## Setas: anda casa a casa; perto do carro, passa da borda da mochila para o porta-malas
## (que fica à direita) e volta.
func mover_cursor(d: Vector2i) -> void:
	var g: RefCounted = grade_aberta()
	var x := cursor.x + d.x
	if outra_grade() != null and foco == "mochila" and x >= g.largura:
		foco = "outra"
		cursor = Vector2i(0, mini(cursor.y, outra_grade().altura - 1))
		return
	if outra_grade() != null and foco == "outra" and x < 0:
		foco = "mochila"
		cursor = Vector2i(mochila.largura - 1, mini(cursor.y, mochila.altura - 1))
		return
	cursor = Vector2i(clampi(x, 0, g.largura - 1), clampi(cursor.y + d.y, 0, g.altura - 1))


## O mouse aponta uma casa de uma das grades.
func apontar(qual: String, casa: Vector2i) -> void:
	if qual == "outra" and outra_grade() == null:
		return
	foco = qual
	cursor = casa


## O: organiza a grade em foco.
func organizar() -> void:
	if not na_mao.is_empty():
		return
	if not grade_aberta().organizar():
		_avisar("Não deu para organizar.")


## Arma só é usada se estiver na mochila (como na maleta). A faca fica no cinto.
func arma_na_mochila(id: String) -> bool:
	return int(arsenal.arma_de(id)["capacidade"]) == 0 or mochila.quantidade(id) > 0


func equipar(id: String) -> bool:
	if not arma_na_mochila(id):
		_avisar("%s não está na mochila." % arsenal.arma_de(id)["nome"])
		return false
	return arsenal.equipar(id)


## Se a arma na mão saiu da mochila, fica a faca.
func _conferir_arma_equipada() -> void:
	if not arma_na_mochila(arsenal.equipada):
		for id in arsenal.ordem:
			if int(arsenal.arma_de(id)["capacidade"]) == 0:
				arsenal.equipar(id)


## Espaço: pega o item do cursor, ou solta o da mão ali (pode ser na outra grade).
func pegar_ou_soltar() -> void:
	var g: RefCounted = grade_aberta()
	if na_mao.is_empty():
		var e: Dictionary = g.em(cursor.x, cursor.y)
		if not e.is_empty():
			na_mao = g.tirar_entrada(e["n"])
		return
	var girado: bool = int(na_mao["w"]) != int(itens[na_mao["item"]]["formato"][0])
	if g.colocar(na_mao["item"], cursor.x, cursor.y, girado, int(na_mao["quantidade"])) > 0:
		na_mao = {}
	else:
		# Mesmo item embaixo: empilha o que couber.
		var e: Dictionary = g.em(cursor.x, cursor.y)
		if not e.is_empty() and e["item"] == na_mao["item"]:
			var cabe: int = mini(int(itens[e["item"]]["pilha"]) - int(e["quantidade"]), int(na_mao["quantidade"]))
			e["quantidade"] = int(e["quantidade"]) + cabe
			na_mao["quantidade"] = int(na_mao["quantidade"]) - cabe
			if int(na_mao["quantidade"]) <= 0:
				na_mao = {}


func girar_na_mao() -> void:
	if not na_mao.is_empty():
		var w: int = na_mao["w"]
		na_mao["w"] = na_mao["h"]
		na_mao["h"] = w


## B: passa uma unidade do item do cursor para o bolso do mesmo item (menu radial).
func por_no_bolso() -> bool:
	var e: Dictionary = grade_aberta().em(cursor.x, cursor.y)
	if e.is_empty():
		return false
	for b in bolsos.itens:
		if b["item"] == e["item"]:
			grade_aberta().retirar(e["item"], 1)
			b["quantidade"] = int(b["quantidade"]) + 1
			_avisar("%s no bolso (%d)." % [b["nome"], int(b["quantidade"])])
			return true
	_avisar("Não tem bolso para isso.")
	return false


## R fora da mochila: recarrega com a munição da mochila.
func recarregar_da_mochila() -> bool:
	var item: String = _cfg_inventario["municao_das_armas"].get(arsenal.equipada, "")
	if item.is_empty():
		return false
	var tem: int = mochila.quantidade(item)
	if tem <= 0:
		_avisar("Sem %s na mochila." % str(itens[item]["nome"]).to_lower())
		return false
	var vai: int = mini(tem, arsenal.faltam())
	if not arsenal.recarregar(vai):
		return false
	mochila.retirar(item, vai)
	_avisar("Recarregando...")
	praticar("recarga")
	return true


## O carro parado do caçador (o porta-malas abre perto dele).
func _estacionar_carro() -> void:
	carro = Carro3D.new()
	carro.montar(_cfg_progressao["carro"])
	add_child(carro)
	var lado := Vector3(cos(cacador.yaw), 0.0, -sin(cacador.yaw))
	carro.position = Vector3(cacador.position.x, 0.05, cacador.position.z) + lado * 2.6
	carro.rotation.y = cacador.yaw


## Qualidade das armas e da mochila (progresso) aplicada no arsenal e na grade.
func _aplicar_qualidade() -> void:
	for id in arsenal.ordem:
		arsenal.qualidade[id] = progresso.multiplicadores_da_arma(id)
	var tamanho: Vector2i = progresso.tamanho_da_mochila()
	if tamanho != Vector2i(mochila.largura, mochila.altura):
		var nova := Grade.new(tamanho.x, tamanho.y, itens)
		for e in mochila.entradas:
			var girado: bool = int(e["w"]) != int(itens[e["item"]]["formato"][0])
			if nova.colocar(e["item"], e["x"], e["y"], girado, int(e["quantidade"])) == 0:
				nova.adicionar(e["item"], int(e["quantidade"]))
		mochila = nova


## E: entra ou sai do carro.
func entrar_no_carro() -> bool:
	if dirigindo or carro == null or zona != "rua":
		return false
	if Vector2(carro.position.x, carro.position.z).distance_to(Vector2(cacador.position.x, cacador.position.z)) > float(_cfg_progressao["carro"]["alcance_da_porta"]) + 1.0:
		return false
	dirigindo = true
	cacador.visible = false
	cacador.process_mode = Node.PROCESS_MODE_DISABLED
	# Dentro do carro o corpo do caçador não bate em nada (nem no próprio carro).
	_camadas_do_cacador = Vector2i(cacador.collision_layer, cacador.collision_mask)
	cacador.collision_layer = 0
	cacador.collision_mask = 0
	carro.camera.current = true
	return true


func sair_do_carro() -> void:
	if not dirigindo:
		return
	dirigindo = false
	carro.velocidade = 0.0
	cacador.position = carro.lado_da_porta()
	cacador.velocity = Vector3.ZERO
	cacador.process_mode = Node.PROCESS_MODE_INHERIT
	cacador.collision_layer = _camadas_do_cacador.x
	cacador.collision_mask = _camadas_do_cacador.y
	cacador.visible = true
	cacador.camera.current = true


## Um passo dirigindo; o caçador vai junto (fronteira, minimapa e mundo seguem o carro).
func dirigir(entrada: Vector2, delta: float) -> void:
	carro.dirigir(entrada, delta)
	cacador.position = carro.position + Vector3(0, 0.3, 0)


## Arte e áudio: os sons (sintetizados em baixa taxa), o reverb, as luzes dos postes e o farol.
func _montar_arte_e_audio() -> void:
	_cfg_arte = Catalogo.carregar_config_arte_e_audio()["dados"]
	var a: Dictionary = _cfg_arte["audio"]
	Sons.taxa = int(a["taxa"])
	som_ambiente = _tocador("SomAmbiente", float(a["volume_ambiente"]))
	som_passos = _tocador("SomPassos", float(a["volume_passos"]))
	som_passos.stream = Sons.passo()
	som_tiros = _tocador("SomTiros", float(a["volume_tiros"]))
	som_sussurro = _tocador("SomSussurro", float(a["volume_sussurro"]))
	som_sussurro.stream = Sons.sussurro()
	som_motor = _tocador("SomMotor", float(a["volume_motor"]))
	som_motor.stream = Sons.motor()
	# Reverb pesado, no estilo da época (só uma vez no barramento principal).
	var tem_reverb := false
	for i in AudioServer.get_bus_effect_count(0):
		tem_reverb = tem_reverb or AudioServer.get_bus_effect(0, i) is AudioEffectReverb
	if not tem_reverb:
		var reverb := AudioEffectReverb.new()
		reverb.room_size = 0.7
		reverb.wet = 0.18
		AudioServer.add_bus_effect(0, reverb)
	var p: Dictionary = _cfg_arte["postes"]
	for i in int(p["acesos_perto"]):
		var luz := OmniLight3D.new()
		luz.name = "LuzDoPoste%d" % i
		luz.omni_range = float(p["alcance"])
		luz.light_energy = float(p["energia"])
		luz.light_color = Color(str(p["cor"]))
		luz.visible = false
		add_child(luz)
		luzes_dos_postes.append(luz)
	if carro != null:
		farol = SpotLight3D.new()
		farol.name = "Farol"
		farol.spot_range = float(_cfg_arte["carro"]["farois_alcance"])
		farol.spot_angle = 32.0
		farol.light_energy = float(_cfg_arte["carro"]["farois_energia"])
		farol.position = Vector3(0, 0.8, -2.2)
		farol.rotation_degrees.x = -8.0
		farol.visible = false
		carro.add_child(farol)
	aplicar_luz()


## Toca o som, se a cena estiver na árvore (nos testes ela fica fora; o som só não toca).
func _tocar(tocador: AudioStreamPlayer) -> void:
	if tocador.is_inside_tree():
		tocador.play()


func _tocador(nome: String, volume_db: float) -> AudioStreamPlayer:
	var t := AudioStreamPlayer.new()
	t.name = nome
	t.volume_db = volume_db
	t.autoplay = nome == "SomAmbiente"
	add_child(t)
	return t


## A luz da hora (config "ciclo"): sol, céu, névoa e ambiente interpolados; à noite, as
## janelas acendem, os postes perto do caçador e o farol do carro ligam. No esgoto, nada muda.
func aplicar_luz() -> void:
	if _cfg_arte.is_empty() or zona != "rua":
		return
	var env: Environment = ambiente.environment
	if not bool(_cfg_arte["ciclo_de_luz"]):
		_definir_noite(0.0)
		return
	var c := luz_da_hora(float(minuto % 1440) / 60.0, _cfg_arte["ciclo"])
	# De noite, o "sol" vira um luar fraco e azulado.
	sol.visible = true
	sol.light_energy = maxf(c["sol"], 0.18)
	sol.light_color = Color(1.0, 0.97, 0.9).lerp(Color(0.55, 0.65, 1.0), clampf(1.0 - c["sol"] / 0.45, 0.0, 1.0))
	var elevacao := clampf(sin(PI * (float(minuto % 1440) / 60.0 - 6.0) / 12.0), 0.05, 1.0)
	sol.rotation_degrees = Vector3(-5.0 - 75.0 * elevacao, 35.0, 0.0)
	env.ambient_light_color = c["cor_ambiente"]
	env.ambient_light_energy = c["ambiente"]
	env.fog_light_color = c["nevoa"]
	env.background_color = c["nevoa"]
	env.fog_density = c["densidade"]
	_definir_noite(clampf(1.0 - c["sol"] / 0.45, 0.0, 1.0))


## Interpola o ciclo de luz numa hora fracionária (0 a 24), dando a volta à meia-noite.
static func luz_da_hora(hora: float, ciclo: Array) -> Dictionary:
	var antes: Dictionary = ciclo[-1]
	var depois: Dictionary = ciclo[0]
	for i in ciclo.size():
		if float(ciclo[i]["hora"]) <= hora:
			antes = ciclo[i]
			depois = ciclo[(i + 1) % ciclo.size()]
	var h0 := float(antes["hora"])
	var h1 := float(depois["hora"])
	if h1 <= h0:
		h1 += 24.0
	var h := hora if hora >= h0 else hora + 24.0
	var t := clampf((h - h0) / maxf(h1 - h0, 0.001), 0.0, 1.0)
	return {
		"sol": lerpf(float(antes["sol"]), float(depois["sol"]), t),
		"ambiente": lerpf(float(antes["ambiente"]), float(depois["ambiente"]), t),
		"cor_ambiente": Color(str(antes["cor_ambiente"])).lerp(Color(str(depois["cor_ambiente"])), t),
		"nevoa": Color(str(antes["nevoa"])).lerp(Color(str(depois["nevoa"])), t),
		"densidade": lerpf(float(antes["densidade"]), float(depois["densidade"]), t),
	}


func _definir_noite(valor: float) -> void:
	var mudou := (valor > 0.5) != (noite > 0.5) or som_ambiente.stream == null
	noite = valor
	Materiais.definir_noite(valor)
	if farol != null:
		farol.visible = valor > 0.5
	acender_postes()
	if mudou:
		som_ambiente.stream = Sons.ambiente_noite() if valor > 0.5 else Sons.ambiente_dia()
		_tocar(som_ambiente)


## À noite, as luzes dos postes vão para os postes mais perto do caçador.
func acender_postes() -> void:
	var acesos := noite > 0.5 and zona == "rua"
	var candidatos: Array = []
	if acesos:
		var aqui := cacador.position
		for id in carregados:
			for p in carregados[id].postes:
				candidatos.append([p.distance_squared_to(aqui), p])
		candidatos.sort_custom(func(x, y): return x[0] < y[0])
	var altura := float(_cfg_arte["postes"]["altura"])
	for i in luzes_dos_postes.size():
		var luz: OmniLight3D = luzes_dos_postes[i]
		luz.visible = acesos and i < candidatos.size()
		if luz.visible:
			luz.position = candidatos[i][1] + Vector3(0, altura - 0.3, 0)


## Passos no ritmo do andar (pela distância) e o motor no tom da velocidade do carro.
func _passos_e_motor(_segundos: float) -> void:
	if dirigindo:
		if not som_motor.playing and som_motor.is_inside_tree():
			_tocar(som_motor)
		som_motor.pitch_scale = 0.6 + absf(carro.velocidade) / float(_cfg_progressao["carro"]["velocidade_maxima"]) * 1.4
		_ultima_posicao = Vector3.INF
		return
	if som_motor.playing:
		som_motor.stop()
	var agora := cacador.position
	if _ultima_posicao != Vector3.INF:
		_andado += Vector2(agora.x - _ultima_posicao.x, agora.z - _ultima_posicao.z).length()
		var passo := 1.0 / maxf(float(_cfg_arte["audio"]["passos_por_metro"]), 0.01)
		if _andado >= passo:
			_andado = fmod(_andado, passo)
			passos_tocados += 1
			som_passos.pitch_scale = 0.92 if passos_tocados % 2 == 0 else 1.06
			_tocar(som_passos)
	_ultima_posicao = agora


## Esc: pausa o jogo e mostra o menu (o mouse fica livre para clicar).
func abrir_pausa() -> void:
	pausa_tela.mostrar("principal")
	pausa_tela.visible = true
	_mouse_antes = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true


func fechar_pausa() -> void:
	pausa_tela.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _mouse_antes == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_VISIBLE


## Volta para a tela inicial (o jogo não tem save ainda: o que não foi guardado se perde).
func ir_para_o_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://ui/inicio.tscn")


## O Sensitivo: espíritos errantes vêm incomodar (exaustão e medo), a presença da criatura é
## sentida (só a força e a direção) e, no máximo da exaustão, algo toma o corpo.
func _sensitivo(segundos: float, protegido: bool, distancia_da_criatura: float) -> void:
	if not condicao.sensitivo():
		if espiritos != null:
			espiritos.visible = false
		return
	var c: Dictionary = _cfg_condicoes["sensitivo"]
	if espiritos == null:
		espiritos = Espiritos3D.new()
		espiritos.montar(c["espiritos_errantes"], Rng.new(semente).stream("espiritos"))
		add_child(espiritos)
	espiritos.visible = true
	espiritos.ajustar(int(condicao.estagio()["espiritos"]), cacador.position)
	var perto: int = espiritos.andar(segundos, cacador.position, circulos)
	var figa: bool = bolsos.quantidade(str(c["protecao_corta_pela_metade"])) > 0
	if perto > 0:
		medo.valor = minf(medo.valor + float(c["espiritos_errantes"]["medo_por_segundo_perto"]) * perto * segundos, 100.0)
		_proximo_sussurro -= segundos
		if _proximo_sussurro <= 0.0:
			var sussurros: Array = c["sussurros"]
			_avisar(sussurros[_g_sussurro.randi_range(0, sussurros.size() - 1)])
			_tocar(som_sussurro)
			_proximo_sussurro = 12.0
	# Sentir a criatura conta como uso do poder (uma vez por criatura).
	if criatura != null and criatura.visible and condicao.sente(criatura.ficha, distancia_da_criatura) and not _sentidas.has(criatura.get_instance_id()):
		_sentidas[criatura.get_instance_id()] = true
		if condicao.usar_poder(0.0, figa):
			_avisar("O dom ficou mais forte: %s." % condicao.nome())
	var antes: bool = condicao.possuido()
	if condicao.passar(segundos, perto, figa or protegido):
		cacador.bloqueado = true
		_avisar("Algo toma o seu corpo. Você não consegue se mexer.")
	elif antes and not condicao.possuido() and not ferimentos.morto and not _alguma_tela_aberta():
		cacador.bloqueado = false
		_avisar("Você volta a si.")


func _alguma_tela_aberta() -> bool:
	return mochila_tela.visible or ritual_tela.visible or conversa_tela.visible or motel_tela.visible or dirigindo


## O que o sensitivo sente da criatura: "forte, à frente" (nunca diz o que é). "" se nada.
func texto_da_presenca() -> String:
	if criatura == null or not criatura.visible:
		return ""
	var d := Vector2(criatura.position.x - cacador.position.x, criatura.position.z - cacador.position.z)
	if not condicao.sente(criatura.ficha, d.length()):
		return ""
	var forca := "forte" if d.length() < float(condicao.estagio()["alcance_da_presenca"]) / 2.0 else "fraca"
	var frente := Vector2(-sin(cacador.yaw), -cos(cacador.yaw))
	var angulo := rad_to_deg(frente.angle_to(d.normalized()))
	var lado := "à frente" if absf(angulo) < 45.0 else ("atrás" if absf(angulo) > 135.0 else ("à direita" if angulo > 0.0 else "à esquerda"))
	return "Presença %s, %s" % [forca, lado]


## Pratica uma ação (dá experiência na árvore dela) e avisa se ganhou ponto.
func praticar(acao: String) -> void:
	if habilidades.praticar(acao):
		_avisar("Novo ponto de habilidade (H).")


## Aprende a i-ésima habilidade da lista (na ordem das árvores) e aplica os efeitos.
func aprender_habilidade(i: int) -> Dictionary:
	var lista: Array = []
	for a in habilidades.arvores():
		for h in a["habilidades"]:
			lista.append(h["id"])
	if i < 0 or i >= lista.size():
		return {"ok": false, "motivo": "não existe"}
	var r: Dictionary = habilidades.aprender(lista[i])
	if r["ok"]:
		_aplicar_habilidades()
	else:
		_avisar("Não dá: %s." % r["motivo"])
	return r


## Efeitos das habilidades nos sistemas que não perguntam a cada uso.
func _aplicar_habilidades() -> void:
	arsenal.habilidade = {"dispersao": habilidades.efeito("dispersao"), "recarga": habilidades.efeito("recarga")}
	ferimentos.tempo_do_critico = habilidades.efeito("tempo_do_critico")


## M: o mapa de viagem rápida só abre dentro do carro.
func abrir_mapa_de_viagem() -> bool:
	if not dirigindo:
		_avisar("O mapa de viagem abre dentro do carro.")
		return false
	viagem_tela.visible = true
	_mouse_antes = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return true


func fechar_mapa_de_viagem() -> void:
	if viagem_tela.visible:
		viagem_tela.visible = false
		Input.mouse_mode = _mouse_antes


## Pontos de viagem rápida: a entrada de cada bairro carregado e os pontos-chave deles, cada
## um na rua mais perto. [{"nome", "bairro", "ponto": Vector2, "metros", "minutos", "litros"}]
func destinos_de_viagem() -> Array:
	var lista: Array = []
	var ids := carregados.keys()
	ids.sort()
	ids = ids.filter(func(i): return progresso.liberada(i))
	for id in ids:
		var c: Vector3 = carregados[id].chegada()
		lista.append({"nome": str(carregados[id].dados["nome"]), "bairro": id, "ponto": Vector2(c.x, c.z)})
	for id in ids:
		if not populacoes.has(id):
			continue
		for ponto in populacoes[id].pontos_chave:
			lista.append({"nome": "%s (%s)" % [ponto["nome"], carregados[id].dados["nome"]], "bairro": id, "ponto": populacoes[id].ponto_na_rua(ponto["porta"])})
	var cfg: Dictionary = _cfg_progressao["carro"]
	var v: Dictionary = cfg["viagem_rapida"]
	var aqui := Vector2(carro.position.x, carro.position.z) if carro != null else Vector2(cacador.position.x, cacador.position.z)
	for d in lista:
		var metros: float = aqui.distance_to(d["ponto"]) * float(v["desvio_das_ruas"])
		d["metros"] = metros
		d["minutos"] = maxi(1, int(ceil(metros / (float(v["velocidade_media_kmh"]) * 1000.0 / 60.0))))
		d["litros"] = metros / (float(cfg["km_por_litro"]) * 1000.0)
	return lista


## Viagem rápida até o destino i: o carro aparece lá, o relógio anda e a gasolina gasta.
func viajar(i: int) -> bool:
	var destinos := destinos_de_viagem()
	if not dirigindo or i < 0 or i >= destinos.size():
		return false
	var d: Dictionary = destinos[i]
	if float(d["litros"]) > carro.litros:
		_avisar("Não tem gasolina para chegar lá.")
		return false
	carro.litros -= float(d["litros"])
	carro.velocidade = 0.0
	carro.position = Vector3(d["ponto"].x, 0.05, d["ponto"].y)
	cacador.position = carro.position + Vector3(0, 0.3, 0)
	var minutos: int = d["minutos"]
	minuto += minutos
	suspeita.passar_minutos(minutos)
	for b in populacoes:
		populacoes[b].atualizar(minuto)
	fechar_mapa_de_viagem()
	verificar_fronteira()
	_avisar("%s (%d min)" % [d["nome"], minutos])
	return true


## O motel do Centro (ponto-chave): a porta mais perto, ou Vector2.INF.
func porta_do_motel() -> Vector2:
	var melhor := Vector2.INF
	var aqui := Vector2(cacador.position.x, cacador.position.z)
	for b in populacoes:
		for ponto in populacoes[b].pontos_chave:
			if ponto["tipo"] == "motel" and (melhor == Vector2.INF or aqui.distance_to(ponto["porta"]) < aqui.distance_to(melhor)):
				melhor = ponto["porta"]
	return melhor


func perto_do_motel() -> bool:
	var porta := porta_do_motel()
	return zona == "rua" and porta != Vector2.INF and porta.distance_to(Vector2(cacador.position.x, cacador.position.z)) <= float(_cfg_progressao["motel"]["alcance"])


func abrir_motel() -> bool:
	if not perto_do_motel():
		return false
	menu_do_motel = "principal"
	motel_tela.visible = true
	cacador.bloqueado = true
	return true


func fechar_motel() -> void:
	motel_tela.visible = false
	if not ferimentos.morto:
		cacador.bloqueado = false


func titulo_do_motel() -> String:
	return {"principal": "MOTEL ESTRELA DO PORTO", "suprimentos": "ENCOMENDAS (entregues no motel)", "melhorias": "MELHORIAS", "interludio": "INTERLÚDIO · quanto tempo deixar passar?",
		"benzedeira": "BENZEDEIRA", "benzedeira_aviso": "BENZEDEIRA · PENSE BEM"}[menu_do_motel]


## A porta de uma benzedeira por perto, ou Vector2.INF.
func porta_da_benzedeira() -> Vector2:
	var aqui := Vector2(cacador.position.x, cacador.position.z)
	for b in populacoes:
		for ponto in populacoes[b].pontos_chave:
			if ponto["tipo"] == "benzedeira" and aqui.distance_to(ponto["porta"]) <= float(_cfg_progressao["motel"]["alcance"]):
				return ponto["porta"]
	return Vector2.INF


## E na porta de uma benzedeira: abrir os olhos (ficar Sensitivo) ou se benzer.
func abrir_benzedeira() -> bool:
	if zona != "rua" or porta_da_benzedeira() == Vector2.INF:
		return false
	menu_do_motel = "benzedeira"
	motel_tela.visible = true
	cacador.bloqueado = true
	return true


## As opções do menu atual: [{"texto", "acao", "dado"}].
func opcoes_do_motel() -> Array:
	var lista: Array = []
	match menu_do_motel:
		"principal":
			var cfg: Dictionary = _cfg_progressao["motel"]
			lista.append({"texto": "Descansar %d horas (R$ %d)" % [int(cfg["horas_de_sono"]), int(cfg["diaria"])], "acao": "descansar"})
			lista.append({"texto": "Guardar coisas (mochila e guarda do quarto)", "acao": "guardar"})
			lista.append({"texto": "Encomendar suprimentos", "acao": "suprimentos"})
			lista.append({"texto": "Melhorias de equipamento", "acao": "melhorias"})
			var litros: float = carro.faltam_litros() if carro != null else 0.0
			lista.append({"texto": "Abastecer o carro (%.0f L, R$ %d)" % [litros, _preco_da_gasolina()], "acao": "abastecer"})
			lista.append({"texto": "Interlúdio: deixar o tempo passar até o próximo caso", "acao": "interludio"})
		"interludio":
			for pulo in Interludio.pulos(_cfg_progressao):
				var e: Dictionary = Interludio.efeito(pulo, _cfg_progressao)
				for a in habilidades.arvores():
					lista.append({"texto": "%s (%d dias) · treinar %s · R$ %d" % [pulo["nome"], int(e["dias"]), a["nome"], int(e["custo"])],
						"acao": "pular", "dado": {"pulo": pulo, "arvore": a["id"]}})
		"suprimentos":
			for o in _cfg_progressao["loja"]:
				lista.append({"texto": "%s · R$ %d" % [o["nome"], int(o["preco"])], "acao": "comprar", "dado": o})
		"benzedeira":
			var b: Dictionary = _cfg_condicoes["sensitivo"]["benzedeira"]
			if not condicao.tem():
				lista.append({"texto": "Pedir para abrir os olhos (ficar Sensitivo)", "acao": "sensitivo_aviso"})
			lista.append({"texto": "Ser benzido: tira o cansaço espiritual (R$ %d)" % int(b["benzer_preco"]), "acao": "benzer"})
		"benzedeira_aviso":
			lista.append({"texto": "Sim. Quero ver o que os outros não veem.", "acao": "sensitivo"})
			lista.append({"texto": "Não. Deixa como está.", "acao": "voltar"})
		"melhorias":
			for m in _cfg_progressao["melhorias"]:
				var pode: Dictionary = progresso.pode_comprar(m)
				lista.append({"texto": "%s · R$ %d%s" % [m["nome"], int(m["preco"]), "" if pode["ok"] else " (%s)" % pode["motivo"]], "acao": "melhorar", "dado": m})
	return lista


func _preco_da_gasolina() -> int:
	if carro == null:
		return 0
	return int(ceil(carro.faltam_litros())) * int(_cfg_progressao["carro"]["preco_do_litro"])


## Escolhe a opção i do menu do motel.
func escolher_no_motel(i: int) -> void:
	var opcoes := opcoes_do_motel()
	if i < 0 or i >= opcoes.size():
		return
	var o: Dictionary = opcoes[i]
	match o["acao"]:
		"descansar":
			descansar()
		"guardar":
			fechar_motel()
			abrir_mochila()
			_mochila_aberta()
			foco = "outra"
		"suprimentos", "melhorias", "interludio":
			menu_do_motel = o["acao"]
		"pular":
			if pular_o_tempo(o["dado"]["pulo"]["id"], o["dado"]["arvore"]):
				fechar_motel()
		"comprar":
			var oferta: Dictionary = o["dado"]
			if progresso.gastar(int(oferta["preco"]), oferta["nome"]):
				var sobra: int = guarda_do_motel.adicionar(oferta["item"], int(oferta["quantidade"]))
				sobra = mochila.adicionar(oferta["item"], sobra) if sobra > 0 else 0
				_avisar("Entregue no motel: %s." % oferta["nome"] if sobra == 0 else "Não coube tudo: sobraram %d." % sobra)
			else:
				_avisar("Falta dinheiro.")
		"melhorar":
			var r: Dictionary = progresso.comprar_melhoria(o["dado"])
			if r["ok"]:
				_aplicar_qualidade()
				_avisar("Agora: %s (%s)." % [o["dado"]["nome"], progresso.nome_da_qualidade(o["dado"]["categoria"])])
			else:
				_avisar("Não dá: %s." % r["motivo"])
		"abastecer":
			abastecer()
		"sensitivo_aviso":
			menu_do_motel = "benzedeira_aviso"
			_avisar("Você vai ver e ouvir os mortos. E eles vão te ver também.")
		"voltar":
			menu_do_motel = "benzedeira"
		"sensitivo":
			var r: Dictionary = condicao.adquirir("sensitivo")
			_avisar("Seus olhos se abriram. Você é Sensitivo." if r["ok"] else "Não dá: %s." % r["motivo"])
			fechar_motel()
		"benzer":
			benzer()


## Interlúdio: o tempo pula (curto, médio ou longo). Sara ferimentos, zera medo e cansaço,
## treina a árvore escolhida, envelhece e paga as diárias. Devolve se pulou.
func pular_o_tempo(id_pulo: String, arvore: String) -> bool:
	var pulo: Dictionary = {}
	for p in Interludio.pulos(_cfg_progressao):
		if p["id"] == id_pulo:
			pulo = p
	if pulo.is_empty() or not habilidades.xp.has(arvore):
		return false
	var e: Dictionary = Interludio.efeito(pulo, _cfg_progressao)
	if not progresso.gastar(int(e["custo"]), "interlúdio %s" % pulo["nome"].to_lower()):
		_avisar("Falta dinheiro para tantas diárias.")
		return false
	minuto += int(e["minutos"])
	suspeita.passar_minutos(int(e["minutos"]))
	for b in populacoes:
		populacoes[b].atualizar(minuto)
	for parte in ferimentos.gravidade.keys():
		for k in int(e["cura_graus"]):
			ferimentos.tratar(parte)
	medo.valor = 0.0
	condicao.aliviar(INF)
	habilidades.xp[arvore] = int(habilidades.xp[arvore]) + int(e["treino_xp"])
	var antes: int = progresso.idade()
	progresso.dias_vividos += int(e["dias"])
	progresso.interludios += 1
	var envelheceu := " Você fez %d anos." % progresso.idade() if progresso.idade() > antes else ""
	_avisar("Passaram-se %d dias.%s" % [int(e["dias"]), envelheceu])
	return true


## Benzedura: tira o cansaço espiritual do sensitivo.
func benzer() -> bool:
	var b: Dictionary = _cfg_condicoes["sensitivo"]["benzedeira"]
	if not progresso.gastar(int(b["benzer_preco"]), "benzedura"):
		_avisar("Falta dinheiro.")
		return false
	condicao.aliviar(float(b["benzer_tira"]))
	_avisar("A benzedeira reza baixinho com um ramo de arruda. Você fica leve.")
	return true


## Dorme no motel: o tempo passa, os ferimentos melhoram um grau, o medo some; paga a diária.
func descansar() -> bool:
	var cfg: Dictionary = _cfg_progressao["motel"]
	if not progresso.gastar(int(cfg["diaria"]), "diária do motel"):
		_avisar("Sem dinheiro para a diária.")
		return false
	var minutos := int(cfg["horas_de_sono"]) * 60
	minuto += minutos
	suspeita.passar_minutos(minutos)
	for b in populacoes:
		populacoes[b].atualizar(minuto)
	for parte in ferimentos.gravidade.keys():
		ferimentos.tratar(parte)
	medo.valor = 0.0
	condicao.aliviar(float(_cfg_condicoes["sensitivo"]["exaustao_maxima"]))
	_avisar("Você dormiu %d horas." % int(cfg["horas_de_sono"]))
	return true


## Enche o tanque, se o carro estiver perto do motel (há um posto na esquina).
func abastecer() -> bool:
	var porta := porta_do_motel()
	if carro == null or porta == Vector2.INF or Vector2(carro.position.x, carro.position.z).distance_to(porta) > float(_cfg_progressao["motel"]["abastece_ate_metros"]):
		_avisar("Traga o carro para perto do motel.")
		return false
	var preco := _preco_da_gasolina()
	if preco == 0:
		_avisar("O tanque já está cheio.")
		return false
	if not progresso.gastar(preco, "gasolina"):
		_avisar("Falta dinheiro.")
		return false
	carro.litros += carro.faltam_litros()
	_avisar("Tanque cheio.")
	return true


## N: começa a conversa, se a criatura negocia e está perto.
func conversar() -> bool:
	if criatura == null or not criatura.visible or _distancia_da_criatura() > float(_cfg_negociacao["alcance_da_conversa"]):
		_avisar("Não tem com quem conversar aqui.")
		return false
	if not Negociacao.pode(criatura.ficha):
		_avisar("Ela não negocia.")
		return false
	var gatilho := gatilho_do_caso if not gatilho_do_caso.is_empty() else str(criatura.ficha["gatilhos"][0])
	negociacao = Negociacao.new(criatura.ficha, gatilho, _cfg_negociacao, Rng.new(semente).stream("negociacao:%s" % criatura.ficha["id"]))
	conversa_tela.visible = true
	cacador.bloqueado = true
	return true


func fechar_conversa() -> void:
	negociacao = null
	conversa_tela.visible = false
	if not ferimentos.morto:
		cacador.bloqueado = false


## Oferece a opção i. Acordo resolve (com termos); recusa vira confronto.
func oferecer(i: int) -> void:
	if negociacao == null:
		return
	negociacao.oferecer(i, bolsos)
	if negociacao.situacao == Negociacao.ACORDO:
		criatura.estado.acordo()
		acordos.append({"especie": criatura.ficha["id"], "termos": negociacao.termos.duplicate(), "traira": negociacao.traira})
		_avisar("Acordo: %s" % " ".join(negociacao.termos))
		fechar_conversa()
	elif negociacao.situacao == Negociacao.RECUSA:
		criatura.estado.recusou()
		_avisar("Ela recusou. Prepare-se!")
		fechar_conversa()


## T: abre a lista de rituais, se a criatura estiver perto.
func abrir_rituais() -> bool:
	if criatura == null or not criatura.visible or _distancia_da_criatura() > float(_cfg_armas["alcance_de_usar_item"]):
		_avisar("O ritual se faz perto da criatura.")
		return false
	ritual_tela.visible = true
	cacador.bloqueado = true
	return true


func fechar_ritual() -> void:
	ritual = null
	segurando = false
	ritual_tela.visible = false
	if not ferimentos.morto:
		cacador.bloqueado = false


## Começa o ritual i: a criatura tem de estar no estado que ele pede, e os materiais saem
## dos bolsos.
func comecar_ritual(i: int) -> bool:
	if i < 0 or i >= rituais.size():
		return false
	var def: Dictionary = rituais[i]
	var e: RefCounted = criatura.estado
	var ok_estado: bool = def["exige_estado"] == "livre" or e.estado == def["exige_estado"] or (def["exige_estado"] == "contida" and e.estado == EstadoCriatura.VULNERAVEL)
	if not ok_estado:
		_avisar("Ela precisa estar %s para isso." % str(def["exige_estado"]).replace("vulneravel", "vulnerável"))
		return false
	var gasto: Dictionary = Ritual.gastar_materiais(def, bolsos)
	if not gasto["ok"]:
		_avisar("Falta material: %s." % str(gasto["falta"]).replace("_", " "))
		return false
	var cfg_ritual: Dictionary = _cfg_rituais.duplicate()
	cfg_ritual["janela_base"] = float(cfg_ritual["janela_base"]) * habilidades.efeito("janela_do_ritual")
	cfg_ritual["janela_minima"] = float(cfg_ritual["janela_minima"]) * habilidades.efeito("janela_do_ritual")
	cfg_ritual["velocidade_do_marcador"] = float(cfg_ritual["velocidade_do_marcador"]) * habilidades.efeito("marcador_do_ritual")
	ritual = Ritual.new(def, cfg_ritual, Rng.new(semente).stream("ritual:%s:%d" % [def["id"], minuto]))
	ritual.perdoes = int(habilidades.efeito("perdoa_palavra"))
	tempo_do_passo = 0.0
	segurando = false
	return true


func apertar_no_ritual() -> void:
	var p: Dictionary = ritual.passo_atual()
	if p.get("tipo", "") == "apertar":
		_tentar_no_ritual()
	elif p.get("tipo", "") == "segurar":
		segurando = true
		tempo_do_passo = 0.0


func soltar_no_ritual() -> void:
	if segurando and ritual.passo_atual().get("tipo", "") == "segurar":
		segurando = false
		_tentar_no_ritual()


func escolher_palavra(i: int) -> void:
	if ritual.passo_atual().get("tipo", "") != "palavra":
		return
	ritual.escolher(i)
	_conferir_ritual()


func _tentar_no_ritual() -> void:
	var acertou: bool = ritual.tentar(ritual.marcador(tempo_do_passo), tempo_do_passo, medo.tremor(), float(ferimentos.modificadores()["ritual"]))
	if acertou:
		praticar("passo_de_ritual")
	else:
		_avisar("Errou o tempo: repita o passo.")
	tempo_do_passo = 0.0
	_conferir_ritual()


## Fim do ritual: completo entrega o item na criatura; errado para ela, o efeito é o
## contrário; palavra errada faz falhar (materiais perdidos).
func _conferir_ritual() -> void:
	if ritual.situacao == Ritual.FALHOU:
		_avisar("Palavra errada: o ritual falhou e os materiais se perderam.")
		fechar_ritual()
	elif ritual.situacao == Ritual.COMPLETO:
		praticar("ritual_completo")
		var efeito: Dictionary = criatura.receber(ritual.def["item"], 0.0)
		if efeito["efeito"].is_empty():
			criatura.estado.enfurecer()
			_avisar("Ritual errado para ela: se libertou e se enfureceu!")
		else:
			_avisar(TEXTO_DO_EFEITO.get(efeito["efeito"], "O ritual terminou."))
		fechar_ritual()


func _distancia_da_criatura() -> float:
	return Vector2(criatura.position.x, criatura.position.z).distance_to(Vector2(cacador.position.x, cacador.position.z))


## Põe a criatura de uma ficha no campo, à frente do caçador (para testar o confronto).
func trazer_criatura(id: String) -> void:
	var fichas: Dictionary = Catalogo.carregar_criaturas()["criaturas"]
	if not fichas.has(id):
		return
	if criatura != null:
		criatura.queue_free()
	criatura = Criatura3D.new()
	criatura.montar(fichas[id], _cfg_confronto["criatura"], _cfg_armas["criatura_em_campo"], Rng.new(semente).stream("criatura_em_campo"))
	add_child(criatura)
	var frente := Vector3(-sin(cacador.yaw), 0.0, -cos(cacador.yaw))
	criatura.position = Vector3(cacador.position.x, 0.0, cacador.position.z) + frente * float(_cfg_armas["criatura_em_campo"]["distancia_inicial"])


## Atira (ou golpeia, com a faca) para onde a câmera aponta. Armas de fogo pedem mira.
func atirar() -> Dictionary:
	if int(arsenal.arma()["capacidade"]) > 0 and not cacador.mirando:
		return {}
	var camera: Camera3D = cacador.camera
	var para_o_alvo := Vector3.ZERO
	var raio := 0.0
	if criatura != null and criatura.visible:
		para_o_alvo = criatura.global_position + Vector3(0, 1.0, 0) - camera.global_position
		raio = criatura.raio()
		if int(arsenal.arma()["capacidade"]) == 0:
			para_o_alvo = criatura.global_position - cacador.global_position
	var direcao := -camera.global_basis.z
	if int(arsenal.arma()["capacidade"]) == 0:
		direcao = Vector3(-sin(cacador.yaw), 0.0, -cos(cacador.yaw))
	var r: Dictionary = arsenal.disparar(direcao, para_o_alvo, raio, medo.tremor(), float(ferimentos.modificadores()["mira"]))
	if not r["ok"]:
		_avisar("Sem munição: R para recarregar." if r["motivo"] == "sem munição" else "Recarregando...")
		return r
	if float(r["barulho"]) > 0.0:
		som_tiros.stream = Sons.tiro_espingarda() if arsenal.equipada == "espingarda_de_sal" else Sons.tiro_revolver()
		_tocar(som_tiros)
	if float(r["barulho"]) > 0.0 and zona == "rua" and alguem_ve_o_cacador(float(r["barulho"])):
		suspeita.somar(str(bairro.dados["id"]), int(_cfg_armas["suspeita_por_disparo_com_gente_perto"]), "disparo", minuto)
	if r["acertou"]:
		praticar("acerto")
		var efeito: Dictionary = criatura.receber(r["item"], float(_cfg_armas["interrompe_ataque_por"]))
		_avisar(TEXTO_DO_EFEITO.get(efeito["efeito"], "Acertou, mas não fez efeito. Ela ficou mais agressiva."))
	return r


## Usa o item do bolso i: sal vira círculo nos pés; bandagem trata o pior ferimento; o resto
## vai na criatura, se estiver perto.
func usar_bolso(i: int) -> void:
	var item: String = bolsos.usar(i)
	if item.is_empty():
		_avisar("Acabou.")
		return
	var aqui := Vector2(cacador.position.x, cacador.position.z)
	if item == "sal_grosso":
		var c := Circulo.new(aqui, _cfg_armas["circulo_de_sal"])
		circulos.append(c)
		_desenhar_circulo(c)
		_avisar("Círculo de sal no chão.")
		return
	if item == "bandagem":
		var pior := ""
		for parte in ferimentos.gravidade:
			if pior.is_empty() or int(ferimentos.gravidade[parte]) > int(ferimentos.gravidade[pior]):
				pior = parte
		for k in 1 + int(habilidades.efeito("trata_mais")):
			ferimentos.tratar(pior)
		praticar("ferimento_tratado")
		_avisar("Bandagem: %s." % ferimentos.texto())
		return
	if criatura == null or not criatura.visible or Vector2(criatura.position.x, criatura.position.z).distance_to(aqui) > float(_cfg_armas["alcance_de_usar_item"]):
		bolsos.itens[i]["quantidade"] = int(bolsos.itens[i]["quantidade"]) + 1
		_avisar("Nada perto para usar isso.")
		return
	# Apaziguar: furiosa, ela não aceita a oferenda (converse antes).
	if "apazigua" in criatura.estado.efeitos_do_item(item) and criatura.estado.agressividade > int(_cfg_negociacao["apaziguar_ate_agressividade"]):
		bolsos.itens[i]["quantidade"] = int(bolsos.itens[i]["quantidade"]) + 1
		_avisar("Furiosa demais para aceitar. Acalme-a antes.")
		return
	var efeito: Dictionary = criatura.receber(item, 0.0)
	_avisar(TEXTO_DO_EFEITO.get(efeito["efeito"], "Não fez efeito. Ela ficou mais agressiva."))


func _desenhar_circulo(c: RefCounted) -> void:
	var anel := MeshInstance3D.new()
	var malha := TorusMesh.new()
	malha.inner_radius = c.raio - 0.06
	malha.outer_radius = c.raio
	malha.rings = 32
	anel.mesh = malha
	anel.scale = Vector3(1, 0.15, 1)
	anel.material_override = Materiais.objeto(Color(0.95, 0.95, 0.92), 1.0)
	anel.position = Vector3(c.centro.x, cacador.position.y - 0.25, c.centro.y)
	anel.set_meta("circulo", c)
	anel.name = "CirculoDeSal"
	add_child(anel)


func _physics_process(delta: float) -> void:
	if dirigindo:
		dirigir(Input.get_vector("mover_esquerda", "mover_direita", "mover_tras", "mover_frente"), delta)
	verificar_fronteira()


## O relógio da cidade anda; a cada minuto novo, todo mundo confere a rotina.
func passar_tempo(segundos: float) -> void:
	_sobra_de_minuto += segundos * minutos_por_segundo
	while _sobra_de_minuto >= 1.0:
		_sobra_de_minuto -= 1.0
		minuto += 1
		_um_minuto()
		for id in populacoes:
			populacoes[id].atualizar(minuto)
		if minuto % 60 == 0:
			for id in transeuntes:
				transeuntes[id].atualizar(Relogio.data_de(minuto)["hora"])
	for id in populacoes:
		populacoes[id].andar(segundos)
	for id in transeuntes:
		transeuntes[id].andar(segundos)
	if policia.andar(segundos, cacador.position) and zona == "rua":
		deter()
	_corpo_e_medo(segundos)


## Ferimentos pesam no corpo; o medo sobe no escuro e com a criatura perto, e a lanterna
## falha com medo alto. A criatura anda e ataca; os círculos de sal se desgastam.
func _corpo_e_medo(segundos: float) -> void:
	ferimentos.passar(segundos)
	var m: Dictionary = ferimentos.modificadores()
	var peso: Dictionary = Grade.efeito_do_peso(mochila.peso_g(), _cfg_inventario["peso"])
	cacador.modificadores = {"velocidade": float(m["velocidade"]) * float(peso["velocidade"]), "folego": float(m["folego"]) * float(peso["folego"]) * habilidades.efeito("folego")}
	if _abrindo_mochila > 0.0:
		_abrindo_mochila -= segundos
		if _abrindo_mochila <= 0.0:
			_mochila_aberta()
	arsenal.passar(segundos, float(m["mira"]))
	if ritual != null and (ritual.passo_atual().get("tipo", "") == "apertar" or segurando):
		tempo_do_passo += segundos
	var aqui := Vector2(cacador.position.x, cacador.position.z)
	var distancia := INF
	var pressionado := false
	# Conversando, a criatura escuta: não anda nem ataca.
	if criatura != null and criatura.visible and negociacao == null:
		var golpe: Dictionary = criatura.andar(segundos, cacador.position, circulos)
		pressionado = criatura.pressionando
		distancia = Vector2(criatura.position.x, criatura.position.z).distance_to(aqui)
		if not golpe.is_empty() and not ferimentos.morto:
			ferimentos.receber(golpe["parte"], golpe["gravidade"])
			praticar("golpe_recebido")
			if golpe["gravidade"] == "grave":
				var quebrados: Array[String] = mochila.quebrar_frageis(float(_cfg_inventario["chance_de_quebrar_fragil"]), _g_quebra)
				if not quebrados.is_empty():
					_avisar("Quebrou na mochila: %s." % ", ".join(quebrados.map(func(i): return itens[i]["nome"])))
			if ritual != null:
				ritual.interromper()
				tempo_do_passo = 0.0
			medo.susto(0.5)
			_avisar("Ferido: %s (%s)." % [str(golpe["parte"]).replace("_", " "), golpe["gravidade"]])
	var protegido := false
	for c in circulos:
		c.passar(segundos, false, pressionado)
		protegido = protegido or c.dentro(aqui)
	for no in get_children():
		if no.name.begins_with("CirculoDeSal") and not no.get_meta("circulo").ativo():
			circulos.erase(no.get_meta("circulo"))
			no.queue_free()
	_sensitivo(segundos, protegido, distancia)
	_passos_e_motor(segundos)
	var escuro := zona == "esgoto" or Relogio.new(minuto).eh_noite()
	medo.passar(segundos, {"escuro": escuro, "luz": cacador.lanterna.visible, "graves": ferimentos.graves(), "multiplicador": float(m["medo"]) * habilidades.efeito("medo"),
		"criatura_metros": distancia, "protegido": protegido})
	if _lanterna_apagada > 0.0:
		_lanterna_apagada -= segundos
		if _lanterna_apagada <= 0.0:
			cacador.lanterna.light_energy = _energia_da_lanterna
	elif cacador.lanterna.visible and medo.lanterna_falha(segundos):
		_energia_da_lanterna = cacador.lanterna.light_energy
		cacador.lanterna.light_energy = 0.0
		_lanterna_apagada = PISCADA_DA_LANTERNA
	if ferimentos.morto and not cacador.bloqueado:
		cacador.bloqueado = true
		_avisar("Você morreu. (O limbo vem depois.)")


## O que muda a cada minuto: a suspeita cai, quem vê o caçador sujo desconfia, a
## polícia acompanha o nível e a água das galerias acompanha a maré.
func _um_minuto() -> void:
	var id := str(bairro.dados["id"])
	aplicar_luz()
	suspeita.passar_minutos(1)
	if zona == "rua" and suspeita.sujo(minuto) and alguem_ve_o_cacador():
		# Disfarce (terno de agente): quem vê desconfia menos.
		suspeita.visto(id, minuto, cacador.aparencia.efeito("suspeita_de_quem_ve"))
	if suspeita.nivel(id) != policia.nivel:
		policia.atualizar(suspeita.nivel(id))
	subterraneo.nivel_da_agua(mare.fracao(minuto))


## Tem alguém (morador, transeunte ou policial) a poucos metros do caçador?
func alguem_ve_o_cacador(alcance: float = -1.0) -> bool:
	if alcance < 0.0:
		alcance = _alcance_de_quem_ve
	var aqui := Vector2(cacador.position.x, cacador.position.z)
	var nos: Array = []
	for id in populacoes:
		for npc_id in populacoes[id].pessoas:
			nos.append(populacoes[id].pessoas[npc_id]["no"])
	for id in transeuntes:
		for a in transeuntes[id].andantes:
			nos.append(a["no"])
	for p in policia.policiais:
		nos.append(p["no"])
	for no in nos:
		if no.visible and Vector2(no.position.x, no.position.z).distance_to(aqui) <= alcance:
			return true
	return false


## A polícia alcançou o caçador: detido. Perde horas (o mundo segue), a suspeita cai e
## ele sai na porta da delegacia, se houver uma por perto.
func deter() -> void:
	detencoes += 1
	var id := str(bairro.dados["id"])
	var antes := minuto
	minuto += _minutos_detido
	suspeita.passar_minutos(minuto - antes)
	suspeita.detido(id, minuto)
	for b in populacoes:
		populacoes[b].atualizar(minuto)
	for b in populacoes:
		for ponto in populacoes[b].pontos_chave:
			if ponto["tipo"] == "delegacia":
				cacador.position = Vector3(ponto["porta"].x, 0.3, ponto["porta"].y)
	cacador.velocity = Vector3.ZERO
	policia.atualizar(suspeita.nivel(str(bairro.dados["id"])))
	verificar_fronteira()
	_avisar("Detido pela polícia. Você perdeu %d horas." % (_minutos_detido / 60))


func _avisar(texto: String) -> void:
	nome_do_lugar.text = texto
	nome_do_lugar.add_theme_font_size_override("font_size", 16)
	_tempo_do_nome = TEMPO_DO_NOME


## "Maré subindo 1,1 m" e "Suspeita: observado".
func texto_do_painel() -> String:
	var altura: float = mare.altura(minuto)
	var sentido := "subindo" if mare.subindo(minuto) else "descendo"
	var alagada := " (alagada)" if mare.galerias_alagadas(minuto) else ""
	var texto := "Maré %s %s m%s\nSuspeita: %s\nMedo: %s" % [sentido, ("%.1f" % altura).replace(".", ","), alagada, suspeita.nivel(str(bairro.dados["id"])), medo.nivel()]
	if ferimentos.texto() != "nenhum":
		texto += "\nFerido: %s" % ferimentos.texto()
	return texto


## "Espingarda de sal: 2/2" e o estado da criatura, se houver uma no campo.
func texto_do_hud() -> String:
	var texto: String = "R$ %d · %s · %d anos\n" % [progresso.dinheiro, progresso.nivel_de_reputacao(), progresso.idade()]
	if condicao.tem():
		texto += condicao.texto() + "\n"
		var presenca := texto_da_presenca()
		if not presenca.is_empty():
			texto += presenca + "\n"
	if dirigindo:
		return texto + "Carro: %.0f km/h · %.1f L" % [absf(carro.velocidade) * 3.6, carro.litros]
	texto += arsenal.texto()
	if criatura != null and criatura.visible:
		var e: RefCounted = criatura.estado
		texto += "\nCriatura: %s%s" % [e.estado.replace("vulneravel", "vulnerável"), " (recuando)" if e.esta_afastada() else ""]
	return texto


## "Quarta, 08:05"
func texto_do_relogio() -> String:
	var d: Dictionary = Relogio.data_de(minuto)
	return "%s, %02d:%02d" % [NOMES_DOS_DIAS[d["nome_dia"]], int(d["hora"]), int(d["minuto"])]


func _process(delta: float) -> void:
	passar_tempo(delta)
	relogio.text = texto_do_relogio()
	hud.text = texto_do_hud()
	painel.text = texto_do_painel()
	painel.add_theme_color_override("font_color", CORES_DA_SUSPEITA[suspeita.nivel(str(bairro.dados["id"]))])
	var camera: Camera3D = cacador.camera
	_alvo = bueiro_na_mira(camera.global_position, -camera.global_basis.z)
	if _alvo < 0:
		aviso.text = ""
	else:
		aviso.text = "[E] descer pelo bueiro" if zona == "rua" else "[E] subir para a rua"
	aviso.modulate = Color(0.1, 0.1, 0.1) if zona == "rua" else Color(0.9, 0.85, 0.7)
	if _tempo_do_nome > 0.0:
		_tempo_do_nome -= delta
		nome_do_lugar.modulate.a = clampf(_tempo_do_nome, 0.0, 1.0)
	minimapa.queue_redraw()
	if _captura.is_empty():
		return
	_quadros += 1
	if _quadros == QUADROS_ANTES_DA_CAPTURA:
		get_viewport().get_texture().get_image().save_png(_captura)
		get_tree().quit()
