extends RefCounted
## Carrega e valida o conteúdo em JSON (rules/implementacao.md: conteúdo é dado).
## Os arquivos são lidos em ordem alfabética, para o resultado ser sempre o mesmo.

const Esquema := preload("res://core/dados/esquema.gd")

const PASTA_CRIATURAS := "res://data/creatures"
const ESQUEMA_CRIATURA := "res://data/schemas/criatura.schema.json"
const CONFIG_SIM_CRIATURAS := "res://data/config/simulacao_criaturas.json"
const ESQUEMA_SIM_CRIATURAS := "res://data/schemas/simulacao_criaturas.schema.json"


## Lê um JSON e valida contra um esquema. Devolve {"dados": ..., "erros": [...]}.
static func carregar_validado(caminho: String, caminho_esquema: String) -> Dictionary:
	var resultado := {"dados": null, "erros": [] as Array[String]}
	var esquema_dados: Variant = ler_json(caminho_esquema)
	if not esquema_dados is Dictionary:
		resultado["erros"].append("%s: esquema ausente ou inválido" % caminho_esquema)
		return resultado
	var dados: Variant = ler_json(caminho)
	if dados == null:
		resultado["erros"].append("%s: ausente ou não é JSON válido" % caminho)
		return resultado
	for erro in Esquema.new(esquema_dados).validate(dados):
		resultado["erros"].append("%s: %s" % [caminho.get_file(), erro])
	resultado["dados"] = dados
	return resultado


## Parâmetros da simulação de criaturas, validados.
static func carregar_config_criaturas() -> Dictionary:
	return carregar_validado(CONFIG_SIM_CRIATURAS, ESQUEMA_SIM_CRIATURAS)


## Parâmetros de geração de população, validados.
static func carregar_config_populacao() -> Dictionary:
	return carregar_validado("res://data/config/populacao.json", "res://data/schemas/populacao.schema.json")


## Parâmetros do gerador de casos, validados.
static func carregar_config_casos() -> Dictionary:
	return carregar_validado("res://data/config/casos.json", "res://data/schemas/casos.schema.json")


## Parâmetros das testemunhas (percepção e mentiras), validados.
static func carregar_config_testemunhas() -> Dictionary:
	return carregar_validado("res://data/config/testemunhas.json", "res://data/schemas/testemunhas.schema.json")


## Custos de tempo da investigação, validados.
static func carregar_config_investigacao() -> Dictionary:
	return carregar_validado("res://data/config/investigacao.json", "res://data/schemas/investigacao.schema.json")


## Textos dos gatilhos (o "por quê" do caso): {gatilho: frase}.
static func carregar_textos_gatilhos() -> Dictionary:
	var dados: Variant = ler_json("res://data/textos/gatilhos.json")
	if not dados is Dictionary:
		return {"dados": {}, "erros": ["res://data/textos/gatilhos.json: ausente ou inválido"] as Array[String]}
	var textos: Dictionary = dados.duplicate()
	textos.erase("$comment")
	return {"dados": textos, "erros": [] as Array[String]}


## Movimento do caçador e câmera, validados.
static func carregar_config_personagem() -> Dictionary:
	return carregar_validado("res://data/config/personagem.json", "res://data/schemas/personagem.schema.json")


## Lanterna, mira, exame e câmera fotográfica, validados.
static func carregar_config_inspecao() -> Dictionary:
	return carregar_validado("res://data/config/inspecao.json", "res://data/schemas/inspecao.schema.json")


## Uma cena cinza (res://data/greybox/<id>.json), validada; os módulos citados precisam existir.
static func carregar_greybox(id_cena: String) -> Dictionary:
	var resultado := carregar_validado("res://data/greybox/%s.json" % id_cena, "res://data/schemas/greybox.schema.json")
	if not resultado["dados"] is Dictionary:
		return resultado
	var modulos: Array = resultado["dados"].get("esgoto", {}).get("trechos", []).duplicate()
	modulos.append(resultado["dados"].get("casa", {}).get("modulo", ""))
	for id_modulo in modulos:
		if not FileAccess.file_exists("res://data/modulos/%s.json" % id_modulo):
			resultado["erros"].append("%s.json: módulo inexistente \"%s\"" % [id_cena, id_modulo])
	return resultado


