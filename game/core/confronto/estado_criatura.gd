extends RefCounted
## Estados da criatura no confronto (docs/06): sem barra de vida. A criatura passa por
## livre -> contida -> vulnerável -> resolvida, pelo EFEITO das fraquezas da ficha:
##   prende: contida | fere ou revela: vulnerável | afasta: afastada (livre, mas recua)
##   destrói, cura, bane: método final, só quando vulnerável | apazigua: método final
## A contenção e a vulnerabilidade se desgastam com o tempo e voltam a livre.
## Usar o que não é fraqueza não faz nada e deixa a criatura mais agressiva.
## Tempos em segundos (data/config/confronto.json).

const LIVRE := "livre"
const CONTIDA := "contida"
const VULNERAVEL := "vulneravel"
const RESOLVIDA := "resolvida"

var ficha: Dictionary
var estado: String = LIVRE
var agressividade: int = 0
## Segundos que faltam para a contenção, a vulnerabilidade ou o recuo acabarem.
var restante: float = 0.0
var afastada: float = 0.0
var resolucao: String = ""
var _cfg: Dictionary


func _init(ficha_da_criatura: Dictionary, cfg_criatura: Dictionary) -> void:
	ficha = ficha_da_criatura
	_cfg = cfg_criatura


## Efeitos que o item tem nesta criatura (pelas fraquezas da ficha), em ordem.
func efeitos_do_item(item: String) -> Array:
	var efeitos: Array = []
	for fraqueza in ficha["fraquezas"]:
		if fraqueza["item"] == item:
			for efeito in fraqueza["efeito"]:
				if not efeito in efeitos:
					efeitos.append(efeito)
	return efeitos


## Usa um item na criatura. {"efeito": o que pegou ("" = nada), "estado": novo estado}
func usar(item: String) -> Dictionary:
	if estado == RESOLVIDA:
		return {"efeito": "", "estado": estado}
	var efeitos := efeitos_do_item(item)
	if efeitos.is_empty():
		agressividade = mini(agressividade + 1, int(_cfg["agressividade_maxima"]))
		return {"efeito": "", "estado": estado}
	# O método final vence, se a criatura estiver no estado que ele pede.
	for efeito in efeitos:
		if _cfg["finais"].has(efeito) and _pode_resolver(str(_cfg["finais"][efeito])):
			estado = RESOLVIDA
			resolucao = efeito
			restante = 0.0
			return {"efeito": efeito, "estado": estado}
	# Senão, o efeito que leva mais longe (vulnerável > contida > afastada).
	for alvo in [VULNERAVEL, CONTIDA, "afastada"]:
		for efeito in efeitos:
			if _cfg["efeito_leva_a"].get(efeito, "") == alvo:
				_entrar(alvo)
				return {"efeito": efeito, "estado": estado}
	return {"efeito": "", "estado": estado}


## O tempo passa: contenção, vulnerabilidade e recuo se desgastam.
func passar(segundos: float) -> void:
	if afastada > 0.0:
		afastada = maxf(0.0, afastada - segundos)
	if estado in [CONTIDA, VULNERAVEL]:
		restante -= segundos
		if restante <= 0.0:
			restante = 0.0
			estado = LIVRE


## Ritual errado (docs/06, "Erros no ritual"): o efeito é o contrário. Ela se liberta e se
## enfurece.
func enfurecer() -> void:
	if estado == RESOLVIDA:
		return
	estado = LIVRE
	restante = 0.0
	agressividade = int(_cfg["agressividade_maxima"])


func esta_afastada() -> bool:
	return afastada > 0.0


func _pode_resolver(exige: String) -> bool:
	match exige:
		VULNERAVEL:
			return estado == VULNERAVEL
		CONTIDA:
			return estado in [CONTIDA, VULNERAVEL]
	return true


func _entrar(alvo: String) -> void:
	var duracao: Dictionary = _cfg["duracao"]
	if alvo == "afastada":
		afastada = float(duracao["afastada"])
		return
	# Ferir uma criatura solta interrompe o ataque, mas a janela é a mesma.
	estado = alvo
	restante = float(duracao[alvo])
