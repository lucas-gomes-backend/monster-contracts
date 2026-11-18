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
var cacador: CharacterBody3D
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
	var id := "valongo"
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
	nome_do_lugar.text = bairro.dados["nome"]
	_tempo_do_nome = TEMPO_DO_NOME
	minimapa.queue_redraw()


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
	ajuda.text = "WASD andar · Shift correr · F lanterna · E bueiro"
	ajuda.position = Vector2(8, 6)
	ajuda.add_theme_font_size_override("font_size", 11)
	ajuda.modulate = Color(0.15, 0.13, 0.1, 0.9)
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
	relogio = Label.new()
	relogio.position = Vector2(498, 150)
	relogio.size = Vector2(134, 16)
	relogio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relogio.add_theme_font_size_override("font_size", 11)
	relogio.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08))
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


## Desce pelo bueiro i (ou sobe, se já estiver lá embaixo). Muda a luz da zona.
func usar_bueiro(i: int) -> void:
	var p: Vector3 = subterraneo.bueiros[i]
	var env: Environment = ambiente.environment
	if zona == "rua":
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
		sol.visible = true
		env.background_color = COR_DA_NEVOA
		env.ambient_light_energy = 0.55
		env.fog_light_color = COR_DA_NEVOA
		env.fog_density = 0.035
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
	if evento.is_action_pressed("examinar") and _alvo >= 0:
		usar_bueiro(_alvo)
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	verificar_fronteira()


## O relógio da cidade anda; a cada minuto novo, todo mundo confere a rotina.
func passar_tempo(segundos: float) -> void:
	_sobra_de_minuto += segundos * minutos_por_segundo
	while _sobra_de_minuto >= 1.0:
		_sobra_de_minuto -= 1.0
		minuto += 1
		for id in populacoes:
			populacoes[id].atualizar(minuto)
		if minuto % 60 == 0:
			for id in transeuntes:
				transeuntes[id].atualizar(Relogio.data_de(minuto)["hora"])
	for id in populacoes:
		populacoes[id].andar(segundos)
	for id in transeuntes:
		transeuntes[id].andar(segundos)


## "Quarta, 08:05"
func texto_do_relogio() -> String:
	var d: Dictionary = Relogio.data_de(minuto)
	return "%s, %02d:%02d" % [NOMES_DOS_DIAS[d["nome_dia"]], int(d["hora"]), int(d["minuto"])]


func _process(delta: float) -> void:
	passar_tempo(delta)
	relogio.text = texto_do_relogio()
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
