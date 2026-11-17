extends RefCounted
## Uma investigação em andamento (docs/05): o caso, o relógio do caçador e o caderno.
##
## Toda ação custa tempo (config investigacao.json), e as pistas vencem com o tempo: quem
## demora chega depois da chuva e não encontra as pegadas. O caçador começa na hora do
## contrato, com o equipamento inicial.
##
## Fase 1: ir a um lugar e examinar, e pesquisar registros. Entrevistas, testes de campo e
## confronto chegam nas próximas tarefas.

const Caderno := preload("res://core/caderno/caderno.gd")
const Pistas := preload("res://core/casos/pistas.gd")
const Solucionador := preload("res://core/casos/solucionador.gd")
const Bairro := preload("res://core/mundo/bairro.gd")

var caso: Dictionary
var caderno: RefCounted
var bairro: RefCounted
var minuto: int

var _cfg: Dictionary
var _local_atual := ""


func _init(caso_gerado: Dictionary, criaturas: Dictionary, dados_bairro: Dictionary, config_investigacao: Dictionary) -> void:
	caso = caso_gerado
	_cfg = config_investigacao
	bairro = Bairro.new(dados_bairro)
	minuto = int(caso["contrato"]["minuto"])
	var fichas := {}
	for id in Solucionador._candidatas(criaturas, dados_bairro["tipo"]):
		fichas[id] = criaturas[id]
	caderno = Caderno.new(fichas)
	caderno.definir_modo(_cfg["modo_padrao"])


## Lugares que dá para visitar (todos menos as casas), em ordem.
func locais() -> Array[String]:
	var lista: Array[String] = []
	for local in bairro.ids_locais():
		if bairro.local(local)["tipo"] != "casa":
			lista.append(local)
	return lista


func local_atual() -> String:
	return _local_atual


## Vai a um lugar e examina. Devolve {"ok", "erro", "novas": [ids], "minutos"}.
func ir(local: String) -> Dictionary:
	if not bairro.existe(local):
		return {"ok": false, "erro": "lugar desconhecido", "novas": [], "minutos": 0}
	var custo := int(_cfg["minutos_examinar_local"])
	if local != _local_atual:
		custo += int(_cfg["minutos_ir_ao_local"])
	minuto += custo
	_local_atual = local
	var novas: Array = []
	for pista in caso["pistas"]:
		if pista["tipo"] != "marca" or pista["local"] != local:
			continue
		if not _detectavel(pista) or not Pistas.disponivel(pista, minuto):
			continue
		if caderno.anotar_pista(pista):
			novas.append(pista["id"])
	return {"ok": true, "erro": "", "novas": novas, "minutos": custo}


## Pesquisa boletins e registros antigos (delegacia, cartório, jornal).
func pesquisar() -> Dictionary:
	var custo := int(_cfg["minutos_pesquisar_registros"])
	minuto += custo
	var novas: Array = []
	for pista in caso["pistas"]:
		if pista["tipo"] != "registro" or int(pista["minuto"]) > minuto:
			continue
		if not _detectavel(pista) or not Pistas.disponivel(pista, minuto):
			continue
		if caderno.anotar_pista(pista):
			novas.append(pista["id"])
	return {"ok": true, "erro": "", "novas": novas, "minutos": custo}


func _detectavel(pista: Dictionary) -> bool:
	return pista["detectar"] in _cfg["deteccao_inicial"]
