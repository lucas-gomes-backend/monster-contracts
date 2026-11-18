extends RefCounted
## Morte simples (docs/13, Parte C, "Escopo"): até a arena do limbo existir, morrer é
## "voltar com custo". Cada volta pesa mais que a anterior: tempo perdido (o mundo segue),
## envelhecimento (o limbo rouba vida), parte do equipamento da mochila fica no limbo e a
## marca do limbo acumula (os espíritos notam mais: o medo sobe mais rápido).
## Este arquivo só calcula; quem aplica no mundo é a cena. Números em data/config/morte.json.

const Rng := preload("res://core/rng.gd")
const MINUTOS_POR_DIA := 1440


## O custo da volta número "volta" (1 = a primeira):
## {"dias_perdidos", "minutos", "dias_envelhecidos", "fracao_perdida"}.
static func custo(volta: int, cfg: Dictionary) -> Dictionary:
	var extra := maxi(volta - 1, 0)
	var dias := int(cfg["dias_perdidos"]) + extra * int(cfg["dias_perdidos_por_volta"])
	var fracao := minf(float(cfg["fracao_do_equipamento"]) + extra * float(cfg["fracao_por_volta"]), float(cfg["fracao_maxima"]))
	return {
		"dias_perdidos": dias,
		"minutos": dias * MINUTOS_POR_DIA,
		"dias_envelhecidos": int(cfg["dias_envelhecidos"]) + extra * int(cfg["dias_envelhecidos_por_volta"]),
		"fracao_perdida": fracao,
	}


## Quais pilhas (o "n" das entradas da grade) ficam no limbo: arredonda para cima, então
## com fração > 0 sempre se perde ao menos uma. Sorteio pelo stream "limbo" da volta.
static func perdidos(entradas: Array, fracao: float, semente: int, volta: int) -> Array[int]:
	var ns: Array[int] = []
	for e in entradas:
		ns.append(int(e["n"]))
	ns.sort()
	var g: RandomNumberGenerator = Rng.new(semente).stream("limbo_%d" % volta)
	for i in range(ns.size() - 1, 0, -1):
		var j := g.randi_range(0, i)
		var t := ns[i]
		ns[i] = ns[j]
		ns[j] = t
	var quantos := mini(int(ceil(ns.size() * fracao)), ns.size())
	return ns.slice(0, quantos)


## Quanto a marca do limbo multiplica o medo.
static func multiplicador_do_medo(marca: int, cfg: Dictionary) -> float:
	return 1.0 + float(marca) * float(cfg["medo_por_marca"])
