extends "res://tests/framework/test_case.gd"
## Bairro abstrato e geração de população (core/mundo/bairro.gd, core/npcs/gerador_populacao.gd).

const Catalogo := preload("res://core/dados/catalogo.gd")
const Bairro := preload("res://core/mundo/bairro.gd")
const Gerador := preload("res://core/npcs/gerador_populacao.gd")
const Rng := preload("res://core/rng.gd")

const SEMENTES := [1, 2, 3, 4, 5, 6, 7, 8]
const PARES := {"familia": "familia", "amizade": "amizade", "desafeto": "desafeto", "patrao": "empregado", "empregado": "patrao"}


func _bairro() -> RefCounted:
	return Bairro.new(Catalogo.carregar_bairro("paqueta")["dados"])


func _config() -> Dictionary:
	return Catalogo.carregar_config_populacao()["dados"]


func _populacao(semente: int) -> Array[Dictionary]:
	return Gerador.gerar(_bairro(), _config(), Rng.new(semente))


func test_bairro_e_config_de_populacao_sao_validos() -> void:
	assert_eq(Catalogo.carregar_bairro("paqueta")["erros"], [] as Array[String], "bairro")
	assert_eq(Catalogo.carregar_config_populacao()["erros"], [] as Array[String], "população")


func test_bairro_casas_sao_criadas_em_rodizio_pelas_ruas() -> void:
	var b := _bairro()
	assert_eq(b.locais_do_tipo("casa").size(), 14, "14 casas")
	assert_eq(b.rua_de("paqueta/casa_01"), "rua_1")
	assert_eq(b.rua_de("paqueta/casa_04"), "rua_do_cemiterio")
	assert_eq(b.rua_de("paqueta/casa_05"), "rua_1")


func test_bairro_lugar_desconhecido_nao_tem_rua() -> void:
	assert_eq(_bairro().rua_de("paqueta/lugar_que_nao_existe"), "")
	assert_eq(_bairro().rua_de("fora_do_bairro"), "")


func test_populacao_tem_o_tamanho_alvo() -> void:
	var alvo := int(_bairro().dados["populacao_alvo"])
	for semente in SEMENTES:
		assert_eq(_populacao(semente).size(), alvo, "semente %d" % semente)


func test_populacao_ids_unicos_e_casas_e_trabalhos_validos() -> void:
	var b := _bairro()
	for semente in SEMENTES:
		var ids := {}
		for npc in _populacao(semente):
			if ids.has(npc["id"]):
				fail("semente %d: id repetido %s" % [semente, npc["id"]])
			ids[npc["id"]] = true
			if not b.existe(npc["casa"]):
				fail("semente %d: %s mora em casa inexistente" % [semente, npc["id"]])
			var trabalho: String = npc["trabalho"]
			if not (trabalho.is_empty() or trabalho == Bairro.FORA_DO_BAIRRO or b.existe(trabalho)):
				fail("semente %d: %s trabalha em lugar inexistente %s" % [semente, npc["id"], trabalho])


func test_populacao_familia_mora_junto_e_divide_o_sobrenome() -> void:
	for semente in SEMENTES:
		var casa_da_familia := {}
		for npc in _populacao(semente):
			var chave: String = npc["familia"]
			var esperado: Array = casa_da_familia.get(chave, [npc["casa"], npc["sobrenome"]])
			casa_da_familia[chave] = esperado
			if esperado != [npc["casa"], npc["sobrenome"]]:
				fail("semente %d: família %s separada" % [semente, chave])


func test_populacao_relacoes_sao_simetricas() -> void:
	for semente in SEMENTES:
		var por_id := {}
		var npcs := _populacao(semente)
		for npc in npcs:
			por_id[npc["id"]] = npc
		for npc in npcs:
			for relacao in npc["relacoes"]:
				var outro: Dictionary = por_id.get(relacao["com"], {})
				var volta := false
				for r in outro.get("relacoes", []):
					if r["com"] == npc["id"] and r["tipo"] == PARES[relacao["tipo"]]:
						volta = true
				if not volta:
					fail("semente %d: %s -> %s (%s) sem volta" % [semente, npc["id"], relacao["com"], relacao["tipo"]])


func test_populacao_respeita_o_maximo_de_cada_ocupacao() -> void:
	var maximos := {}
	for ocupacao in _config()["ocupacoes"]:
		maximos[ocupacao["id"]] = int(ocupacao["maximo"])
	for semente in SEMENTES:
		var contagem := {}
		for npc in _populacao(semente):
			var id_ocupacao: String = npc["ocupacao"].get("id", "")
			contagem[id_ocupacao] = int(contagem.get(id_ocupacao, 0)) + 1
		for id_ocupacao in contagem:
			if maximos.has(id_ocupacao) and contagem[id_ocupacao] > maximos[id_ocupacao]:
				fail("semente %d: %d x %s (máximo %d)" % [semente, contagem[id_ocupacao], id_ocupacao, maximos[id_ocupacao]])


func test_populacao_mesma_semente_gera_as_mesmas_pessoas() -> void:
	assert_eq(JSON.stringify(_populacao(42), "", true), JSON.stringify(_populacao(42), "", true))


func test_populacao_semente_diferente_gera_outras_pessoas() -> void:
	assert_ne(JSON.stringify(_populacao(42), "", true), JSON.stringify(_populacao(43), "", true))
