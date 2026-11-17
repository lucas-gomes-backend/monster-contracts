extends "res://tests/framework/test_case.gd"
## Fase 2: módulos cinza (casa e esgoto) vindos de game/data/modulos, a casa num lote
## da rua e o trecho de esgoto embaixo, com o bueiro para descer e a escada para subir.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Rua := preload("res://presentation/greybox/rua.gd")
const Blocos := preload("res://presentation/greybox/blocos.gd")

var _rua: Node3D


func before_each() -> void:
	_rua = Rua.new()
	_rua.montar(12)


func after_each() -> void:
	_rua.free()


func _ids_dos_modulos() -> Array[String]:
	var ids: Array[String] = []
	for nome in DirAccess.get_files_at("res://data/modulos"):
		if nome.ends_with(".json"):
			ids.append(nome.get_basename())
	return ids


## Caixa que envolve todos os blocos de um módulo (no espaço do módulo).
func _caixa(dados: Dictionary) -> AABB:
	var caixa := AABB()
	var primeira := true
	for b in dados["blocos"]:
		var tamanho := Blocos.vetor(b["tamanho"])
		var parte := AABB(Blocos.vetor(b["posicao"]) - tamanho / 2.0, tamanho)
		caixa = parte if primeira else caixa.merge(parte)
		primeira = false
	return caixa.grow(0.05)


func test_modulos_todos_passam_no_esquema() -> void:
	var ids := _ids_dos_modulos()
	assert_gte(ids.size(), 4, "casa e trechos de esgoto")
	for id in ids:
		var r := Catalogo.carregar_modulo(id)
		assert_eq(r["erros"].size(), 0, "%s: %s" % [id, r["erros"]])


func test_modulos_pontos_de_pista_e_passagens_ficam_dentro_do_modulo() -> void:
	for id in _ids_dos_modulos():
		var dados: Dictionary = Catalogo.carregar_modulo(id)["dados"]
		var caixa := _caixa(dados)
		for p in dados.get("pontos_de_pista", []) + dados.get("passagens", []):
			assert_true(caixa.has_point(Blocos.vetor(p["posicao"])), "%s: %s fora do módulo" % [id, p["id"]])


func test_casa_tem_pontos_de_pista_para_o_caso() -> void:
	var dados: Dictionary = Catalogo.carregar_modulo("casa_terrea")["dados"]
	assert_gte(dados["pontos_de_pista"].size(), 3, "lugares para o caso deixar marcas")
	assert_eq(_rua.pontos_de_pista(_rua.casa).size(), dados["pontos_de_pista"].size())


func test_rua_lote_da_casa_fica_livre_das_casas_de_bloco() -> void:
	var lote: Vector3 = _rua._lote_da_casa()
	for filho in _rua.get_children():
		if not filho is StaticBody3D:
			continue
		var forma: BoxShape3D = filho.get_child(0).shape
		var x_dentro: bool = signf(filho.position.x) == lote.x and absf(filho.position.x) > 6.0
		var z_cruza: bool = filho.position.z + forma.size.z / 2.0 > lote.y + 0.01 and filho.position.z - forma.size.z / 2.0 < lote.z - 0.01
		assert_false(x_dentro and z_cruza, "bloco em %s invade o lote da casa" % filho.position)


func test_rua_porta_da_casa_fica_na_calcada_e_o_piso_na_altura_dela() -> void:
	var porta: Marker3D = Blocos.marcadores(_rua.casa, "Passagem_porta")[0]
	var p: Vector3 = _rua.posicao_no_mundo(porta)
	assert_almost_eq(absf(p.x), 6.0, 0.01, "a porta está na linha das fachadas")
	assert_almost_eq(p.y, Rua.ALTURA_CALCADA, 0.01, "o piso da casa continua a calçada")


func test_esgoto_trechos_em_sequencia_sem_buraco() -> void:
	var trechos: Array = Catalogo.carregar_greybox("rua")["dados"]["esgoto"]["trechos"]
	assert_eq(_rua.esgoto.get_child_count(), trechos.size())
	var z := 0.0
	for i in trechos.size():
		assert_almost_eq(_rua.esgoto.get_child(i).position.z, z, 0.001, "trecho %d encaixa no anterior" % i)
		z += float(Catalogo.carregar_modulo(trechos[i])["dados"]["comprimento"])


func test_bueiro_desce_para_o_esgoto_escuro_e_a_escada_sobe() -> void:
	assert_eq(_rua.zona, "rua")
	_rua.usar_passagem("bueiro")
	assert_eq(_rua.zona, "esgoto")
	assert_true(_rua.cacador.position.y < _rua.esgoto.position.y + 1.0, "está lá embaixo")
	assert_false(_rua.lua.visible, "a lua não chega no esgoto")
	assert_true(_rua.ambiente.environment.ambient_light_energy < 0.1, "breu: só a lanterna ilumina")
	_rua.usar_passagem("subida")
	assert_eq(_rua.zona, "rua")
	assert_true(_rua.cacador.position.y >= 0.0, "voltou para a rua")
	assert_true(_rua.lua.visible)


func test_bueiro_vira_alvo_na_mira_depois_das_pessoas() -> void:
	var bueiro: Vector3 = _rua.passagens[0]["ponto"]
	_rua.cacador.position = bueiro + Vector3(0, 0, 1.0)
	var olho: Vector3 = bueiro + Vector3(0, 2.0, 3.0)
	var alvo: int = _rua.alvo_na_mira(olho, (bueiro - olho).normalized())
	assert_eq(alvo, _rua.pistas.size() + _rua.moradores.size(), "o bueiro é a primeira passagem")
