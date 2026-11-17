extends RefCounted
## Bairro abstrato (docs/07): lugares com tipo e rua. Na Fase 1 não há geometria,
## só a lista de lugares. As casas são criadas a partir do número de casas do bairro,
## distribuídas pelas ruas em rodízio (sem sorteio: o mesmo bairro tem sempre as mesmas casas).
##
## Lugares têm id completo "<bairro>/<lugar>", ex.: "paqueta/cemiterio", "paqueta/casa_03".

const FORA_DO_BAIRRO := "fora_do_bairro"

var dados: Dictionary
var id: String
var _locais: Dictionary = {}  # id completo -> {id, tipo, rua, nome}


func _init(dados_bairro: Dictionary) -> void:
	dados = dados_bairro
	id = dados_bairro["id"]
	for local in dados_bairro["locais"]:
		_adicionar(local["id"], local["tipo"], local["rua"], local["nome"])
	var ruas: Array = dados_bairro["ruas"]
	for i in int(dados_bairro["casas"]):
		_adicionar("casa_%02d" % (i + 1), "casa", ruas[i % ruas.size()], "Casa %d" % (i + 1))


func _adicionar(local_id: String, tipo: String, rua: String, nome: String) -> void:
	var completo := "%s/%s" % [id, local_id]
	_locais[completo] = {"id": completo, "tipo": tipo, "rua": rua, "nome": nome}


## Dados de um lugar (cópia), ou {} se não existir.
func local(id_completo: String) -> Dictionary:
	return _locais.get(id_completo, {}).duplicate()


func existe(id_completo: String) -> bool:
	return _locais.has(id_completo)


## Rua de um lugar, ou "" se o lugar não for deste bairro.
func rua_de(id_completo: String) -> String:
	return _locais.get(id_completo, {}).get("rua", "")


## Ids completos de todos os lugares de um tipo, em ordem.
func locais_do_tipo(tipo: String) -> Array[String]:
	var encontrados: Array[String] = []
	for local_id in ids_locais():
		if _locais[local_id]["tipo"] == tipo:
			encontrados.append(local_id)
	return encontrados


## Ids completos de todos os lugares, em ordem.
func ids_locais() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_locais.keys())
	ids.sort()
	return ids
