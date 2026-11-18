extends "res://tests/framework/test_case.gd"
## Fase 4: primeira passada de arte e áudio nos 2 bairros (docs/09), tudo gerado por código.

const Texturas := preload("res://presentation/arte/texturas.gd")
const Predio := preload("res://presentation/arte/predio.gd")
const Sons := preload("res://presentation/audio/sons.gd")
const Materiais := preload("res://presentation/ps1/materiais.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")


func _cfg() -> Dictionary:
	return Catalogo.carregar_config_arte_e_audio()["dados"]


func test_arte_e_audio_config_e_valida() -> void:
	assert_eq(Catalogo.carregar_config_arte_e_audio()["erros"], [] as Array[String])


func test_texturas_pequenas_e_sempre_iguais() -> void:
	var f: Texture2D = Texturas.fachada()
	assert_eq(f.get_width(), Texturas.MODULOS * Texturas.PX)
	assert_true(f.get_width() <= 256, "tamanho PS1")
	assert_eq(Texturas.fachada().get_image().get_data(), f.get_image().get_data(), "guardada, a mesma")
	var mais: Image = Texturas.janelas(0.9).get_image()
	var menos: Image = Texturas.janelas(0.1).get_image()
	var acesas := func(img: Image) -> int:
		var n := 0
		for y in range(0, img.get_height(), 4):
			for x in range(0, img.get_width(), 4):
				if img.get_pixel(x, y).r > 0.5:
					n += 1
		return n
	assert_true(acesas.call(mais) > acesas.call(menos), "mais janelas acesas com fração maior")
	var calcada: Image = Texturas.calcada_portuguesa().get_image()
	var escuros := 0
	for x in 64:
		if calcada.get_pixel(x, 10).r < 0.5:
			escuros += 1
	assert_true(escuros > 5 and escuros < 59, "pedras pretas e brancas")


func test_predio_tem_janelas_do_tamanho_certo() -> void:
	var m := Predio.malha(Vector3(12, 9, 6), 3.0)
	assert_eq(m.get_surface_count(), 2, "paredes e telhado")
	var arrays := m.surface_get_arrays(0)
	var maior_u := 0.0
	var maior_v := 0.0
	for uv in arrays[Mesh.ARRAY_TEX_UV]:
		maior_u = maxf(maior_u, uv.x)
		maior_v = maxf(maior_v, uv.y)
	assert_almost_eq(maior_u, 12.0 / 3.0 / 8.0, 0.001, "12 m = 4 janelas")
	assert_almost_eq(maior_v, 9.0 / 3.0 / 8.0, 0.001, "9 m = 3 andares")


func test_luz_da_hora_interpola_e_da_a_volta_a_meia_noite() -> void:
	var ciclo: Array = _cfg()["ciclo"]
	assert_almost_eq(Cena.luz_da_hora(12.0, ciclo)["sol"], 0.9, 0.001, "meio-dia")
	assert_almost_eq(Cena.luz_da_hora(2.0, ciclo)["sol"], 0.0, 0.001, "madrugada")
	var meio: float = Cena.luz_da_hora(7.0, ciclo)["sol"]
	assert_true(meio > 0.35 and meio < 0.9, "amanhecendo")
	assert_almost_eq(Cena.luz_da_hora(23.5, ciclo)["densidade"], 0.05, 0.001)


func test_sons_sintetizados_em_baixa_taxa() -> void:
	Sons.taxa = int(_cfg()["audio"]["taxa"])
	for s in [Sons.ambiente_dia(), Sons.ambiente_noite(), Sons.motor()]:
		assert_eq(s.loop_mode, AudioStreamWAV.LOOP_FORWARD, "ambiente e motor em laço")
		assert_eq(s.mix_rate, 11025)
	for s in [Sons.passo(), Sons.tiro_espingarda(), Sons.tiro_revolver(), Sons.sussurro()]:
		assert_eq(s.loop_mode, AudioStreamWAV.LOOP_DISABLED)
		assert_true(s.data.size() > 100)
	assert_true(Sons.tiro_espingarda().data.size() > Sons.tiro_revolver().data.size(), "a espingarda ecoa mais")


# --- Na cidade ---

func _cena(hora: int) -> Node3D:
	var cena := Cena.new()
	cena.montar("centro", 1)
	cena.minuto = (cena.minuto / 1440) * 1440 + hora * 60
	cena.aplicar_luz()
	return cena


func test_de_noite_janelas_postes_e_farol_acendem() -> void:
	var cena := _cena(22)
	assert_true(cena.noite > 0.5)
	assert_eq(Materiais.noite(), cena.noite, "janelas acesas")
	var acesas := 0
	for luz in cena.luzes_dos_postes:
		if luz.visible:
			acesas += 1
	assert_eq(acesas, int(_cfg()["postes"]["acesos_perto"]), "os postes perto acendem")
	assert_true(cena.farol.visible, "farol do carro")
	var perto: Vector3 = cena.luzes_dos_postes[0].position
	assert_true(Vector2(perto.x, perto.z).distance_to(Vector2(cena.cacador.position.x, cena.cacador.position.z)) < 40.0, "perto do caçador")
	cena.free()
	Materiais.definir_noite(0.0)


func test_de_dia_tudo_apagado_e_sol_forte() -> void:
	var cena := _cena(11)
	assert_true(cena.noite < 0.1)
	for luz in cena.luzes_dos_postes:
		assert_false(luz.visible)
	assert_false(cena.farol.visible)
	assert_true(cena.sol.light_energy > 0.8)
	cena.free()


func test_bairros_tem_postes_e_paleta_propria() -> void:
	var cena := _cena(11)
	# Os 2 bairros do corte vertical (o Monte Serrat só tem escadarias: sem postes).
	for id in ["centro", "valongo"]:
		assert_true(cena.carregados[id].postes.size() > 10, "%s tem postes" % id)
	cena.free()


func test_passos_tocam_pela_distancia_andada() -> void:
	var cena := _cena(11)
	cena.passar_tempo(0.1)
	var antes: int = cena.passos_tocados
	for i in 10:
		cena.cacador.position += Vector3(0.5, 0, 0)
		cena.passar_tempo(0.1)
	assert_true(cena.passos_tocados - antes >= 3, "5 m andados dão uns 3 passos")
	cena.free()
