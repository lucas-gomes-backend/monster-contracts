extends "res://tests/framework/test_case.gd"
## Fase 4: estados da criatura, ferimentos localizados e medo (core/confronto, docs/06).

const Estado := preload("res://core/confronto/estado_criatura.gd")
const Ferimentos := preload("res://core/confronto/ferimentos.gd")
const Medo := preload("res://core/confronto/medo.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Rua := preload("res://presentation/greybox/rua.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_confronto()["dados"]


func _criatura(id: String) -> RefCounted:
	return Estado.new(Catalogo.carregar_criaturas()["criaturas"][id], _cfg()["criatura"])


func _ferimentos() -> RefCounted:
	return Ferimentos.new(_cfg()["ferimentos"])


func _medo(semente: int = 1) -> RefCounted:
	return Medo.new(_cfg()["medo"], Rng.new(semente).stream("medo"))


func test_confronto_config_e_valida() -> void:
	assert_eq(Catalogo.carregar_config_confronto()["erros"], [] as Array[String])


# --- Estados da criatura ---

func test_lobisomem_faca_benzida_fere_e_depois_cura() -> void:
	var c := _criatura("lobisomem_br")
	assert_eq(c.usar("arma_branca_benzida")["estado"], Estado.VULNERAVEL, "ferido: vulnerável")
	var r: Dictionary = c.usar("arma_branca_benzida")
	assert_eq(r["estado"], Estado.RESOLVIDA)
	assert_eq(c.resolucao, "cura")


func test_corpo_seco_sal_prende_e_o_sepultamento_bane() -> void:
	var c := _criatura("corpo_seco")
	assert_eq(c.usar("ritual_de_sepultamento")["estado"], Estado.LIVRE, "solto, o ritual não pega")
	assert_eq(c.usar("sal_grosso")["estado"], Estado.CONTIDA)
	assert_eq(c.usar("ritual_de_sepultamento")["estado"], Estado.RESOLVIDA)
	assert_eq(c.resolucao, "bane")


func test_mula_so_se_cura_contida() -> void:
	var c := _criatura("mula_sem_cabeca")
	assert_eq(c.usar("tirar_o_freio_de_ferro")["estado"], Estado.LIVRE)
	assert_eq(c.usar("laco_ate_o_galo_cantar")["estado"], Estado.CONTIDA)
	assert_eq(c.usar("tirar_o_freio_de_ferro")["estado"], Estado.RESOLVIDA)


func test_curupira_apaziguado_pela_oferenda_sem_luta() -> void:
	var c := _criatura("curupira")
	assert_eq(c.usar("oferenda_fumo_e_cachaca")["estado"], Estado.RESOLVIDA)
	assert_eq(c.resolucao, "apazigua")


func test_contencao_se_desgasta_e_a_criatura_se_solta() -> void:
	var c := _criatura("corpo_seco")
	c.usar("sal_grosso")
	var duracao: float = _cfg()["criatura"]["duracao"]["contida"]
	c.passar(duracao - 1.0)
	assert_eq(c.estado, Estado.CONTIDA, "ainda presa")
	c.passar(2.0)
	assert_eq(c.estado, Estado.LIVRE, "a contenção acabou")


func test_agua_benta_afasta_sem_prender() -> void:
	var c := _criatura("corpo_seco")
	assert_eq(c.usar("agua_benta")["efeito"], "afasta")
	assert_eq(c.estado, Estado.LIVRE)
	assert_true(c.esta_afastada())
	c.passar(float(_cfg()["criatura"]["duracao"]["afastada"]) + 0.1)
	assert_false(c.esta_afastada(), "o recuo acaba")


func test_o_que_nao_e_fraqueza_so_deixa_mais_agressiva() -> void:
	var c := _criatura("lobisomem_br")
	for i in 10:
		assert_eq(c.usar("sal_grosso")["efeito"], "")
	assert_eq(c.estado, Estado.LIVRE)
	assert_eq(c.agressividade, int(_cfg()["criatura"]["agressividade_maxima"]), "sobe até o máximo")


# --- Ferimentos ---

func test_perna_ferida_anda_mais_devagar_e_grave_pesa_mais_que_leve() -> void:
	var f := _ferimentos()
	assert_eq(f.modificadores()["velocidade"], 1.0)
	f.receber("perna_esquerda", "leve")
	var leve: float = f.modificadores()["velocidade"]
	assert_true(leve < 1.0, "leve já pesa")
	f.receber("perna_esquerda", "grave")
	var grave: float = f.modificadores()["velocidade"]
	assert_true(grave < leve, "grave pesa mais")
	assert_almost_eq(grave, float(_cfg()["ferimentos"]["grave"]["perna"]["velocidade"]), 0.001)


func test_ferimentos_se_somam_leve_leve_grave_grave_critico() -> void:
	var f := _ferimentos()
	f.receber("tronco", "leve")
	assert_eq(f.gravidade["tronco"], Ferimentos.LEVE)
	f.receber("tronco", "leve")
	assert_eq(f.gravidade["tronco"], Ferimentos.GRAVE, "dois leves")
	f.receber("tronco", "grave")
	assert_eq(f.gravidade["tronco"], Ferimentos.CRITICO, "grave em cima de grave")


func test_critico_sem_tratamento_mata_mais_rapido_na_cabeca() -> void:
	var cabeca := _ferimentos()
	cabeca.receber("cabeca", "critico")
	var perna := _ferimentos()
	perna.receber("perna_direita", "critico")
	var limite: float = _cfg()["ferimentos"]["critico_mata_em"]["cabeca"]
	cabeca.passar(limite + 1.0)
	perna.passar(limite + 1.0)
	assert_true(cabeca.morto, "crítico na cabeça mata rápido")
	assert_eq(cabeca.causa_da_morte, "cabeca")
	assert_false(perna.morto, "na perna dá mais tempo")


func test_tratar_desce_um_degrau_e_salva_do_critico() -> void:
	var f := _ferimentos()
	f.receber("cabeca", "critico")
	f.passar(10.0)
	f.tratar("cabeca")
	assert_eq(f.gravidade["cabeca"], Ferimentos.GRAVE)
	assert_eq(f.tempo_ate_morrer(), -1.0, "não está mais morrendo")
	f.passar(1000.0)
	assert_false(f.morto)


func test_braco_dominante_ferido_pesa_mais_na_mira() -> void:
	var dir := _ferimentos()
	dir.receber("braco_direito", "grave")
	var esq := _ferimentos()
	esq.receber("braco_esquerdo", "grave")
	assert_true(dir.modificadores()["mira"] > esq.modificadores()["mira"])
	assert_true(esq.modificadores()["mira"] > 1.0, "o outro braço também pesa")
	assert_true(dir.modificadores()["ritual"] > 1.0, "ritual fica mais difícil")


# --- Medo ---

func test_medo_sobe_no_escuro_sem_luz_e_desce_com_lanterna() -> void:
	var m := _medo()
	m.passar(30.0, {"escuro": true, "luz": false})
	var no_escuro: float = m.valor
	assert_true(no_escuro > 0.0)
	m.passar(5.0, {"escuro": true, "luz": true})
	assert_true(m.valor < no_escuro, "a lanterna acalma")


func test_criatura_perto_assusta_muito_e_longe_acalma() -> void:
	var m := _medo()
	m.passar(5.0, {"criatura_metros": 5.0})
	assert_eq(m.nivel(), Medo.TENSO)
	m.passar(5.0, {"criatura_metros": 5.0})
	assert_eq(m.nivel(), Medo.APAVORADO)
	var antes: float = m.valor
	m.passar(5.0, {"criatura_metros": 100.0})
	assert_true(m.valor < antes, "longe, o medo desce")


func test_cabeca_ferida_faz_o_medo_subir_mais_rapido() -> void:
	var a := _medo()
	var b := _medo()
	a.passar(10.0, {"escuro": true})
	b.passar(10.0, {"escuro": true, "multiplicador": 1.5})
	assert_true(b.valor > a.valor)


func test_maos_tremem_e_lanterna_falha_so_com_medo() -> void:
	var calmo := _medo()
	assert_eq(calmo.tremor(), 0.0)
	var falhas := 0
	for i in 200:
		if calmo.lanterna_falha(0.1):
			falhas += 1
	assert_eq(falhas, 0, "calmo, a lanterna não falha")
	var apavorado := _medo()
	apavorado.passar(30.0, {"criatura_metros": 1.0})
	assert_true(apavorado.tremor() > 0.9)
	for i in 200:
		if apavorado.lanterna_falha(0.1):
			falhas += 1
	assert_true(falhas > 0, "apavorado, a lanterna falha")


func test_medo_e_deterministico_pela_semente() -> void:
	var a := _medo(7)
	var b := _medo(7)
	a.valor = 100.0
	b.valor = 100.0
	var sa: Array = []
	var sb: Array = []
	for i in 50:
		sa.append(a.lanterna_falha(0.1))
		sb.append(b.lanterna_falha(0.1))
	assert_eq(sa, sb)


# --- No jogo ---

func test_perna_ferida_o_cacador_anda_mais_devagar_de_verdade() -> void:
	var rua := Rua.new()
	rua.montar(12)
	(Engine.get_main_loop() as SceneTree).root.add_child(rua)
	rua.cacador.position = Vector3(1.0, 0.05, 0.0)
	for i in 30:
		rua.cacador.passo(Vector2(0, 1), false, 1.0 / 60.0)
	var sao: float = Vector2(rua.cacador.velocity.x, rua.cacador.velocity.z).length()
	var f := _ferimentos()
	f.receber("perna_direita", "grave")
	rua.cacador.modificadores = f.modificadores()
	for i in 60:
		rua.cacador.passo(Vector2(0, 1), false, 1.0 / 60.0)
	var mancando: float = Vector2(rua.cacador.velocity.x, rua.cacador.velocity.z).length()
	assert_true(mancando < sao * 0.8, "mancando (%.2f) mais devagar que são (%.2f)" % [mancando, sao])
	rua.get_parent().remove_child(rua)
	rua.free()


func test_cidade_mostra_medo_e_ferimentos_e_o_escuro_do_esgoto_assusta() -> void:
	var cena := Cena.new()
	cena.montar("valongo", 1)
	assert_has(cena.texto_do_painel(), "Medo: calmo")
	cena.ferimentos.receber("perna_esquerda", "grave")
	cena.zona = "esgoto"
	cena.cacador.lanterna.visible = false
	cena.passar_tempo(60.0)
	assert_true(cena.medo.valor > 0.0, "no escuro do esgoto, sem lanterna, o medo sobe")
	assert_true(cena.cacador.modificadores["velocidade"] < 1.0, "o corpo sente a perna")
	assert_has(cena.texto_do_painel(), "Ferido: perna esquerda (grave)")
	cena.free()


func test_mapas_do_confronto_usam_estados_e_partes_que_existem() -> void:
	var cfg := _cfg()
	for efeito in cfg["criatura"]["efeito_leva_a"]:
		assert_has(["contida", "vulneravel", "afastada"], cfg["criatura"]["efeito_leva_a"][efeito])
	for efeito in cfg["criatura"]["finais"]:
		assert_has(["livre", "contida", "vulneravel"], cfg["criatura"]["finais"][efeito])
	for parte in cfg["ferimentos"]["partes"]:
		assert_true(cfg["ferimentos"]["critico_mata_em"].has(parte), "%s tem tempo até morrer" % parte)
