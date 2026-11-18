extends RefCounted
## Suspeita da polícia e do público (docs/07, "Polícia e suspeita"). Pontos inteiros por
## bairro e uma suspeita geral da cidade, que recebe metade de tudo. O nível num bairro é o
## pior entre a dele e a geral: normal, observado, procurado ou barrado.
## A suspeita cai um pouco a cada hora. Quem sai do esgoto fica sujo por um tempo, e cada
## minuto em que alguém o vê sujo soma pontos (docs/07, "Sujeira").

const NORMAL := "normal"
const OBSERVADO := "observado"
const PROCURADO := "procurado"
const BARRADO := "barrado"

var _sobra: Dictionary = {}  # bairro -> fração de ponto ainda não somada
var geral: int = 0
## [{"minuto", "bairro", "pontos", "motivo"}]
var historico: Array[Dictionary] = []
var _cfg: Dictionary
var _pontos: Dictionary = {}
var _sujo_ate: int = -1
var _minutos_sem_queda: int = 0


func _init(config: Dictionary) -> void:
	_cfg = config


func pontos(bairro: String) -> int:
	return int(_pontos.get(bairro, 0))


## Soma (ou tira, com n negativo) pontos de suspeita num bairro.
func somar(bairro: String, n: int, motivo: String, minuto: int) -> void:
	_pontos[bairro] = maxi(0, pontos(bairro) + n)
	geral = maxi(0, geral + n / 2)
	historico.append({"minuto": minuto, "bairro": bairro, "pontos": n, "motivo": motivo})


## O nível no bairro: o pior entre a suspeita dele e a geral.
func nivel(bairro: String) -> String:
	return nivel_de(maxi(pontos(bairro), geral))


func nivel_de(valor: int) -> String:
	var niveis: Dictionary = _cfg["niveis"]
	if valor >= int(niveis["barrado"]):
		return BARRADO
	if valor >= int(niveis["procurado"]):
		return PROCURADO
	if valor >= int(niveis["observado"]):
		return OBSERVADO
	return NORMAL


## O tempo passou: a cada hora cheia, a suspeita cai em todo bairro e na geral.
func passar_minutos(minutos: int) -> void:
	_minutos_sem_queda += minutos
	var queda := int(_cfg["queda_por_hora"])
	while _minutos_sem_queda >= 60:
		_minutos_sem_queda -= 60
		for bairro in _pontos:
			_pontos[bairro] = maxi(0, int(_pontos[bairro]) - queda)
		geral = maxi(0, geral - queda)


## Saiu do esgoto: fica sujo (roupa e cheiro) por um tempo.
func sujar(minuto: int) -> void:
	_sujo_ate = minuto + int(_cfg["sujeira"]["duracao_minutos"])


func sujo(minuto: int) -> bool:
	return minuto < _sujo_ate


## Alguém o viu neste minuto. Se estiver sujo, soma pontos. Devolve quantos somou.
## "fator": um disfarce faz quem vê desconfiar menos (0,5 = metade). A sobra fracionária
## fica guardada por bairro, para os pontos continuarem inteiros.
func visto(bairro: String, minuto: int, fator: float = 1.0) -> int:
	if not sujo(minuto):
		return 0
	var exato: float = float(_cfg["sujeira"]["pontos_por_minuto_visto"]) * fator + float(_sobra.get(bairro, 0.0))
	var n := int(floor(exato))
	_sobra[bairro] = exato - n
	if n > 0:
		somar(bairro, n, "visto sujo do esgoto", minuto)
	return n


## Foi detido: a suspeita do bairro e a geral caem até o valor da detenção.
func detido(bairro: String, minuto: int) -> void:
	var depois := int(_cfg["detencao"]["suspeita_depois"])
	_pontos[bairro] = mini(pontos(bairro), depois)
	geral = mini(geral, depois)
	_sujo_ate = -1
	historico.append({"minuto": minuto, "bairro": bairro, "pontos": 0, "motivo": "detido"})
