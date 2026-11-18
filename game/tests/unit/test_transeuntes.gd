extends "res://tests/framework/test_case.gd"
## Fase 4: transeuntes, figurantes andando a esmo pelas ruas (presentation/cidade).

const Catalogo := preload("res://core/dados/catalogo.gd")
const Trans := preload("res://presentation/cidade/transeuntes_3d.gd")
const Lotes := preload("res://core/cidade/lotes.gd")

var _t: Node3D
var _real: Dictionary


func before_each() -> void:
	_real = Catalogo.carregar_bairro_real("valongo")["dados"]
	_t = Trans.new()
	_t.montar("valongo", _real, 1)


func after_each() -> void:
	_t.free()


func _na_rua(p: Vector2) -> bool:
	for rua in _real["ruas"]:
		var pontos := Lotes._pontos(rua["pontos"])
		for i in pontos.size() - 1:
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p, pontos[i], pontos[i + 1])) < 0.6:
				return true
	return false


func test_transeuntes_config_valida() -> void:
	var r := Catalogo.carregar_config_transeuntes()
	assert_eq(r["erros"].size(), 0, str(r["erros"]))


func test_de_dia_a_rua_enche_e_de_madrugada_esvazia() -> void:
	_t.atualizar(12)
	assert_eq(_t.ativos(), int(_t.por_hora[12]), "ao meio-dia")
	_t.atualizar(3)
	for i in 600:
		_t.andar(1.0)
	assert_eq(_t.ativos(), int(_t.por_hora[3]), "às 3h, quem chega ao destino vai embora")


func test_transeuntes_andam_pelas_ruas_sem_parar() -> void:
	_t.atualizar(12)
	var a: Dictionary = _t.andantes[0]
	var antes := Vector3(a["no"].position)
	for i in 120:
		_t.andar(0.5)
		var p := Vector2(a["no"].position.x, a["no"].position.z)
		assert_true(_na_rua(p) or a["passo"] <= 1, "anda pela rua (%s)" % p)
	assert_true(a["ativo"], "continua na rua: chegou e foi para outro lugar")
	assert_gte(Vector3(a["no"].position).distance_to(antes), 1.0, "saiu do lugar")


func test_mesma_semente_mesmo_movimento() -> void:
	var outro := Trans.new()
	outro.montar("valongo", _real, 1)
	_t.atualizar(12)
	outro.atualizar(12)
	for i in 30:
		_t.andar(0.5)
		outro.andar(0.5)
	for i in _t.andantes.size():
		assert_eq(Vector3(_t.andantes[i]["no"].position), Vector3(outro.andantes[i]["no"].position))
	outro.free()


func test_cidade_tem_transeuntes_em_todo_bairro_carregado() -> void:
	const Cena := preload("res://presentation/cidade/bairro_cena.gd")
	var cena := Cena.new()
	cena.montar("valongo", 1)
	for id in cena.carregados:
		assert_true(cena.transeuntes.has(id), "%s tem transeuntes" % id)
		assert_gte(cena.transeuntes[id].ativos(), 1, "às 8h já tem gente andando em %s" % id)
	cena.free()
