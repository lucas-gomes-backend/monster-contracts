extends RefCounted
## Caderno do caçador (docs/05): onde a dedução acontece.
##
##   Pistas     - o que o jogador encontrou (fatos, sem interpretação)
##   Pessoas    - quem falou e o que disse (depoimentos)
##   Hipóteses  - ligações "esta evidência" -> "esta característica do bestiário",
##                espécies riscadas, a espécie circulada e as respostas às três perguntas
##
## O caderno NÃO diz se uma ligação está certa: ligar uma pista à característica errada
## gera eliminações erradas. Interpretar é trabalho do jogador.
##
## Modos de ajuda (docs/05):
##   assistido - sugere as ligações óbvias
##   padrao    - filtra as espécies compatíveis com as ligações feitas
##   puro      - não filtra nada

const MODOS := ["assistido", "padrao", "puro"]
const PERGUNTAS := ["o_que", "quem", "por_que"]

var modo := "padrao"

var _especies: Dictionary = {}       # id -> {tag: true}
var _vocabulario: Dictionary = {}    # tag -> true (características que o bestiário mostra)
var _pistas: Dictionary = {}         # id -> pista
var _ordem_pistas: Array[String] = []
var _depoimentos: Dictionary = {}    # id -> depoimento
var _ordem_depoimentos: Array[String] = []
var _ligacoes: Dictionary = {}       # fonte -> [tags]
var _riscadas: Dictionary = {}
var _circulada := ""
var _respostas := {"o_que": "", "quem": "", "por_que": ""}


## "fichas": as espécies que o bestiário do jogador mostra (id -> ficha).
func _init(fichas: Dictionary) -> void:
	for id in fichas:
		var tags := {}
		for marca in fichas[id]["marcas"]:
			tags[marca["tag"]] = true
			_vocabulario[marca["tag"]] = true
		_especies[id] = tags


# --- Pistas e pessoas ---

## Anota uma pista. Devolve true se era nova.
func anotar_pista(pista: Dictionary) -> bool:
	if _pistas.has(pista["id"]):
		return false
	_pistas[pista["id"]] = pista.duplicate(true)
	_ordem_pistas.append(pista["id"])
	return true


## Anota um depoimento. Devolve true se era novo.
func anotar_depoimento(depoimento: Dictionary) -> bool:
	if _depoimentos.has(depoimento["id"]):
		return false
	_depoimentos[depoimento["id"]] = depoimento.duplicate(true)
	_ordem_depoimentos.append(depoimento["id"])
	return true


func pistas() -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for id in _ordem_pistas:
		lista.append(_pistas[id].duplicate(true))
	return lista


func depoimentos() -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for id in _ordem_depoimentos:
		lista.append(_depoimentos[id].duplicate(true))
	return lista


## Pessoas que já falaram: {npc_id: [ids de depoimento]}.
func pessoas() -> Dictionary:
	var resultado := {}
	for id in _ordem_depoimentos:
		var npc: String = _depoimentos[id]["npc"]
		if not resultado.has(npc):
			resultado[npc] = []
		resultado[npc].append(id)
	return resultado


# --- Hipóteses ---

## Liga uma evidência anotada (pista ou depoimento) a uma característica do bestiário.
## Devolve "" se deu certo, ou o motivo da recusa.
func ligar(fonte: String, tag: String) -> String:
	if not _pistas.has(fonte) and not _depoimentos.has(fonte):
		return "essa evidência não está no caderno"
	if not _vocabulario.has(tag):
		return "essa característica não está no bestiário"
	if not _ligacoes.has(fonte):
		_ligacoes[fonte] = []
	if not tag in _ligacoes[fonte]:
		_ligacoes[fonte].append(tag)
	return ""


func desligar(fonte: String, tag: String) -> void:
	if _ligacoes.has(fonte):
		_ligacoes[fonte].erase(tag)
		if _ligacoes[fonte].is_empty():
			_ligacoes.erase(fonte)


## Todas as características ligadas a alguma evidência, em ordem.
func tags_ligadas() -> Array:
	var tags := {}
	for fonte in _ligacoes:
		for tag in _ligacoes[fonte]:
			tags[tag] = true
	var lista := tags.keys()
	lista.sort()
	return lista


func ligacoes() -> Dictionary:
	return _ligacoes.duplicate(true)


## Espécies que ainda explicam todas as ligações feitas (no modo puro: todas).
func compativeis() -> Array:
	var ids := _especies.keys()
	ids.sort()
	if modo == "puro":
		return ids
	var ligadas := tags_ligadas()
	var resultado: Array = []
	for id in ids:
		var explica := true
		for tag in ligadas:
			if not _especies[id].has(tag):
				explica = false
				break
		if explica:
			resultado.append(id)
	return resultado


## Só no modo assistido: ligações óbvias ainda não feitas. [{fonte, tag}]
func sugestoes() -> Array:
	var resultado: Array = []
	if modo != "assistido":
		return resultado
	for id in _ordem_pistas:
		var tag: String = _pistas[id].get("tag", "")
		if _vocabulario.has(tag) and not tag in _ligacoes.get(id, []):
			resultado.append({"fonte": id, "tag": tag})
	for id in _ordem_depoimentos:
		for tag in _depoimentos[id].get("tags", []):
			if _vocabulario.has(tag) and not tag in _ligacoes.get(id, []):
				resultado.append({"fonte": id, "tag": tag})
	return resultado


func definir_modo(novo: String) -> bool:
	if not novo in MODOS:
		return false
	modo = novo
	return true


func riscar(especie: String) -> bool:
	if not _especies.has(especie):
		return false
	_riscadas[especie] = true
	if _circulada == especie:
		_circulada = ""
	return true


func desriscar(especie: String) -> void:
	_riscadas.erase(especie)


func riscadas() -> Array:
	var lista := _riscadas.keys()
	lista.sort()
	return lista


func circular(especie: String) -> bool:
	if not _especies.has(especie):
		return false
	_circulada = especie
	_riscadas.erase(especie)
	return true


func circulada() -> String:
	return _circulada


func responder(pergunta: String, resposta: String) -> bool:
	if not pergunta in PERGUNTAS:
		return false
	_respostas[pergunta] = resposta
	return true


func respostas() -> Dictionary:
	return _respostas.duplicate()


func especies() -> Array:
	var ids := _especies.keys()
	ids.sort()
	return ids


func caracteristicas_de(especie: String) -> Array:
	var tags: Array = _especies.get(especie, {}).keys()
	tags.sort()
	return tags


func vocabulario() -> Array:
	var tags := _vocabulario.keys()
	tags.sort()
	return tags


## Estado do caderno como dicionário (para salvar e para testes de determinismo).
func para_dicionario() -> Dictionary:
	return {
		"modo": modo,
		"pistas": _ordem_pistas.duplicate(),
		"depoimentos": _ordem_depoimentos.duplicate(),
		"ligacoes": _ligacoes.duplicate(true),
		"riscadas": riscadas(),
		"circulada": _circulada,
		"respostas": _respostas.duplicate(),
	}
