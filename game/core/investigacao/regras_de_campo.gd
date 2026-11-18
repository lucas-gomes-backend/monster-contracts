extends RefCounted
## Testes de campo (docs/05) e desfecho do caso (docs/06), resolvidos por REGRAS na Fase 1.
##
## Tudo sai das fraquezas e resoluções da ficha da criatura verdadeira: não há resultado
## escrito à mão. Um teste dá positivo quando a criatura tem uma fraqueza com o item do teste
## e um dos efeitos esperados (ou é do tipo que o teste pega: "positivo_se", pela natureza ou
## família da ficha, como o EMF e a câmera térmica), E o alvo é o certo (o hospedeiro, ou um lugar que ela frequenta).
## Testar a pessoa errada dá negativo sem descartar a criatura (docs/05).

const Criatura := preload("res://core/criaturas/criatura.gd")
const Rng := preload("res://core/rng.gd")
const Barramento := preload("res://core/eventos/barramento.gd")

const MINUTOS_POR_DIA := 1440


## O teste dá positivo para este alvo, dada a verdade do caso?
static func positivo(teste: Dictionary, ficha_verdade: Dictionary, verdade: Dictionary, alvo: String) -> bool:
	var tem_fraqueza := false
	for fraqueza in ficha_verdade["fraquezas"]:
		if not fraqueza["item"] in teste["itens"]:
			continue
		for efeito in fraqueza["efeito"]:
			if efeito in teste["efeitos_positivos"]:
				tem_fraqueza = true
	if not tem_fraqueza and not _pega_pelo_que_e(teste, ficha_verdade):
		return false
	if teste["alvo"] == "pessoa":
		return not alvo.is_empty() and alvo == verdade["hospedeiro"]
	return alvo in verdade["locais"]


## EMF e câmera térmica: pegam a criatura pela natureza ou pela família, não por fraqueza.
static func _pega_pelo_que_e(teste: Dictionary, ficha: Dictionary) -> bool:
	var regra: Dictionary = teste.get("positivo_se", {})
	if ficha.get("natureza", "") in regra.get("natureza", []):
		return true
	for familia in ficha.get("familia", []):
		if familia in regra.get("familia", []):
			return true
	return false


## Minuto em que o resultado do teste aparece (a manhã seguinte à espera).
static func minuto_do_resultado(teste: Dictionary, agora: int, ficha_verdade: Dictionary, config_criaturas: Dictionary, cfg: Dictionary) -> int:
	var hora := int(cfg["hora_do_resultado"])
	var momento := agora
	if teste["espera"] == "proxima_janela_da_criatura":
		var criatura := Criatura.new(ficha_verdade, "teste", Rng.new(0), Barramento.new(), config_criaturas, [])
		var achou := false
		for h in int(cfg["espera_maxima_dias"]) * 24:
			var m := agora + h * 60
			if criatura.em_janela(m):
				momento = m
				achou = true
				break
		if not achou:
			momento = agora + int(cfg["espera_maxima_dias"]) * MINUTOS_POR_DIA
	var dia_seguinte: int = momento / MINUTOS_POR_DIA + 1
	return dia_seguinte * MINUTOS_POR_DIA + hora * 60


## A criatura percebeu o teste? Determinístico pela semente do caso e o número do teste.
static func percebeu(ficha_verdade: Dictionary, cfg: Dictionary, sub_semente: int, numero_do_teste: int) -> bool:
	var chance := float(cfg["chance_de_perceber"][ficha_verdade["inteligencia"]])
	var g: RandomNumberGenerator = Rng.new(sub_semente).stream("teste_de_campo:%d" % numero_do_teste)
	return g.randf() < chance


## Desfecho do caso: o caçador AGE com base no que acredita (docs/05, "Decisão").
##   resolucao: matar, banir, prender, curar, apaziguar, negociar, expor ou abandonar
##   especie:   a espécie em que o caçador aposta
##   alvo:      a pessoa (hospedeiro), quando a resolução precisa de "quem"
## Devolve {"ok", "erro", ...} ou o resultado: sucesso, especie_certa, quem_certo,
## inocente_prejudicado, amaldicoado_morto, recompensa, motivo.
## "minuto_atual": quando o caçador age. Depois do prazo do contrato, o cliente já desistiu:
## o caso pode até ser resolvido, mas não há pagamento (docs/04, "O caso pode falhar sozinho").
static func decidir(resolucao: String, especie: String, alvo: String, caso: Dictionary, fichas: Dictionary, cfg: Dictionary, minuto_atual: int = -1) -> Dictionary:
	var verdade: Dictionary = caso["verdade"]
	var base := {"ok": true, "erro": "", "resolucao": resolucao, "especie": especie, "alvo": alvo,
		"sucesso": false, "especie_certa": false, "quem_certo": false, "inocente_prejudicado": "",
		"amaldicoado_morto": false, "recompensa": 0, "motivo": "",
		"prazo_estourado": minuto_atual > int(caso["contrato"]["prazo_minuto"])}
	if resolucao == "abandonar":
		base["motivo"] = "Você abandonou o caso."
		return base
	if not fichas.has(especie):
		return {"ok": false, "erro": "espécie desconhecida"}
	var ficha: Dictionary = fichas[especie]
	if not resolucao in ficha["resolucoes"]:
		return {"ok": false, "erro": "pelo bestiário, %s não se resolve com '%s'" % [ficha["nome"], resolucao]}
	var precisa_quem: bool = resolucao in cfg["resolucoes_que_exigem_quem"] and ficha.has("hospedeiro")
	if precisa_quem and alvo.is_empty():
		return {"ok": false, "erro": "diga quem: essa resolução precisa da pessoa certa"}

	var verdadeira: Dictionary = fichas.get(verdade["especie"], {})
	base["especie_certa"] = especie == verdade["especie"]
	base["quem_certo"] = not precisa_quem or alvo == verdade["hospedeiro"]
	if not alvo.is_empty() and alvo != verdade["hospedeiro"] and resolucao in ["matar", "prender", "expor"]:
		base["inocente_prejudicado"] = alvo

	if not base["especie_certa"]:
		base["motivo"] = "As fraquezas de %s não funcionam: a criatura era outra." % ficha["nome"]
	elif not resolucao in verdadeira.get("resolucoes", []):
		base["motivo"] = "A criatura certa, mas essa resolução não funciona com ela."
	elif not base["quem_certo"]:
		base["motivo"] = "A criatura certa, mas a pessoa errada."
	else:
		base["sucesso"] = true
		base["motivo"] = "Resolvido."
		base["amaldicoado_morto"] = resolucao == "matar" and "amaldicoado" in verdadeira.get("familia", [])
		if resolucao in cfg["resolucoes_que_encerram_os_ataques"] and not base["prazo_estourado"]:
			base["recompensa"] = int(caso["contrato"]["recompensa"])
	return base
