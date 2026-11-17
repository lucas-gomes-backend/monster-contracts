extends RefCounted
## Carrega e valida o conteúdo em JSON (rules/implementacao.md: conteúdo é dado).
## Os arquivos são lidos em ordem alfabética, para o resultado ser sempre o mesmo.

const Esquema := preload("res://core/dados/esquema.gd")

const PASTA_CRIATURAS := "res://data/creatures"
const ESQUEMA_CRIATURA := "res://data/schemas/criatura.schema.json"


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