## Aparência das marcas no mundo cinza, validada: cada entrada no formato do esquema e
## toda marca com texto em res://data/textos/marcas.json.
static func carregar_aparencia_marcas() -> Dictionary:
	var caminho := "res://data/greybox/aparencia_marcas.json"
	var caminho_esquema := "res://data/schemas/aparencia_marcas.schema.json"
	var resultado := carregar_validado(caminho, caminho_esquema)
	if not resultado["dados"] is Dictionary:
		return resultado
	var esquema_raiz: Variant = ler_json(caminho_esquema)
	var de_uma := Esquema.new(esquema_raiz["$defs"]["aparencia"])
	var textos: Dictionary = carregar_textos_marcas()["dados"]
	var marcas: Dictionary = resultado["dados"].get("marcas", {})
	for tag in marcas:
		for erro in de_uma.validate(marcas[tag]):
			resultado["erros"].append("aparencia_marcas.json: %s: %s" % [tag, erro])
		if not textos.has(tag):
			resultado["erros"].append("aparencia_marcas.json: marca sem texto \"%s\"" % tag)
	return resultado


## Um bairro do mapa real (res://data/cidade/<id>.json, gerado por tools/cidade/importar.py), validado.
static func carregar_bairro_real(id_bairro: String) -> Dictionary:
	var resultado := carregar_validado("res://data/cidade/%s.json" % id_bairro, "res://data/schemas/cidade_bairro.schema.json")
	if resultado["dados"] is Dictionary and resultado["dados"].get("id", "") != id_bairro:
		resultado["erros"].append("%s.json: o id precisa ser igual ao nome do arquivo" % id_bairro)
	return resultado


## Tempo na cidade 3D (início do dia, velocidade do relógio e de quem anda), validado.
static func carregar_config_relogio_da_cidade() -> Dictionary:
	return carregar_validado("res://data/config/relogio_da_cidade.json", "res://data/schemas/relogio_da_cidade.schema.json")


## Suspeita e polícia básicas, validadas.
static func carregar_config_suspeita() -> Dictionary:
	return carregar_validado("res://data/config/suspeita.json", "res://data/schemas/suspeita.schema.json")


## Maré básica, validada.
static func carregar_config_mare() -> Dictionary:
	return carregar_validado("res://data/config/mare.json", "res://data/schemas/mare.schema.json")


## Armas, bolsos (menu radial), círculo de sal e a criatura no campo (docs/06), validados.
static func carregar_config_armas() -> Dictionary:
	return carregar_validado("res://data/config/armas.json", "res://data/schemas/armas.schema.json")


## Itens de inventário, validados: {"dados": {id: definição}, "erros"}.
static func carregar_itens() -> Dictionary:
	var r := carregar_validado("res://data/items/itens.json", "res://data/schemas/itens.schema.json")
	var por_id := {}
	if r["dados"] is Dictionary:
		for item in r["dados"]["itens"]:
			por_id[item["id"]] = item
	return {"dados": por_id, "erros": r["erros"]}


## Caso tutorial com mentor (docs/02), validado.
static func carregar_config_tutorial() -> Dictionary:
	return carregar_validado("res://data/config/tutorial.json", "res://data/schemas/tutorial.schema.json")


## Arte e áudio gerados por código (docs/09), validados.
static func carregar_config_arte_e_audio() -> Dictionary:
	return carregar_validado("res://data/config/arte_e_audio.json", "res://data/schemas/arte_e_audio.schema.json")


## Criação de personagem: sliders, pele, cabelo, roupas e disfarces (docs/09), validada.
static func carregar_config_aparencia() -> Dictionary:
	return carregar_validado("res://data/config/aparencia.json", "res://data/schemas/aparencia.schema.json")


