extends "res://tests/framework/test_case.gd"
## Fase 5: Iara, Afogado e Kappa, as criaturas da água (docs/pesquisa, seções 11 a 13).
## Moram na praia e nos canais: entram nos bairros da orla e ficam fora da zona central.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Solucionador := preload("res://core/casos/solucionador.gd")
const Gerador := preload("res://core/casos/gerador_casos.gd")
const DA_AGUA := ["iara", "afogado", "kappa"]


func _ficha(id: String) -> Dictionary:
	return Catalogo.carregar_criaturas()["criaturas"][id]


func _mora(id_criatura: String, id_bairro: String) -> bool:
	var b: Dictionary = Catalogo.carregar_bairro(id_bairro)["dados"]
	var tipos := []
	for l in b["locais"]:
		tipos.append(l["tipo"])
	return Solucionador.vive_no_bairro(_ficha(id_criatura), b["tipo"], tipos)


func test_fichas_validas() -> void:
	var r := Catalogo.carregar_criaturas()
	assert_eq(r["erros"], [] as Array[String])
	for id in DA_AGUA:
		assert_has(r["criaturas"], id)


func test_criaturas_da_agua_moram_na_orla() -> void:
	assert_true(_mora("iara", "gonzaga"), "a Iara mora na praia do Gonzaga")
	assert_true(_mora("afogado", "boqueirao"), "o Afogado mora na praia e no canal")
	assert_true(_mora("kappa", "embare"), "o Kappa mora no canal")
	assert_true(_mora("iara", "ponta_da_praia"), "a Ponta da Praia é do tipo orla")


func test_criaturas_da_agua_nao_moram_na_zona_central() -> void:
	for id in DA_AGUA:
		for bairro in ["valongo", "centro", "paqueta", "macuco", "porto"]:
			assert_false(_mora(id, bairro), "%s não mora no %s" % [id, bairro])


func test_casos_da_orla_podem_ter_as_criaturas_da_agua() -> void:
	var vistas := {}
	for bairro in ["gonzaga", "ponta_da_praia", "boqueirao", "embare"]:
		for s in range(1, 41):
			var caso := Gerador.gerar(s, bairro)
			if caso.get("valido", false):
				vistas[caso["verdade"]["especie"]] = true
	for id in DA_AGUA:
		assert_has(vistas, id, "%s aparece em algum caso da orla" % id)


func test_reverencia_e_enterro_sao_rituais_com_materiais_da_loja() -> void:
	var loja := {}
	for e in Catalogo.carregar_config_progressao()["dados"]["loja"]:
		loja[e["item"]] = true
	var achados := {}
	for r in Catalogo.carregar_config_rituais()["dados"]["rituais"]:
		if r["id"] in ["reverencia", "enterro_do_afogado"]:
			achados[r["id"]] = true
			for m in r["materiais"]:
				assert_has(loja, m["item"], "%s: %s se compra" % [r["id"], m["item"]])
	assert_eq(achados.size(), 2)
