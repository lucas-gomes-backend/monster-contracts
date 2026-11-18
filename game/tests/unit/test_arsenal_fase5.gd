extends "res://tests/framework/test_case.gd"
## Fase 5: rituais, armas, itens e disfarces novos. Cada criatura do bestiário passa a ter
## como ser resolvida no 3D (itens das fraquezas e rituais), docs/06.

const Arsenal := preload("res://core/confronto/arsenal.gd")
const Bolsos := preload("res://core/confronto/bolsos.gd")
const Rng := preload("res://core/rng.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const Cena := preload("res://presentation/cidade/bairro_cena.gd")
const Aparencia := preload("res://core/personagem/aparencia.gd")


func _armas() -> Dictionary:
	return Catalogo.carregar_config_armas()["dados"]


func test_configs_validas() -> void:
	for r in [Catalogo.carregar_config_armas(), Catalogo.carregar_config_rituais(), Catalogo.carregar_itens(), Catalogo.carregar_config_progressao(), Catalogo.carregar_config_aparencia()]:
		assert_eq(r["erros"], [] as Array[String])


func test_toda_fraqueza_que_e_coisa_de_levar_existe_como_item_ou_ritual_ou_arma() -> void:
	var itens := {}
	for id in Catalogo.carregar_itens()["dados"]:
		itens[id] = true
	for r in Catalogo.carregar_config_rituais()["dados"]["rituais"]:
		itens[r["item"]] = true
	for a in _armas()["armas"]:
		itens[a["item"]] = true
		if a.has("municao_especial"):
			itens[a["municao_especial"]["entrega"]] = true
	# Coisas que não se carregam: provas, atos e o que acontece na investigação.
	var nao_e_coisa := ["provas_documentais", "prova_da_injustica", "padre_amaldicoa_sete_vezes", "ferimento_leve_que_sangra", "agua_corrente", "luz_do_sol"]
	for ficha in Catalogo.carregar_criaturas()["criaturas"].values():
		for f in ficha["fraquezas"]:
			if not f["item"] in nao_e_coisa:
				assert_true(itens.has(f["item"]), "%s: %s não tem item, arma nem ritual" % [ficha["id"], f["item"]])


func test_toda_criatura_nova_tem_ritual_ou_item_para_a_resolucao() -> void:
	var rituais := {}
	for r in Catalogo.carregar_config_rituais()["dados"]["rituais"]:
		rituais[r["item"]] = r["id"]
	assert_eq(rituais.get("ritual_de_purificacao", ""), "purificacao")
	assert_eq(rituais.get("queimar_o_contrato", ""), "queimar_o_contrato")
	assert_eq(rituais.get("tirar_o_cinto_de_pele", ""), "tirar_o_cinto")


func test_balas_de_prata_entram_primeiro_e_cada_tiro_entrega_o_item_da_bala() -> void:
	var a := Arsenal.new(_armas(), Rng.new(1).stream("armas"))
	a.equipar("revolver")
	for i in 2:
		a.disparar(Vector3.FORWARD, Vector3.ZERO, 0.5)
	assert_true(a.recarregar(2, "prata"))
	a.passar(100.0)
	assert_eq(int(a.municao["revolver"]), 6)
	assert_eq(a.disparar(Vector3.FORWARD, Vector3.ZERO, 0.5)["item"], "prata")
	assert_eq(a.disparar(Vector3.FORWARD, Vector3.ZERO, 0.5)["item"], "prata")
	assert_eq(a.disparar(Vector3.FORWARD, Vector3.ZERO, 0.5)["item"], "bala_comum")


func test_bolsos_ate_oito_lugares_e_vazio_e_reaproveitado() -> void:
	var b := Bolsos.new([{"item": "sal_grosso", "nome": "Sal", "quantidade": 1}])
	for i in 7:
		assert_true(b.guardar("x%d" % i, "X"))
	assert_false(b.guardar("alho", "Alho"), "oito lugares")
	assert_eq(b.esvaziar(0), {"item": "sal_grosso", "quantidade": 1})
	assert_true(b.guardar("alho", "Alho"), "o bolso vazio é reaproveitado")
	assert_eq(b.quantidade("alho"), 1)


func test_disfarce_de_estivador_so_vale_no_cais_e_o_jaleco_em_todo_lugar() -> void:
	var cfg: Dictionary = Catalogo.carregar_config_aparencia()["dados"]
	var ap := Aparencia.new(cfg)
	ap.roupas["tronco"] = "macacao_de_estivador"
	assert_eq(ap.disfarce()["id"], "estivador")
	assert_eq(ap.efeito("suspeita_de_quem_ve"), 1.0)
	assert_true(ap.efeito("suspeita_no_porto") < 1.0)
	ap.roupas["tronco"] = "jaleco"
	assert_eq(ap.disfarce()["id"], "legista")
	assert_true(ap.efeito("suspeita_de_quem_ve") < 1.0)


# --- Na cidade ---

func _cena(bairro: String = "valongo") -> Node3D:
	var cena := Cena.new()
	cena.montar(bairro, 1)
	return cena


func test_recarregar_usa_as_balas_de_prata_da_mochila_primeiro() -> void:
	var cena := _cena()
	cena.mochila.adicionar("bala_de_prata", 2)
	cena.equipar("revolver")
	for i in 3:
		cena.arsenal.disparar(Vector3.FORWARD, Vector3.ZERO, 0.5)
	assert_true(cena.recarregar_da_mochila())
	assert_eq(cena.mochila.quantidade("bala_de_prata"), 0, "as 2 de prata entraram")
	cena.arsenal.passar(100.0)
	assert_eq(cena.arsenal.disparar(Vector3.FORWARD, Vector3.ZERO, 0.5)["item"], "prata")
	cena.free()


func test_estaca_e_facao_so_com_o_item_na_mochila_e_a_faca_sempre() -> void:
	var cena := _cena()
	assert_true(cena.arma_na_mochila("faca"))
	assert_false(cena.arma_na_mochila("estaca"))
	assert_false(cena.equipar("facao"))
	cena.mochila.adicionar("estaca", 1)
	assert_true(cena.equipar("estaca"))
	cena.free()


func test_estivador_desconfia_menos_no_porto_que_no_valongo() -> void:
	var porto := _cena("porto")
	var valongo := _cena("valongo")
	for c in [porto, valongo]:
		c.cacador.aparencia.roupas["tronco"] = "macacao_de_estivador"
	assert_true(porto._fator_do_disfarce() < 1.0, "no cais")
	assert_eq(valongo._fator_do_disfarce(), 1.0, "fora do cais, nada muda")
	porto.free()
	valongo.free()


func test_bolso_volta_para_a_mochila() -> void:
	var cena := _cena()
	var sal_na_mochila: int = cena.mochila.quantidade("sal_grosso")
	var sal_no_bolso: int = cena.bolsos.quantidade("sal_grosso")
	var i := -1
	for j in cena.bolsos.itens.size():
		if cena.bolsos.itens[j]["item"] == "sal_grosso":
			i = j
	assert_true(cena.guardar_bolso_na_mochila(i))
	assert_eq(cena.bolsos.quantidade("sal_grosso"), 0)
	assert_eq(cena.mochila.quantidade("sal_grosso"), sal_na_mochila + sal_no_bolso)
	cena.free()