## Condições paranormais (docs/12, Parte B), validadas.
static func carregar_config_condicoes() -> Dictionary:
	return carregar_validado("res://data/config/condicoes.json", "res://data/schemas/condicoes.schema.json")


## Habilidades humanas (docs/12), validadas.
static func carregar_config_habilidades() -> Dictionary:
	return carregar_validado("res://data/config/habilidades.json", "res://data/schemas/habilidades.schema.json")


## Contorno de todas as regiões da cidade (mapa de viagem), validado.
static func carregar_mapa_geral() -> Dictionary:
	return carregar_validado("res://data/mapa/mapa_geral.json", "res://data/schemas/mapa_geral.schema.json")


## Progressão: dinheiro, reputação, qualidade, motel, carro e loja (docs/08), validados.
static func carregar_config_progressao() -> Dictionary:
	return carregar_validado("res://data/config/progressao.json", "res://data/schemas/progressao.schema.json")


## Mochila e porta-malas (docs/08), validados.
static func carregar_config_inventario() -> Dictionary:
	return carregar_validado("res://data/config/inventario.json", "res://data/schemas/inventario.schema.json")


## Negociação e apaziguamento (docs/06), validados.
static func carregar_config_negociacao() -> Dictionary:
	return carregar_validado("res://data/config/negociacao.json", "res://data/schemas/negociacao.schema.json")


## Rituais do confronto (docs/06), validados.
static func carregar_config_rituais() -> Dictionary:
	return carregar_validado("res://data/config/rituais.json", "res://data/schemas/rituais.schema.json")


## Confronto: estados da criatura, ferimentos e medo (docs/06), validados.
static func carregar_config_confronto() -> Dictionary:
	return carregar_validado("res://data/config/confronto.json", "res://data/schemas/confronto.schema.json")


## Pontos-chave (tipo de lugar -> nome, letra no minimapa, cor), validados um a um.
static func carregar_pontos_chave() -> Dictionary:
	var caminho_esquema := "res://data/schemas/pontos_chave.schema.json"
	var resultado := carregar_validado("res://data/config/pontos_chave.json", caminho_esquema)
	if not resultado["dados"] is Dictionary:
		return resultado
	var de_um := Esquema.new(ler_json(caminho_esquema)["$defs"]["ponto"])
	var tipos: Dictionary = resultado["dados"].get("tipos", {})
	for tipo in tipos:
		for erro in de_um.validate(tipos[tipo]):
			resultado["erros"].append("pontos_chave.json: %s: %s" % [tipo, erro])
	return resultado


## Transeuntes (figurantes nas ruas): quantos por hora e a que velocidade, validado.
static func carregar_config_transeuntes() -> Dictionary:
	return carregar_validado("res://data/config/transeuntes.json", "res://data/schemas/transeuntes.schema.json")


## O bairro real tem descrição abstrata (famílias, casas e lugares) em data/neighborhoods?
static func tem_bairro_abstrato(id_bairro: String) -> bool:
	return FileAccess.file_exists("res://data/neighborhoods/%s.json" % id_bairro)


## Medidas do subterrâneo dos bairros do mapa real, validadas.
static func carregar_config_subterraneo() -> Dictionary:
	return carregar_validado("res://data/config/subterraneo.json", "res://data/schemas/subterraneo.schema.json")


## Opções de visual (efeito PS1 ligado ou não), validadas.
static func carregar_config_visual() -> Dictionary:
	return carregar_validado("res://data/config/visual.json", "res://data/schemas/visual.schema.json")


## Kits de lotes por zona (gerador de lotes do mapa real), validados.
static func carregar_config_lotes() -> Dictionary:
	return carregar_validado("res://data/config/lotes.json", "res://data/schemas/lotes.schema.json")


## Ids dos bairros do mapa real que já foram importados, em ordem.
static func bairros_reais() -> Array[String]:
	var ids: Array[String] = []
	for caminho in _listar_json("res://data/cidade"):
		ids.append(caminho.get_file().get_basename())
	return ids


