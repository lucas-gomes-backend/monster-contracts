extends "res://tests/framework/test_case.gd"
## Fase 4: casos gerados nos bairros do corte vertical (Valongo e Centro), com as
## criaturas que o tipo de cada bairro permite e o golpe humano.

const Gerador := preload("res://core/casos/gerador_casos.gd")

const SEMENTES := 12
## Valongo é antigo/religioso: corpo-seco. O Curupira vive nas áreas verdes dos dois. Mais as coringas.
const PERMITIDAS := {
	"valongo": ["corpo_seco", "curupira", "lobisomem_br", "mula_sem_cabeca", "golpe_humano"],
	"centro": ["curupira", "lobisomem_br", "mula_sem_cabeca", "golpe_humano"],
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


func test_o_corte_vertical_tem_as_quatro_criaturas_e_o_golpe() -> void:
	var vistas := {}
	for id_bairro in PERMITIDAS:
		for caso in _casos(id_bairro):
			vistas[caso["verdade"]["especie"]] = true
	for especie in ["corpo_seco", "curupira", "lobisomem_br", "mula_sem_cabeca", "golpe_humano"]:
		assert_true(vistas.has(especie), "%s aparece em algum caso (vistas: %s)" % [especie, str(vistas.keys())])


func _culpados() -> Array:
	var lista: Array = []
	for id_bairro in PERMITIDAS:
		for caso in _casos(id_bairro):
			if caso["estrutura"] == "culpado_humano":
				lista.append(caso)
	return lista


func test_culpado_humano_um_morador_cometeu_o_crime_que_provocou_a_criatura() -> void:
	var casos := _culpados()
	assert_gte(casos.size(), 2, "há casos de culpado humano no corte vertical")
	for caso in casos:
		var verdade: Dictionary = caso["verdade"]
		var culpado: Dictionary = {}
		for npc in caso["npcs"]:
			if npc["id"] == verdade["culpado"]:
				culpado = npc
		assert_false(culpado.is_empty(), "o culpado é um morador")
		assert_gte(int(culpado.get("idade", 0)), 18, "adulto")
		assert_eq(verdade["especie"], "curupira", "só o Curupira reage a crime de morador")
		assert_has(["desmatamento", "caca_cruel"], verdade["crime"])
		assert_ne(caso["contrato"]["cliente"], verdade["culpado"], "o culpado não contrata o caçador")
		var crimes: Array = caso["registro"].buscar("humano.crime", verdade["culpado"])
		assert_gte(crimes.size(), 2, "cometeu o crime mais de uma vez")
		var provocacao: Array = caso["registro"].buscar("criatura.provocada")
		assert_true(int(provocacao[0]["minuto"]) > int(crimes[-1]["minuto"]), "a criatura reage depois do último crime")
		var marcas_do_crime := 0
		for pista in caso["pistas"]:
			if pista["origem"] == "crime" and pista["tipo"] == "marca":
				marcas_do_crime += 1
		assert_gte(marcas_do_crime, 1, "o crime deixa marcas no lugar")
		var apontam := 0
		for dep in caso["depoimentos"]:
			if dep["tipo"] == "ausencia" and dep["relato"]["quem_saiu"] == verdade["culpado"]:
				apontam += 1
		assert_gte(apontam, 2, "vizinhos viram o culpado sair à noite")


func test_paqueta_nao_tem_culpado_humano() -> void:
	var dados := Gerador.carregar_dados("paqueta")
	var bairro := preload("res://core/mundo/bairro.gd").new(dados["bairro"])
	for e in Gerador._estruturas_possiveis(dados["casos"], bairro, dados["criaturas"]):
		assert_ne(e["id"], "culpado_humano", "sem área verde, nada no Paquetá reage a crime")
