extends RefCounted
## Rotina dos NPCs (docs/07): onde cada um está em qualquer minuto.
##
## SEM ESTADO: a resposta depende só do NPC, do minuto e da semente do mundo. Por isso dá
## para perguntar "onde o seu Manoel estava às 23h de quinta?" em qualquer ordem e
## sempre receber a mesma resposta. É isso que permite álibis e testemunhas coerentes.
##
## Ordem de prioridade: trabalho -> sono -> lazer (sorteado por dia) -> em casa.

const Janela := preload("res://core/tempo/janela.gd")
const Relogio := preload("res://core/tempo/relogio.gd")
const Bairro := preload("res://core/mundo/bairro.gd")

var _config: Dictionary
var _rng_mundo: RefCounted
var _bairro: RefCounted


func _init(config_populacao: Dictionary, rng_mundo: RefCounted, bairro: RefCounted) -> void:
	_config = config_populacao
	_rng_mundo = rng_mundo
	_bairro = bairro


## {"local": id completo ou "fora_do_bairro", "atividade": "trabalhando" | "dormindo" | "lazer" | "em_casa"}
func onde_esta(npc: Dictionary, minuto: int) -> Dictionary:
	var ocupacao: Dictionary = npc.get("ocupacao", {})
	if not npc.get("trabalho", "").is_empty() and Janela.dentro(minuto, int(ocupacao["inicio"]), int(ocupacao["fim"]), ocupacao["dias"]):
		return {"local": npc["trabalho"], "atividade": "trabalhando"}

	var sono := horario_de_sono(npc)
	if Janela.dentro(minuto, sono[0], sono[1]):
		return {"local": npc["casa"], "atividade": "dormindo"}

	var lazer: Dictionary = _config["lazer"]
	if Janela.dentro(minuto, int(lazer["janela"][0]), int(lazer["janela"][1])):
		var dia: int = minuto / Relogio.MINUTOS_POR_DIA
		var sorteio: RandomNumberGenerator = _rng_mundo.stream("rotina:%s:%d" % [npc["id"], dia])
		if sorteio.randf() < float(lazer["chance"]):
			var destino := _destino_de_lazer(npc)
			if not destino.is_empty():
				return {"local": destino, "atividade": "lazer"}

	return {"local": npc["casa"], "atividade": "em_casa"}


## [inicio, fim] do sono deste NPC.
func horario_de_sono(npc: Dictionary) -> Array:
	var sono: Dictionary = _config["sono"]
	var faixa: Array = sono["padrao"]
	if npc.get("ocupacao", {}).has("sono"):
		faixa = npc["ocupacao"]["sono"]
	elif "notivago" in npc["tracos"]:
		faixa = sono["notivago"]
	elif int(npc["idade"]) < 12:
		faixa = sono["crianca"]
	elif int(npc["idade"]) >= int(_config["idade_aposentado"]):
		faixa = sono["aposentado"]
	return [int(faixa[0]), int(faixa[1])]


func _destino_de_lazer(npc: Dictionary) -> String:
	var lazer: Dictionary = _config["lazer"]
	var tipo: String = lazer["padrao"]
	for traco in npc["tracos"]:
		if lazer["por_traco"].has(traco):
			tipo = lazer["por_traco"][traco]
			break
	var opcoes: Array[String] = _bairro.locais_do_tipo(tipo)
	return opcoes[0] if not opcoes.is_empty() else ""