## Um módulo de cenário (res://data/modulos/<id>.json), validado.
static func carregar_modulo(id_modulo: String) -> Dictionary:
	var resultado := carregar_validado("res://data/modulos/%s.json" % id_modulo, "res://data/schemas/modulo.schema.json")
	if resultado["dados"] is Dictionary and resultado["dados"].get("id", "") != id_modulo:
		resultado["erros"].append("%s.json: o id precisa ser igual ao nome do arquivo" % id_modulo)
	if resultado["dados"] is Dictionary and resultado["dados"].get("tipo", "") == "tunel" and not resultado["dados"].has("comprimento"):
		resultado["erros"].append("%s.json: trecho de túnel precisa de comprimento" % id_modulo)
	return resultado


## Testes de campo e regras de desfecho, validados.
static func carregar_config_testes() -> Dictionary:
	return carregar_validado("res://data/config/testes_de_campo.json", "res://data/schemas/testes_de_campo.schema.json")


## Cartas e presentes depois do caso, validados.
static func carregar_textos_cartas() -> Dictionary:
	return carregar_validado("res://data/textos/cartas.json", "res://data/schemas/cartas.schema.json")


## Textos das marcas: {tag: {"pista": ..., "caracteristica": ...}}.
static func carregar_textos_marcas() -> Dictionary:
	var dados: Variant = ler_json("res://data/textos/marcas.json")
	if not dados is Dictionary:
		return {"dados": {}, "erros": ["res://data/textos/marcas.json: ausente ou inválido"] as Array[String]}
	var textos: Dictionary = dados.duplicate()
	textos.erase("$comment")
	return {"dados": textos, "erros": [] as Array[String]}


## Um bairro abstrato pelo id (res://data/neighborhoods/<id>.json), validado.
static func carregar_bairro(id_bairro: String) -> Dictionary:
	var resultado := carregar_validado("res://data/neighborhoods/%s.json" % id_bairro, "res://data/schemas/bairro.schema.json")
	if resultado["dados"] is Dictionary and resultado["dados"].get("id", "") != id_bairro:
		resultado["erros"].append("%s.json: o id precisa ser igual ao nome do arquivo" % id_bairro)
	return resultado


## Lê um arquivo JSON. Devolve null se não existir ou se não for JSON válido.
static func ler_json(caminho: String) -> Variant:
	if not FileAccess.file_exists(caminho):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(caminho)) != OK:
		return null
	return json.data


## Carrega todas as fichas de criatura.
## Devolve {"criaturas": {id: ficha}, "erros": ["arquivo: problema", ...]}.
static func carregar_criaturas(pasta: String = PASTA_CRIATURAS, caminho_esquema: String = ESQUEMA_CRIATURA) -> Dictionary:
	var resultado := {"criaturas": {}, "erros": [] as Array[String]}
	var esquema_dados: Variant = ler_json(caminho_esquema)
	if not esquema_dados is Dictionary:
		resultado["erros"].append("%s: esquema ausente ou inválido" % caminho_esquema)
		return resultado
	var esquema := Esquema.new(esquema_dados)

	for caminho in _listar_json(pasta):
		var ficha: Variant = ler_json(caminho)
		if not ficha is Dictionary:
			resultado["erros"].append("%s: não é um objeto JSON válido" % caminho)
			continue
		for erro in esquema.validate(ficha):
			resultado["erros"].append("%s: %s" % [caminho.get_file(), erro])
		var id: String = str(ficha.get("id", ""))
		if id != caminho.get_file().get_basename():
			resultado["erros"].append("%s: o id \"%s\" precisa ser igual ao nome do arquivo" % [caminho.get_file(), id])
		if resultado["criaturas"].has(id):
			resultado["erros"].append("%s: id repetido \"%s\"" % [caminho.get_file(), id])
		resultado["criaturas"][id] = ficha
	return resultado


static func _listar_json(pasta: String) -> Array[String]:
	var encontrados: Array[String] = []
	var dir := DirAccess.open(pasta)
	if dir == null:
		return encontrados
	for nome in dir.get_files():
		if nome.ends_with(".json"):
			encontrados.append(pasta.path_join(nome))
	encontrados.sort()
	return encontrados
