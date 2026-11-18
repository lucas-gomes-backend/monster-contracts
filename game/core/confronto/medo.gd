extends RefCounted
## Medo do caçador (docs/06). Sobe com a criatura por perto, a escuridão, ferimentos graves e
## sustos (eventos sobrenaturais); desce com luz, proteção e calma. Ferimento na cabeça faz
## subir mais rápido. Com medo alto, as mãos tremem (mira e ritual) e a lanterna falha.
## Tempos em segundos; o sorteio da lanterna vem de um stream do core/rng.gd.

const CALMO := "calmo"
const TENSO := "tenso"
const APAVORADO := "apavorado"

var valor: float = 0.0
var _cfg: Dictionary
var _g: RandomNumberGenerator


func _init(cfg_medo: Dictionary, g: RandomNumberGenerator) -> void:
	_cfg = cfg_medo
	_g = g


## situacao: {"criatura_metros": distância (INF = longe), "escuro": bool, "luz": bool,
##            "protegido": bool, "graves": int, "multiplicador": float (cabeça ferida)}
func passar(segundos: float, situacao: Dictionary) -> void:
	var sobe: Dictionary = _cfg["sobe_por_segundo"]
	var desce: Dictionary = _cfg["desce_por_segundo"]
	var subida := 0.0
	var perto := float(situacao.get("criatura_metros", INF)) <= float(_cfg["criatura_perto_metros"])
	if perto:
		subida += float(sobe["criatura_perto"])
	if situacao.get("escuro", false) and not situacao.get("luz", false):
		subida += float(sobe["escuro"])
	subida += float(sobe["por_ferimento_grave"]) * int(situacao.get("graves", 0))
	subida *= float(situacao.get("multiplicador", 1.0))
	var descida := 0.0
	if situacao.get("luz", false):
		descida += float(desce["luz"])
	if situacao.get("protegido", false):
		descida += float(desce["protecao"])
	if not perto and subida == 0.0:
		descida += float(desce["calmo"])
	valor = clampf(valor + (subida - descida) * segundos, 0.0, float(_cfg["maximo"]))


## Evento sobrenatural: um susto de uma vez.
func susto(multiplicador: float = 1.0) -> void:
	valor = minf(valor + float(_cfg["susto"]) * multiplicador, float(_cfg["maximo"]))


func nivel() -> String:
	var niveis: Dictionary = _cfg["niveis"]
	if valor >= float(niveis["apavorado"]):
		return APAVORADO
	if valor >= float(niveis["tenso"]):
		return TENSO
	return CALMO


## Tremor das mãos, de 0 (firme) a 1 (tremendo muito): oscila a mira e dificulta o ritual.
func tremor() -> float:
	var inicio := float(_cfg["tremor_a_partir"])
	var maximo := float(_cfg["maximo"])
	if valor <= inicio:
		return 0.0
	return (valor - inicio) / (maximo - inicio)


## A lanterna falha neste intervalo? Chance cresce com o medo (só a partir do tremor).
func lanterna_falha(segundos: float) -> bool:
	var chance := tremor() * float(_cfg["lanterna_falha_por_segundo_no_maximo"]) * segundos
	return chance > 0.0 and _g.randf() < chance
