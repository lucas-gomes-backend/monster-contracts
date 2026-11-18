extends RefCounted
## Pistas de um caso, derivadas do registro de eventos (docs/04, "Pistas").
##
## Nenhuma pista é inventada: cada uma é a leitura de um evento do registro.
##   marca.depositada  -> pista "marca"      (cena, corpo, ambiente, covil)
##   npc.presenciou    -> pista "testemunho" (quem viu ou ouviu)
##   registro.boletim  -> pista "registro"   (boletim de ocorrência)
##
## Cada pista guarda:
##   evento  : o id do evento que a gerou (proveniência)
##   causa   : o id do evento que a CAUSOU (o ataque ou o ruído)
##   origem  : "criatura" ou "ruido" (o jogador NÃO vê isto; serve ao validador e ao relatório)
##   valida_ate : minuto em que a pista some (-1 = não expira). Pistas de cena somem antes
##                se chover (a chuva apaga pegadas).


## Devolve a lista de pistas, em ordem de evento.
static func derivar(registro: RefCounted, validade_horas: Dictionary, chuva_em: int) -> Array[Dictionary]:
	var pistas: Array[Dictionary] = []
	for evento in registro.buscar():
		var pista := {}
		match evento["tipo"]:
			"marca.depositada":
				pista = {
					"tipo": "marca",
					"tag": evento["dados"]["tag"],
					"onde": evento["dados"]["onde"],
					"detectar": evento["dados"]["detectar"],
				}
			"npc.presenciou":
				pista = {
					"tipo": "testemunho",
					"npc": evento["ator"],
					"modo": evento["dados"]["modo"],
					"onde": "testemunha",
					"detectar": "entrevista",
				}
			"npc.notou_ausencia":
				pista = {
					"tipo": "testemunho",
					"npc": evento["ator"],
					"modo": "notou_ausencia",
					"sobre": evento["dados"]["quem"],
					"tag": evento["dados"]["tag"],
					"onde": "testemunha",
					"detectar": "entrevista",
				}
			"registro.boletim":
				pista = {"tipo": "registro", "onde": "registro", "detectar": "pesquisa"}
			"historia.registro":
				pista = {"tipo": "registro", "tag": evento["dados"]["tag"], "onde": "registro", "detectar": "pesquisa"}
			_:
				continue
		var causa: Dictionary = registro.obter(int(evento["dados"]["evento_origem"]))
		pista["id"] = "pista_%03d" % pistas.size()
		pista["evento"] = evento["id"]
		pista["causa"] = causa.get("id", -1)
		pista["origem"] = "criatura" if causa.get("tipo", "") in ["criatura.ataque", "historia.gatilho"] else ("crime" if causa.get("tipo", "") == "humano.crime" else "ruido")
		pista["local"] = evento["local"]
		pista["minuto"] = evento["minuto"]
		pista["valida_ate"] = validade(pista["onde"], evento["minuto"], validade_horas, chuva_em)
		pistas.append(pista)
	return pistas


## Minuto em que uma pista criada em "minuto" deixa de existir (-1 = nunca).
static func validade(onde: String, minuto: int, validade_horas: Dictionary, chuva_em: int) -> int:
	var horas := int(validade_horas.get(onde, -1))
	if horas < 0:
		return -1
	var fim := minuto + horas * 60
	if onde == "cena" and chuva_em >= 0 and chuva_em > minuto:
		fim = mini(fim, chuva_em)
	return fim


## A pista ainda existe neste minuto?
static func disponivel(pista: Dictionary, minuto: int) -> bool:
	return int(pista["valida_ate"]) < 0 or minuto < int(pista["valida_ate"])
