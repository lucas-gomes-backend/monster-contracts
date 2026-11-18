extends RefCounted
## Armas do caçador (docs/06, "Armas"): poucos tiros, recarga lenta, mira que treme com o
## medo e com o braço ferido. A arma não é o método final: ela entrega um item na criatura
## (sal, bala, lâmina benzida), que vale pelas fraquezas da ficha (core/confronto/estado_criatura.gd).
## Números em data/config/armas.json. O acerto é sorteado num stream do core/rng.gd.

var armas: Dictionary = {}  # id -> dados da arma
var ordem: Array[String] = []
var municao: Dictionary = {}  # id -> tiros na arma
var equipada: String = ""
var recarregando: float = 0.0
var _cfg: Dictionary
var _g: RandomNumberGenerator


func _init(cfg_armas: Dictionary, g: RandomNumberGenerator) -> void:
	_cfg = cfg_armas
	_g = g
	for arma in _cfg["armas"]:
		armas[arma["id"]] = arma
		ordem.append(arma["id"])
		municao[arma["id"]] = int(arma["capacidade"])
	equipada = ordem[0]


func arma() -> Dictionary:
	return armas[equipada]


func equipar(id: String) -> bool:
	if not armas.has(id) or recarregando > 0.0:
		return false
	equipada = id
	return true


## Arma branca não gasta munição.
func sem_municao() -> bool:
	return int(arma()["capacidade"]) > 0 and int(municao[equipada]) <= 0


func recarregar() -> bool:
	var a := arma()
	if int(a["capacidade"]) == 0 or recarregando > 0.0 or int(municao[equipada]) >= int(a["capacidade"]):
		return false
	recarregando = float(a["recarga"])
	return true


## O tempo passa: a recarga termina (o braço ferido deixa mais lenta: "lentidao" > 1).
func passar(segundos: float, lentidao: float = 1.0) -> void:
	if recarregando <= 0.0:
		return
	recarregando -= segundos / maxf(lentidao, 0.01)
	if recarregando <= 0.0:
		recarregando = 0.0
		municao[equipada] = int(arma()["capacidade"])


## Dispara (ou golpeia) na direção da mira. "para_o_alvo" é o vetor do caçador até a
## criatura (Vector3.ZERO = nada na frente). tremor (0 a 1, medo) e mira (>= 1, braço
## ferido) aumentam a dispersão.
## {"ok", "motivo", "acertou", "item", "barulho"}
func disparar(direcao: Vector3, para_o_alvo: Vector3, raio_do_alvo: float, tremor: float = 0.0, mira: float = 1.0) -> Dictionary:
	if recarregando > 0.0:
		return {"ok": false, "motivo": "recarregando", "acertou": false, "item": "", "barulho": 0.0}
	if sem_municao():
		return {"ok": false, "motivo": "sem munição", "acertou": false, "item": "", "barulho": 0.0}
	var a := arma()
	if int(a["capacidade"]) > 0:
		municao[equipada] = int(municao[equipada]) - 1
	var acertou := false
	var distancia := para_o_alvo.length()
	if distancia > 0.001 and distancia <= float(a["alcance"]) + raio_do_alvo:
		var abertura := rad_to_deg(atan2(raio_do_alvo, distancia))
		var desvio_da_mira := rad_to_deg(direcao.normalized().angle_to(para_o_alvo.normalized()))
		var dispersao := float(a["dispersao_graus"]) * mira * (1.0 + tremor * float(_cfg["tremor_multiplica_dispersao"]))
		# Arma branca: a "dispersão" é o arco do golpe; não é sorteada.
		var sorteio := 0.0 if int(a["capacidade"]) == 0 else _g.randf() * dispersao
		var limite := abertura + (dispersao if int(a["capacidade"]) == 0 else 0.0)
		acertou = desvio_da_mira + sorteio <= limite
	return {"ok": true, "motivo": "", "acertou": acertou, "item": a["item"], "barulho": float(a["barulho_metros"])}


func texto() -> String:
	var a := arma()
	if recarregando > 0.0:
		return "%s: recarregando" % a["nome"]
	if int(a["capacidade"]) == 0:
		return str(a["nome"])
	return "%s: %d/%d" % [a["nome"], int(municao[equipada]), int(a["capacidade"])]
