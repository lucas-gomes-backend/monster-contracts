extends RefCounted
## Ferimentos localizados do caçador (docs/06): sem barra de vida. Cada parte do corpo tem
## gravidade nenhum / leve / grave / crítico. Ferimentos se somam (dois leves viram grave,
## dois graves viram crítico). Um crítico sem tratamento mata depois de um tempo, mais rápido
## na cabeça e no tronco. Tratar (bandagem, tala) desce um degrau.
##
## Efeitos (modificadores): perna -> velocidade; tronco -> fôlego (corrida); braço -> mira e
## ritual (o dominante pesa mais); cabeça -> medo sobe mais rápido e visão turva.
## Leve vale uma fração do grave; crítico vale como grave.

const NENHUM := 0
const LEVE := 1
const GRAVE := 2
const CRITICO := 3
const NOMES := ["nenhum", "leve", "grave", "critico"]

var gravidade: Dictionary = {}  # parte -> 0..3
var _leves: Dictionary = {}  # parte -> leves acumulados desde o último degrau
var _graves: Dictionary = {}
var _critico_ha: Dictionary = {}  # parte -> segundos desde que ficou crítico
var morto: bool = false
var causa_da_morte: String = ""
var dominante: String = "braco_direito"
## Quanto mais tempo o crítico leva para matar (habilidade Resistência).
var tempo_do_critico: float = 1.0
var _cfg: Dictionary


func _init(cfg_ferimentos: Dictionary) -> void:
	_cfg = cfg_ferimentos
	for parte in _cfg["partes"]:
		gravidade[parte] = NENHUM
		_leves[parte] = 0
		_graves[parte] = 0


## Recebe um ferimento numa parte: "leve", "grave" ou "critico".
func receber(parte: String, tipo: String) -> void:
	if morto or not gravidade.has(parte):
		return
	var nivel: int = NOMES.find(tipo)
	if nivel <= NENHUM:
		return
	if nivel == LEVE:
		_leves[parte] += 1
		if _leves[parte] >= int(_cfg["leves_viram_grave"]):
			_leves[parte] = 0
			nivel = GRAVE
	if nivel == GRAVE and gravidade[parte] >= GRAVE:
		_graves[parte] += 1
		if _graves[parte] + 1 >= int(_cfg["graves_viram_critico"]):
			nivel = CRITICO
	if nivel > gravidade[parte]:
		gravidade[parte] = nivel
	if gravidade[parte] == CRITICO and not _critico_ha.has(parte):
		_critico_ha[parte] = 0.0


## Bandagem ou tala: desce um degrau (crítico -> grave -> leve -> nenhum).
func tratar(parte: String) -> void:
	if morto or not gravidade.has(parte) or gravidade[parte] == NENHUM:
		return
	gravidade[parte] -= 1
	_leves[parte] = 0
	_graves[parte] = 0
	if gravidade[parte] < CRITICO:
		_critico_ha.erase(parte)


## O tempo passa: um crítico sem tratamento mata.
func passar(segundos: float) -> void:
	if morto:
		return
	var partes := _critico_ha.keys()
	partes.sort()
	for parte in partes:
		_critico_ha[parte] += segundos
		if _critico_ha[parte] >= float(_cfg["critico_mata_em"][parte]) * tempo_do_critico:
			morto = true
			causa_da_morte = parte
			return


## Segundos até morrer pelo crítico mais urgente (-1 = nenhum crítico).
func tempo_ate_morrer() -> float:
	var menor := -1.0
	for parte in _critico_ha:
		var falta: float = float(_cfg["critico_mata_em"][parte]) * tempo_do_critico - float(_critico_ha[parte])
		if menor < 0.0 or falta < menor:
			menor = falta
	return menor


func graves() -> int:
	var n := 0
	for parte in gravidade:
		if gravidade[parte] >= GRAVE:
			n += 1
	return n


## Multiplicadores para o corpo: velocidade e fôlego (< 1 piora), mira, ritual e medo (> 1
## piora), visão turva (0 a 1).
func modificadores() -> Dictionary:
	var m := {"velocidade": 1.0, "folego": 1.0, "mira": 1.0, "ritual": 1.0, "medo": 1.0, "visao_turva": 0.0}
	var tabela: Dictionary = _cfg["grave"]
	var partes := gravidade.keys()
	partes.sort()
	for parte in partes:
		var nivel: int = gravidade[parte]
		if nivel == NENHUM:
			continue
		var peso: float = float(_cfg["peso_do_leve"]) if nivel == LEVE else 1.0
		var grupo: String = parte.split("_")[0]
		if grupo == "braco" and parte != dominante:
			peso *= float(_cfg["peso_do_braco_que_nao_e_o_dominante"])
		var efeitos: Dictionary = tabela[grupo]
		for chave in efeitos:
			var alvo: float = float(efeitos[chave])
			if chave == "visao_turva":
				m[chave] = maxf(m[chave], alvo * peso)
			else:
				# Interpola de 1 (sem efeito) até o valor do grave, pelo peso.
				m[chave] = m[chave] * lerpf(1.0, alvo, peso)
	return m


func texto() -> String:
	var partes: Array = []
	for parte in _cfg["partes"]:
		if gravidade[parte] > NENHUM:
			partes.append("%s (%s)" % [parte.replace("_", " "), NOMES[gravidade[parte]].replace("critico", "crítico")])
	return ", ".join(partes) if not partes.is_empty() else "nenhum"
