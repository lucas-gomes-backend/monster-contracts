extends RefCounted
## Maré básica (docs/07, "Marés"): Santos tem maré semidiurna, que sobe e desce duas vezes
## por dia. Altura em metros reais, num ciclo de cosseno com fase fixa (uma preamar de
## referência). Na maré bem alta, as galerias do esgoto alagam.

const Relogio := preload("res://core/tempo/relogio.gd")

var periodo: int
var media: float
var amplitude: float
var limite_alagada: float
var _referencia: int


func _init(config: Dictionary) -> void:
	periodo = int(config["periodo_minutos"])
	media = float(config["media"])
	amplitude = float(config["amplitude"])
	limite_alagada = float(config["galerias_alagadas"])
	var r: Dictionary = config["preamar_de_referencia"]
	_referencia = Relogio.minutos_de(int(r["ano"]), int(r["mes"]), int(r["dia"]), int(r["hora"]), int(r["minuto"]))


## Altura da maré no minuto (metros).
func altura(minuto: int) -> float:
	var fase := float(posmod(minuto - _referencia, periodo)) / float(periodo)
	return media + amplitude * cos(TAU * fase)


## De 0 (baixa-mar) a 1 (preamar).
func fracao(minuto: int) -> float:
	return clampf((altura(minuto) - (media - amplitude)) / maxf(2.0 * amplitude, 0.001), 0.0, 1.0)


func subindo(minuto: int) -> bool:
	return altura(minuto + 1) > altura(minuto)


func galerias_alagadas(minuto: int) -> bool:
	return altura(minuto) >= limite_alagada


## O minuto da próxima preamar (maré alta) a partir de agora.
func proxima_preamar(minuto: int) -> int:
	return minuto + posmod(_referencia - minuto, periodo)
