extends RefCounted
## Círculo de sal (docs/06, "Proteções"): uma zona segura temporária. Barra a criatura que tem
## o sal entre as fraquezas (o corpo-seco, por exemplo); as outras passam. Desgasta com o
## tempo, mais rápido com chuva e com a criatura pressionando a linha.

var centro: Vector2
var raio: float
var restante: float
var _cfg: Dictionary


func _init(onde: Vector2, cfg_circulo: Dictionary) -> void:
	centro = onde
	_cfg = cfg_circulo
	raio = float(cfg_circulo["raio"])
	restante = float(cfg_circulo["dura"])


func ativo() -> bool:
	return restante > 0.0


func dentro(ponto: Vector2) -> bool:
	return ativo() and ponto.distance_to(centro) <= raio


## A criatura não atravessa a linha se o sal é fraqueza dela.
static func barra(ficha: Dictionary) -> bool:
	for fraqueza in ficha["fraquezas"]:
		if fraqueza["item"] == "sal_grosso":
			return true
	return false


func passar(segundos: float, chovendo: bool = false, pressionado: bool = false) -> void:
	var ritmo := 1.0
	if chovendo:
		ritmo *= float(_cfg["desgaste_com_chuva"])
	if pressionado:
		ritmo *= float(_cfg["desgaste_com_a_criatura_pressionando"])
	restante = maxf(0.0, restante - segundos * ritmo)
