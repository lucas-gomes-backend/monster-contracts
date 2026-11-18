extends "res://tests/framework/test_case.gd"
## Fase 4: casos gerados nos bairros do corte vertical (Valongo e Centro), com as
## criaturas que o tipo de cada bairro permite e o golpe humano.

const Gerador := preload("res://core/casos/gerador_casos.gd")

const SEMENTES := 12
## Valongo é antigo/religioso: corpo-seco, mais as coringas. Centro só tem as coringas.
const PERMITIDAS := {
	"valongo": ["corpo_seco", "lobisomem_br", "mula_sem_cabeca", "golpe_humano"],
	"centro": ["lobisomem_br", "mula_sem_cabeca", "golpe_humano"],
}

static var _cache: Dictionary = {}


func _casos(id_bairro: String) -> Array:
	if not _cache.has(id_bairro):
		var lista: Array = []
		for semente in range(1, SEMENTES + 1):
			lista.append(Gerador.gerar(semente, id_bairro))
		_cache[id_bairro] = lista
	return _cache[id_bairro]


func test_valongo_e_centro_geram_casos_justos_no_proprio_bairro() -> void:
	for id_bairro in PERMITIDAS:
		for caso in _casos(id_bairro):
			assert_true(caso.get("valido", false), "%s semente %d: %s" % [id_bairro, caso["semente"], str(caso.get("erros", []))])
			assert_eq(caso["bairro"], id_bairro)
			assert_false(caso["verdade"]["locais"].is_empty(), "%s semente %d sem local de ataque" % [id_bairro, caso["semente"]])


func test_especie_respeita_o_tipo_do_bairro() -> void:
	for id_bairro in PERMITIDAS:
		for caso in _casos(id_bairro):
			assert_has(PERMITIDAS[id_bairro], caso["verdade"]["especie"], "%s semente %d" % [id_bairro, caso["semente"]])


func test_o_corte_vertical_tem_tres_criaturas_e_o_golpe() -> void:
	var vistas := {}
	for id_bairro in PERMITIDAS:
		for caso in _casos(id_bairro):
			vistas[caso["verdade"]["especie"]] = true
	for especie in ["corpo_seco", "lobisomem_br", "mula_sem_cabeca", "golpe_humano"]:
		assert_true(vistas.has(especie), "%s aparece em algum caso (vistas: %s)" % [especie, str(vistas.keys())])
