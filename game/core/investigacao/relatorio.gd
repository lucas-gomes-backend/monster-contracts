extends RefCounted
## Relatório do caso (docs/05, "O relatório do caso"): compara o que o caçador acreditava com
## o que era verdade. Mostra TODA a verdade, para o erro virar aprendizado:
##   - a criatura, quem era e por quê;
##   - as pistas da criatura que o caçador encontrou e as que perdeu (e por quê perdeu);
##   - as ligações certas e as erradas no caderno;
##   - quem mentiu, por quê, e se a mentira foi descoberta;
##   - o que era ruído;
##   - quanto tempo levou e se passou do prazo.

const MOTIVO_EQUIPAMENTO := "exigia equipamento que você ainda não tem"
const MOTIVO_ANTES_DO_CONTRATO := "já tinha sumido antes de você ser contratado"
const MOTIVO_NAO_FOI := "você não foi até esse lugar"
const MOTIVO_SUMIU := "sumiu antes de você chegar (o tempo ou a chuva apagaram)"
const MOTIVO_NAO_PESQUISOU := "você não pesquisou os registros"


static func gerar(sessao: RefCounted, criaturas: Dictionary, gatilhos: Dictionary) -> Dictionary:
	var caso: Dictionary = sessao.caso
	var verdade: Dictionary = caso["verdade"]
	var contrato: Dictionary = caso["contrato"]
	var ficha: Dictionary = criaturas[verdade["especie"]]
	var deteccao: Array = sessao._cfg["deteccao_inicial"]

	var anotadas := {}
	for p in sessao.caderno.pistas():
		anotadas[p["id"]] = true
	var ouvidos := {}
	for d in sessao.caderno.depoimentos():
		ouvidos[d["id"]] = true

	# Pistas da criatura: encontradas e perdidas.
	var encontradas: Array = []
	var perdidas: Array = []
	for pista in caso["pistas"]:
		if pista["origem"] != "criatura" or pista["tipo"] == "testemunho":
			continue
		if anotadas.has(pista["id"]):
			encontradas.append(pista["id"])
		else:
			perdidas.append({"id": pista["id"], "motivo": _motivo_perdida(pista, sessao, int(contrato["minuto"]), deteccao)})

	# Ligações do caderno: certas quando a evidência é mesmo aquela marca.
	var marcas_da_fonte := {}
	for p in sessao.caderno.pistas():
		marcas_da_fonte[p["id"]] = [p.get("tag", "")]
	for d in sessao.caderno.depoimentos():
		marcas_da_fonte[d["id"]] = d["tags"]
	var certas: Array = []
	var erradas: Array = []
	var ligacoes: Dictionary = sessao.caderno.ligacoes()
	var fontes := ligacoes.keys()
	fontes.sort()
	for fonte in fontes:
		for tag in ligacoes[fonte]:
			(certas if tag in marcas_da_fonte.get(fonte, []) else erradas).append({"fonte": fonte, "tag": tag})

	# Mentiras.
	var mentiras: Array = []
	for dep in caso["depoimentos"]:
		if dep["mentira"].is_empty():
			continue
		mentiras.append({
			"depoimento": dep["id"],
			"npc": dep["npc"],
			"tipo": dep["mentira"]["tipo"],
			"motivo": dep["mentira"]["motivo"],
			"verdade": dep["mentira"]["verdade"],
			"sobre": dep["relato"].get("sobre", ""),
			"ouvida": ouvidos.has(dep["id"]),
			"descoberta": ouvidos.has("%s_verdade" % dep["id"]),
		})

	# Ruído.
	var ruido: Array = []
	for evento in caso["registro"].buscar("ruido.ocorreu"):
		var anotou := 0
		for pista in caso["pistas"]:
			if int(pista["causa"]) == int(evento["id"]) and anotadas.has(pista["id"]):
				anotou += 1
		ruido.append({"ruido": evento["dados"]["ruido"], "local": evento["local"], "minuto": evento["minuto"], "pistas_anotadas": anotou})

	# Depoimentos.
	var sobre_hospedeiro_nao_ouvidos := 0
	for dep in caso["depoimentos"]:
		if dep["tipo"] == "ausencia" and not ouvidos.has(dep["id"]):
			sobre_hospedeiro_nao_ouvidos += 1

	return {
		"desfecho": sessao.desfecho.duplicate(),
		"verdade": {
			"especie": verdade["especie"],
			"nome": ficha["nome"],
			"hospedeiro": verdade["hospedeiro"],
			"estrutura": caso["estrutura"],
			"gatilho": verdade["gatilho"],
			"por_que": gatilhos.get(verdade["gatilho"], verdade["gatilho"].replace("_", " ")),
			"npc_ligado": verdade["npc_ligado"],
		},
		"tempo": {
			"minutos_gastos": int(sessao.minuto) - int(contrato["minuto"]),
			"passou_do_prazo": int(sessao.minuto) > int(contrato["prazo_minuto"]),
		},
		"pistas": {"encontradas": encontradas, "perdidas": perdidas},
		"ligacoes": {"certas": certas, "erradas": erradas},
		"mentiras": mentiras,
		"ruido": ruido,
		"depoimentos": {
			"ouvidos": sessao.caderno.depoimentos().size(),
			"total": caso["depoimentos"].size(),
			"sobre_o_hospedeiro_nao_ouvidos": sobre_hospedeiro_nao_ouvidos,
		},
	}


static func _motivo_perdida(pista: Dictionary, sessao: RefCounted, contrato_min: int, deteccao: Array) -> String:
	if not pista["detectar"] in deteccao:
		return MOTIVO_EQUIPAMENTO
	var vence := int(pista["valida_ate"])
	if vence >= 0 and vence <= contrato_min:
		return MOTIVO_ANTES_DO_CONTRATO
	if pista["tipo"] == "registro":
		return MOTIVO_NAO_PESQUISOU
	if not sessao.visitas.has(pista["local"]):
		return MOTIVO_NAO_FOI
	return MOTIVO_SUMIU
