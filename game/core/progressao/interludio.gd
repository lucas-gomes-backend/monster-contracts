extends RefCounted
## Interlúdio (docs/02, "Interlúdio"): o tempo entre um caso e outro. O jogador escolhe o
## tamanho do pulo e em que árvore treinar:
##   curto: pega o próximo caso rápido, quase não sara nem treina;
##   médio: sara e treina; longo: cura tudo e treina muito, mas envelhece mais.
## Paga a diária do motel por dia. A idade é um recurso: cada pulo aproxima a aposentadoria.
## Este arquivo só calcula; quem aplica no mundo é a cena (relógio, ferimentos, xp).
## Números em data/config/progressao.json ("interludio").

const MINUTOS_POR_DIA := 1440
const DIAS_POR_ANO := 365


static func pulos(cfg_progressao: Dictionary) -> Array:
	return cfg_progressao["interludio"]["pulos"]


static func custo(pulo: Dictionary, cfg_progressao: Dictionary) -> int:
	return int(pulo["dias"]) * int(cfg_progressao["interludio"]["diaria_no_interludio"])


## O que o pulo faz: {"minutos", "custo", "cura_graus", "treino_xp", "dias"}.
static func efeito(pulo: Dictionary, cfg_progressao: Dictionary) -> Dictionary:
	return {
		"dias": int(pulo["dias"]),
		"minutos": int(pulo["dias"]) * MINUTOS_POR_DIA,
		"custo": custo(pulo, cfg_progressao),
		"cura_graus": int(pulo["cura_graus"]),
		"treino_xp": int(pulo["treino_xp"]),
	}


## Idade em anos inteiros a partir dos dias vividos desde o começo da carreira.
static func idade(idade_inicial_anos: int, dias_vividos: int) -> int:
	return idade_inicial_anos + dias_vividos / DIAS_POR_ANO
