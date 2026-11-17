extends RefCounted
## Estatísticas de um lote de casos gerados (docs/04, "Gerador em lote").
## Serve para enxergar o gerador como um todo: quantos casos saem justos, quantas
## tentativas custam, por que tentativas são descartadas, e o "tamanho" típico de um caso.
##
## Números com fração são arredondados a 4 casas, para o resultado ser comparável entre
## máquinas e caber numa referência (game/tests/baselines/lote.json).

const CASAS := 0.0001


## Resume uma lista de casos (como devolvidos por gerador_casos.gerar).
static func resumir(casos: Array) -> Dictionary:
	var validos: Array = []
	var tentativas: Array = []
	var descartes := {}
	var estruturas := {}
	var especies := {}
	for caso in casos:
		for descarte in caso.get("descartes", []):
			for motivo in descarte["motivos"]:
				var chave := resumir_motivo(motivo)
				descartes[chave] = int(descartes.get(chave, 0)) + 1
		if not caso.get("valido", false):
			continue
		validos.append(caso)
		tentativas.append(int(caso["tentativa"]) + 1)
		_contar(estruturas, caso["estrutura"])
		_contar(especies, caso["verdade"]["especie"])

	var pistas: Array = []
	var depoimentos: Array = []
	var ruidos: Array = []
	var boletins: Array = []
	var evidencias: Array = []
	var pistas_por_tipo := {}
	var mentiras := {}
	var com_chuva := 0
	for caso in validos:
		pistas.append(caso["pistas"].size())
		depoimentos.append(caso["depoimentos"].size())
		ruidos.append(caso["registro"].buscar("ruido.ocorreu").size())
		boletins.append(caso["registro"].buscar("registro.boletim").size())
		evidencias.append(caso.get("validacao", {}).get("evidencias", []).size())
		for pista in caso["pistas"]:
			_contar(pistas_por_tipo, "%s/%s" % [pista["tipo"], pista["origem"]])
		for dep in caso["depoimentos"]:
			if not dep["mentira"].is_empty():
				_contar(mentiras, dep["mentira"]["tipo"])
		if int(caso["previsao"]["chuva_em"]) >= 0:
			com_chuva += 1

	var n := validos.size()
	var media_por_tipo := {}
	for chave in pistas_por_tipo:
		media_por_tipo[chave] = _arredondar(float(pistas_por_tipo[chave]) / maxi(n, 1))
	var primeira := 0
	for t in tentativas:
		if t == 1:
			primeira += 1

	return {
		"casos": casos.size(),
		"validos": n,
		"taxa_validos": _arredondar(float(n) / maxi(casos.size(), 1)),
		"tentativas": {"media": _media(tentativas), "maximo": _maximo(tentativas), "primeira_tentativa": _arredondar(float(primeira) / maxi(n, 1))},
		"descartes": descartes,
		"estruturas": estruturas,
		"especies": especies,
		"pistas": {"media": _media(pistas), "minimo": _minimo(pistas), "maximo": _maximo(pistas), "por_tipo": media_por_tipo},
		"depoimentos": {"media": _media(depoimentos), "minimo": _minimo(depoimentos), "maximo": _maximo(depoimentos)},
		"mentiras": mentiras,
		"ruidos": {"media": _media(ruidos)},
		"boletins": {"media": _media(boletins)},
		"evidencias_do_iniciante": {"media": _media(evidencias), "minimo": _minimo(evidencias)},
		"chuva": _arredondar(float(com_chuva) / maxi(n, 1)),
	}


## Motivo de descarte sem o nome da espécie e sem números, para agrupar.
## "corpo_seco descartada por só 1 evidência(s)" -> "<espécie> descartada por só N evidência(s)"
static func resumir_motivo(motivo: String) -> String:
	var regex := RegEx.new()
	regex.compile("^[a-z_]+ descartada")
	var texto := regex.sub(motivo, "<espécie> descartada")
	regex.compile("\\([a-z]+_[a-z_]+\\)")  # ids têm "_"; "(s)" de "evidência(s)" não é espécie
	texto = regex.sub(texto, "(<espécie>)", true)
	regex.compile("[0-9]+")
	texto = regex.sub(texto, "N", true)
	regex.compile(": .*$")
	return regex.sub(texto, "")


static func _contar(contagem: Dictionary, chave: String) -> void:
	contagem[chave] = int(contagem.get(chave, 0)) + 1


static func _media(valores: Array) -> float:
	if valores.is_empty():
		return 0.0
	var soma := 0
	for v in valores:
		soma += int(v)
	return _arredondar(float(soma) / valores.size())


static func _minimo(valores: Array) -> int:
	return int(valores.min()) if not valores.is_empty() else 0


static func _maximo(valores: Array) -> int:
	return int(valores.max()) if not valores.is_empty() else 0


static func _arredondar(x: float) -> float:
	return snappedf(x, CASAS)
