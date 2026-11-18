extends RefCounted
## Psicometria do Sensitivo (docs/12): tocar uma pista dá uma visão do que a deixou.
## A visão é VAGA, como todo poder: o tamanho, o som e a hora, nunca a forma nem o nome.
## Serve para separar o que é ruído (uma briga de bar soa como briga) do que não é, sem dar
## a resposta do caso (regra de ouro do docs/12).

const Relogio := preload("res://core/tempo/relogio.gd")

const TAMANHOS := {"pequeno": "algo pequeno", "medio": "alguém do tamanho de uma pessoa", "grande": "algo grande", "enorme": "algo enorme", "gigante": "algo gigantesco"}


## O observável que deixou a pista: de uma criatura, de um ruído ou de um crime.
static func observavel(caso: Dictionary, pista: Dictionary, criaturas: Dictionary, cfg_casos: Dictionary) -> Dictionary:
	var causa: Dictionary = caso["registro"].obter(int(pista.get("causa", -1)))
	match causa.get("tipo", ""):
		"criatura.ataque", "historia.gatilho":
			return criaturas.get(causa["dados"].get("especie", caso["verdade"]["especie"]), {}).get("observavel", {})
		"ruido.ocorreu":
			for r in cfg_casos["ruidos"]:
				if r["id"] == causa["dados"].get("ruido", ""):
					return r["observavel"]
		"humano.crime":
			for c in cfg_casos.get("crimes", []):
				if c["id"] == causa["dados"].get("crime", ""):
					return c["observavel"]
	return {}


## Texto da visão. Sem observável (registro de papel, por exemplo), nada vem.
static func visao(caso: Dictionary, pista: Dictionary, criaturas: Dictionary, cfg_casos: Dictionary) -> String:
	var o := observavel(caso, pista, criaturas, cfg_casos)
	if o.is_empty():
		return "Você toca e não sente nada: isso não guardou nenhum momento."
	var causa: Dictionary = caso["registro"].obter(int(pista.get("causa", -1)))
	var quando := "de noite" if Relogio.new(int(causa.get("minuto", 0))).eh_noite() else "de dia"
	return "Ao tocar, o mundo some por um instante. É %s. Você ouve %s e sente %s ali perto." % [quando, o.get("som", "um barulho"), TAMANHOS.get(o.get("tamanho", ""), "alguma coisa")]
