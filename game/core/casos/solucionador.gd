extends RefCounted
## Solucionador automático (docs/04, passo 8): joga o caso como um caçador INICIANTE e diz
## se ele é justo. Usa só o que o iniciante tem:
##   - pistas ainda disponíveis na hora do contrato (core/casos/pistas.gd);
##   - pistas detectáveis com o equipamento inicial (olho nu, entrevista, pesquisa);
##   - depoimentos (o que as testemunhas contam, com as marcas que mencionam).
##
## Regras de dedução (as mesmas que o jogador usa no caderno, docs/05):
##   - só existe UMA criatura por caso;
##   - uma marca que pertence ao vocabulário de alguma espécie precisa ser explicada pela
##     criatura do caso; marcas que nenhuma espécie deixa são ruído e são ignoradas;
##   - então uma espécie é descartada se alguma evidência tem uma marca que ela não deixa.
##
## O caso é JUSTO quando:
##   1. sobra exatamente a espécie verdadeira;
##   2. cada outra espécie é descartada por pelo menos 2 evidências diferentes
##      (perder uma pista não trava o caso);
##   3. se a criatura tem hospedeiro humano, há pelo menos 2 depoimentos que apontam para ele.

const Pistas := preload("res://core/casos/pistas.gd")
const Relogio := preload("res://core/tempo/relogio.gd")

const DETECCAO_INICIAL := ["olho_nu", "entrevista", "pesquisa"]
const MINIMO_EVIDENCIAS := 2
## Um padrão só existe com pelo menos 2 boletins: um boletim sozinho é coincidência.
const MINIMO_BOLETINS_PADRAO := 2

## Padrões que só aparecem juntando boletins de ocorrência (marcas de registro "sobre evento").
const PADROES_DE_BOLETIM := {
	"ataques_noite_quinta_sexta": ["quinta", "sexta"],
}


## Os tipos de lugar de um bairro abstrato (data/neighborhoods), sem repetir, em ordem.
static func tipos_de_locais(dados_bairro: Dictionary) -> Array:
	var tipos: Array = []
	for local in dados_bairro["locais"]:
		if not local["tipo"] in tipos:
			tipos.append(local["tipo"])
	tipos.sort()
	return tipos


## A criatura pode viver neste bairro? Coringa, tipo de bairro da ficha, ou um lugar do
## bairro que serve de covil para ela (o Curupira mora em qualquer área verde).
static func vive_no_bairro(ficha: Dictionary, tipo_bairro: String, tipos_de_locais: Array = []) -> bool:
	var bairros: Array = ficha["bairros"]
	if "coringa" in bairros or tipo_bairro in bairros:
		return true
	for covil in ficha.get("covil", []):
		if covil in tipos_de_locais:
			return true
	return false


## {"valido": bool, "motivos": [...], "candidatos": [...], "evidencias": [...]}
## tipos_de_locais: os tipos de lugar do bairro (para os covis; ver vive_no_bairro).
static func validar(caso: Dictionary, criaturas: Dictionary, tipo_bairro: String, tipos_de_locais: Array = []) -> Dictionary:
	var motivos: Array[String] = []
	var especie: String = caso["verdade"]["especie"]
	var candidatas := _candidatas(criaturas, tipo_bairro, tipos_de_locais)
	var vocabulario := {}
	for id in candidatas:
		for tag in _tags(criaturas[id]):
			vocabulario[tag] = true

	var evidencias := coletar_evidencias(caso)
	var restantes: Array = []
	for id in candidatas:
		var tags_especie := _tags(criaturas[id])
		var descartada_por: Array = []
		for ev in evidencias:
			if vocabulario.has(ev["tag"]) and not tags_especie.has(ev["tag"]):
				descartada_por.append(ev["fonte"])
		if descartada_por.is_empty():
			restantes.append(id)
		elif id != especie and _distintas(descartada_por) < MINIMO_EVIDENCIAS:
			motivos.append("%s descartada por só %d evidência(s)" % [id, _distintas(descartada_por)])

	if not especie in restantes:
		motivos.append("a espécie verdadeira (%s) foi descartada pelas evidências" % especie)
	if restantes.size() != 1:
		motivos.append("sobraram %d candidatas: %s" % [restantes.size(), ", ".join(restantes)])

	var hospedeiro: String = caso["verdade"]["hospedeiro"]
	if not hospedeiro.is_empty():
		var apontam := 0
		for dep in caso["depoimentos"]:
			if dep["tipo"] == "ausencia" and dep["relato"].get("quem_saiu", "") == hospedeiro:
				apontam += 1
			elif dep["tipo"] == "alibi" and dep["relato"].get("sobre", "") == hospedeiro:
				apontam += 1
		if apontam < MINIMO_EVIDENCIAS:
			motivos.append("só %d depoimento(s) apontam para o hospedeiro" % apontam)

	# Culpado humano: o crime precisa de quem viu o culpado sair de casa naquelas noites.
	var culpado: String = caso["verdade"].get("culpado", "")
	if not culpado.is_empty():
		var contra := 0
		for dep in caso["depoimentos"]:
			if dep["tipo"] == "ausencia" and dep["relato"].get("quem_saiu", "") == culpado:
				contra += 1
		if contra < MINIMO_EVIDENCIAS:
			motivos.append("só %d depoimento(s) apontam para o culpado" % contra)

	return {"valido": motivos.is_empty(), "motivos": motivos, "candidatos": restantes, "evidencias": evidencias}


## Tudo o que um iniciante consegue juntar na hora do contrato: [{"fonte", "tag"}].
static func coletar_evidencias(caso: Dictionary) -> Array:
	var minuto: int = caso["contrato"]["minuto"]
	var evidencias: Array = []
	var boletins: Array = []
	for pista in caso["pistas"]:
		if not Pistas.disponivel(pista, minuto) or not pista["detectar"] in DETECCAO_INICIAL:
			continue
		if pista.has("tag") and pista["tipo"] != "testemunho":
			evidencias.append({"fonte": pista["id"], "tag": pista["tag"]})
		if pista["tipo"] == "registro" and not pista.has("tag"):
			boletins.append(pista)
	for dep in caso["depoimentos"]:
		for tag in dep["tags"]:
			evidencias.append({"fonte": dep["id"], "tag": tag})
	for tag in PADROES_DE_BOLETIM:
		var dias: Array = PADROES_DE_BOLETIM[tag]
		var noites_certas := 0
		for boletim in boletins:
			var ataque: Dictionary = caso["registro"].obter(int(boletim["causa"]))
			if Relogio.new(int(ataque["minuto"])).noite_entre(dias[0], dias[1]):
				noites_certas += 1
		if noites_certas >= MINIMO_BOLETINS_PADRAO and noites_certas == boletins.size():
			evidencias.append({"fonte": "padrao_de_boletins", "tag": tag})
	return evidencias


static func _candidatas(criaturas: Dictionary, tipo_bairro: String, tipos_de_locais: Array) -> Array:
	var ids := criaturas.keys()
	ids.sort()
	var candidatas: Array = []
	for id in ids:
		if vive_no_bairro(criaturas[id], tipo_bairro, tipos_de_locais):
			candidatas.append(id)
	return candidatas


static func _tags(ficha: Dictionary) -> Dictionary:
	var tags := {}
	for marca in ficha["marcas"]:
		tags[marca["tag"]] = true
	return tags


static func _distintas(fontes: Array) -> int:
	var unicas := {}
	for f in fontes:
		unicas[f] = true
	return unicas.size()
