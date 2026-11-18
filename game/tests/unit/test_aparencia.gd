extends "res://tests/framework/test_case.gd"
## Fase 4: criação de personagem com sliders, roupas por parte e disfarce de agente (docs/09).

const Aparencia := preload("res://core/personagem/aparencia.gd")
const Corpo := preload("res://presentation/personagem/corpo.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Inicio := preload("res://ui/inicio.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")
const Criacao := preload("res://presentation/personagem/criacao.tscn")


func _a() -> RefCounted:
	return Aparencia.new(Catalogo.carregar_config_aparencia()["dados"])


func _agente(a: RefCounted) -> void:
	a.escolher("tronco", "terno")
	a.escolher("pernas", "calca_social")
	a.escolher("pes", "sapato_social")


## Altura (topo) e largura do boneco montado.
func _medidas(a: RefCounted) -> Vector2:
	var no := Node3D.new()
	Corpo.montar(no, a)
	var topo := 0.0
	var largura := 0.0
	for m in no.get_children():
		var caixa: AABB = m.get_aabb()
		topo = maxf(topo, m.position.y + caixa.size.y / 2.0)
		largura = maxf(largura, absf(m.position.x) + caixa.size.x / 2.0)
	no.free()
	return Vector2(largura, topo)


func _pecas(a: RefCounted) -> int:
	var no := Node3D.new()
	Corpo.montar(no, a)
	var n := no.get_child_count()
	no.free()
	return n


func test_aparencia_config_e_valida_e_o_padrao_existe() -> void:
	assert_eq(Catalogo.carregar_config_aparencia()["erros"], [] as Array[String])
	var a := _a()
	for lista in ["peles", "cabelos", "cores_de_cabelo", "barbas"]:
		assert_true(a.opcoes(lista).size() >= 2, lista)
	for parte in ["cabeca", "tronco", "pernas", "pes"]:
		var ids: Array = a.opcoes(parte).map(func(o): return o["id"])
		assert_has(ids, a.roupas[parte])
		assert_true(ids.size() >= 2, "1 a 2 roupas (ou mais) por parte: %s" % parte)


func test_sliders_ficam_entre_0_e_1_e_opcao_que_nao_existe_e_recusada() -> void:
	var a := _a()
	a.definir_slider("altura", 3.0)
	assert_eq(a.sliders["altura"], 1.0)
	a.definir_slider("altura", -1.0)
	assert_eq(a.sliders["altura"], 0.0)
	assert_false(a.escolher("cabelos", "moicano_roxo"))
	assert_true(a.escolher("cabelos", "black_power"))
	assert_eq(a.cabelo, "black_power")


func test_disfarce_de_agente_so_com_as_tres_pecas() -> void:
	var a := _a()
	assert_eq(a.efeito("suspeita_de_quem_ve"), 1.0)
	a.escolher("tronco", "terno")
	a.escolher("pernas", "calca_social")
	assert_true(a.disfarce().is_empty(), "falta o sapato")
	a.escolher("pes", "sapato_social")
	assert_eq(a.disfarce()["id"], "agente")
	assert_eq(a.efeito("suspeita_de_quem_ve"), 0.5)


func test_guardar_e_restaurar_a_aparencia() -> void:
	var a := _a()
	a.definir_slider("nariz", 0.9)
	a.escolher("barbas", "cheia")
	_agente(a)
	var b := _a()
	b.de_dados(a.como_dados())
	assert_eq(b.como_dados(), a.como_dados())


func test_sliders_mudam_o_boneco() -> void:
	var baixo := _a()
	baixo.definir_slider("altura", 0.0)
	var alto := _a()
	alto.definir_slider("altura", 1.0)
	assert_true(_medidas(alto).y > _medidas(baixo).y + 0.2, "mais alto")
	var magro := _a()
	magro.definir_slider("compleicao", 0.0)
	var forte := _a()
	forte.definir_slider("compleicao", 1.0)
	assert_true(_medidas(forte).x > _medidas(magro).x, "mais largo")


func test_cabelo_barba_e_roupas_mudam_as_pecas() -> void:
	var careca := _a()
	careca.escolher("cabelos", "careca")
	var cabeludo := _a()
	cabeludo.escolher("cabelos", "comprido")
	cabeludo.escolher("barbas", "cheia")
	cabeludo.escolher("cabeca", "chapeu")
	assert_true(_pecas(cabeludo) > _pecas(careca))
	var terno := _a()
	_agente(terno)
	var jaqueta := _a()
	jaqueta.escolher("tronco", "camiseta")
	assert_true(_pecas(terno) > _pecas(jaqueta), "camisa e gravata aparecem no terno")


func test_disfarce_de_agente_faz_quem_ve_desconfiar_menos() -> void:
	var pontos := []
	for disfarcado in [false, true]:
		var cena := Cena.new()
		cena.montar("valongo", 1)
		if disfarcado:
			var a: RefCounted = cena.cacador.aparencia
			_agente(a)
			cena.cacador.vestir(a)
		cena.suspeita.sujar(cena.minuto)
		var t: Dictionary = cena.transeuntes["valongo"].andantes[0]
		t["no"].visible = true
		for i in 10:
			t["no"].position = cena.cacador.position
			cena.passar_tempo(1.0 / cena.minutos_por_segundo)
		pontos.append(cena.suspeita.pontos("valongo"))
		cena.free()
	assert_true(pontos[0] > 0)
	assert_eq(pontos[1], pontos[0] / 2, "o terno corta pela metade")


func test_cidade_veste_a_aparencia_da_criacao() -> void:
	var a := _a()
	a.escolher("cabelos", "black_power")
	_agente(a)
	Inicio.aparencia_escolhida = a.como_dados()
	var cena := Cena.new()
	cena.montar("valongo", 1)
	assert_eq(cena.cacador.aparencia.cabelo, "black_power")
	assert_eq(cena.cacador.aparencia.disfarce()["id"], "agente")
	cena.free()
	Inicio.aparencia_escolhida = {}


func test_tela_de_criacao_sorteia_e_guarda() -> void:
	var tela: Node3D = Criacao.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(tela)
	assert_true(tela.boneco.get_child_count() > 10, "o boneco aparece")
	var antes: Dictionary = tela.aparencia.como_dados()
	tela.sortear()
	assert_ne(tela.aparencia.como_dados(), antes, "aleatório muda")
	tela.guardar()
	assert_eq(Inicio.aparencia_escolhida, tela.aparencia.como_dados())
	tela.get_parent().remove_child(tela)
	tela.free()
	Inicio.aparencia_escolhida = {}
