extends RefCounted
## Quem presenciou o quê (docs/04, "Testemunhas"). Ouve o barramento e, para cada evento
## presenciável num lugar do bairro, pergunta à rotina onde cada NPC estava naquele minuto:
##
##   no mesmo lugar e acordado            -> "viu"
##   na mesma rua e acordado              -> "ouviu"
##   na mesma rua, dormindo, sono leve    -> "ouviu"
##
## Cada memória vira um evento "npc.presenciou" (com "evento_origem") e entra na lista de
## memórias do NPC. O filtro de percepção (distância, luz, medo...) vem na tarefa de
## testemunhas; aqui fica só o fato de ter presenciado.
##
## Assina o barramento, então chame barramento.encerrar() ao descartar (evita ciclo).

var _npcs: Array
var _rotina: RefCounted
var _bairro: RefCounted
var _barramento: RefCounted
var _tipos: Array


func _init(npcs: Array, rotina: RefCounted, bairro: RefCounted, barramento: RefCounted, tipos_presenciaveis: Array) -> void:
	_npcs = npcs
	_rotina = rotina
	_bairro = bairro
	_barramento = barramento
	_tipos = tipos_presenciaveis
	barramento.assinar("*", _ao_evento)


func _ao_evento(evento: Dictionary) -> void:
	if not evento["tipo"] in _tipos:
		return
	var rua_evento: String = _bairro.rua_de(evento["local"])
	if rua_evento.is_empty():
		return
	for npc in _npcs:
		var posicao: Dictionary = _rotina.onde_esta(npc, evento["minuto"])
		var acordado: bool = posicao["atividade"] != "dormindo"
		var modo := ""
		if posicao["local"] == evento["local"] and acordado:
			modo = "viu"
		elif _bairro.rua_de(posicao["local"]) == rua_evento and (acordado or "sono_leve" in npc["tracos"]):
			modo = "ouviu"
		if modo.is_empty():
			continue
		npc["memorias"].append({"evento_origem": evento["id"], "modo": modo, "minuto": evento["minuto"]})
		_barramento.publicar(evento["minuto"], "npc.presenciou", npc["id"], posicao["local"], {
			"evento_origem": evento["id"],
			"modo": modo,
			"atividade": posicao["atividade"],
		})
