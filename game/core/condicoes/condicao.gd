extends RefCounted
## Condição paranormal do caçador (docs/12, Parte B). Uma por vez, sem exceção: adquirir
## outra com uma já ativa é recusado (o conflito entre condições fica para depois).
## No corte vertical, só o Sensitivo:
##   - poderes: sente presenças (pela natureza da criatura, não diz qual é), vê espíritos
##     errantes e tem visões ao tocar pistas (psicometria);
##   - custo: exaustão mental. Sobe com visões e com espíritos por perto; no máximo, algo
##     toma o corpo (possessão) por alguns segundos. Cai devagar sozinha, de vez com descanso
##     ou benzedura; a proteção espiritual (figa e arruda) corta pela metade;
##   - estágios (Recente, Controlado, Dominante) sobem com o uso: mais alcance, mais custo.
## Fase 5: Vampirismo e Licantropia, pegos por mordida (pega_pela_mordida):
##   - vampirismo: enxerga no escuro (o escuro não dá medo), o sol fere na rua de dia;
##   - licantropia: faro (sente criaturas de qualquer natureza, sem dizer qual);
##   - estigma básico: quem vê o caçador de perto desconfia, mesmo limpo.
## Números em data/config/condicoes.json.

var id: String = ""
var usos: int = 0
var exaustao: float = 0.0
var possuido_por: float = 0.0  # segundos que faltam da possessão
var _cfg: Dictionary  # o config inteiro de condições


func _init(cfg_condicoes: Dictionary) -> void:
	_cfg = cfg_condicoes


func tem() -> bool:
	return not id.is_empty()


func sensitivo() -> bool:
	return id == "sensitivo"


## Adquire a condição. Recusa se já tiver outra (uma por vez). {"ok", "motivo"}
func adquirir(qual: String) -> Dictionary:
	if not _cfg.has(qual):
		return {"ok": false, "motivo": "não existe"}
	if tem():
		return {"ok": false, "motivo": "já é %s: uma condição por vez" % _cfg[id]["nome"]}
	id = qual
	usos = 0
	exaustao = 0.0
	return {"ok": true, "motivo": ""}


func _c() -> Dictionary:
	return _cfg[id] if tem() else {}


func estagio() -> Dictionary:
	if not tem():
		return {}
	if not _c().has("estagios"):
		return {"nome": "Recente"}
	var atual: Dictionary = _c()["estagios"][0]
	for e in _c()["estagios"]:
		if usos >= int(e["a_partir_de_usos"]):
			atual = e
	return atual


func nome() -> String:
	return "%s (%s)" % [_c()["nome"], estagio()["nome"]] if tem() else ""


## Sente esta criatura a esta distância? (só a presença, nunca a espécie)
func sente(ficha: Dictionary, metros: float) -> bool:
	if not tem() or not ficha.get("natureza", "") in _c()["sente_naturezas"]:
		return false
	if sensitivo():
		return metros <= float(estagio()["alcance_da_presenca"])
	return metros <= float(_c().get("alcance_do_faro", 0.0))


## A mordida passa a condição? Só ferimento grave ou crítico de uma criatura que transmite
## uma condição pega por mordida; "sorteio" (0 a 1) vem do stream do mundo. Devolve o id
## da condição ou "".
static func pega_pela_mordida(cfg_condicoes: Dictionary, ficha: Dictionary, gravidade: String, sorteio: float) -> String:
	if not gravidade in ["grave", "critico"]:
		return ""
	var qual = ficha.get("condicao_transmitida", null)
	if qual == null or not cfg_condicoes.has(str(qual)) or not cfg_condicoes[str(qual)].has("chance_por_mordida"):
		return ""
	return str(qual) if sorteio < float(cfg_condicoes[str(qual)]["chance_por_mordida"]) else ""


func enxerga_no_escuro() -> bool:
	return tem() and bool(_c().get("enxerga_no_escuro", false))


## De quantos em quantos minutos o sol fere quem está na rua de dia (0 = não fere).
func sol_fere_a_cada_minutos() -> int:
	return int(_c().get("sol_fere_a_cada_minutos", 0)) if tem() else 0


## Estigma básico: quanto quem vê o caçador de perto desconfia, mesmo limpo (0 = nada).
func fator_de_estigma() -> float:
	return float(_c().get("estigma_suspeita", 0.0)) if tem() else 0.0


## Usou um poder (sentiu uma presença nova, teve uma visão): conta para o estágio.
## Devolve se mudou de estágio.
func usar_poder(exaustao_extra: float = 0.0, protegido: bool = false) -> bool:
	if not tem():
		return false
	var antes: String = estagio()["nome"]
	usos += 1
	_cansar(exaustao_extra, protegido)
	return estagio()["nome"] != antes


## Visão por psicometria: cansa e conta como uso.
func visao(protegido: bool = false) -> bool:
	return usar_poder(float(_c()["exaustao_por_visao"]), protegido)


## O tempo passa: espíritos por perto cansam; sem eles, a exaustão cai devagar.
## Devolve true no instante em que a possessão começa.
func passar(segundos: float, espiritos_perto: int, protegido: bool) -> bool:
	if not sensitivo():
		return false
	if possuido_por > 0.0:
		possuido_por = maxf(0.0, possuido_por - segundos)
		return false
	if espiritos_perto > 0:
		_cansar(float(estagio()["exaustao_perto_de_espirito"]) * espiritos_perto * segundos, protegido)
	else:
		exaustao = maxf(0.0, exaustao - float(_c()["exaustao_cai_por_segundo"]) * segundos)
	if exaustao >= float(_c()["exaustao_maxima"]):
		possuido_por = float(_c()["possessao_segundos"])
		exaustao = float(_c()["exaustao_depois_da_possessao"])
		return true
	return false


func possuido() -> bool:
	return possuido_por > 0.0


## Descanso ou benzedura: tira a exaustão.
func aliviar(quanto: float) -> void:
	exaustao = maxf(0.0, exaustao - quanto)


func _cansar(quanto: float, protegido: bool) -> void:
	exaustao = minf(exaustao + quanto * (0.5 if protegido else 1.0), float(_c()["exaustao_maxima"]))


func texto() -> String:
	if not tem():
		return ""
	if not sensitivo():
		return nome()
	return "%s · exaustão %d%%" % [nome(), int(round(exaustao / float(_c()["exaustao_maxima"]) * 100.0))]
