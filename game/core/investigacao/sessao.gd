extends RefCounted
## Uma investigação em andamento (docs/05): o caso, o relógio do caçador e o caderno.
##
## Toda ação custa tempo (config investigacao.json), e as pistas vencem com o tempo: quem
## demora chega depois da chuva e não encontra as pegadas. O caçador começa na hora do
## contrato, com o equipamento inicial.
##
## Fase 1: ir a um lugar e examinar, pesquisar registros, entrevistar quem está por perto e
## confrontar um depoimento com uma prova. Testes de campo e confronto com a criatura chegam
## nas próximas tarefas.

const Caderno := preload("res://core/caderno/caderno.gd")
const Pistas := preload("res://core/casos/pistas.gd")
const Solucionador := preload("res://core/casos/solucionador.gd")
const Bairro := preload("res://core/mundo/bairro.gd")
const Rotina := preload("res://core/npcs/rotina.gd")
const Rng := preload("res://core/rng.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")
const RegrasDeCampo := preload("res://core/investigacao/regras_de_campo.gd")
const Psicometria := preload("res://core/condicoes/psicometria.gd")
const Cartas := preload("res://core/casos/cartas.gd")

var caso: Dictionary
var caderno: RefCounted
var bairro: RefCounted
var minuto: int
## Quantas vezes o caçador acusou alguém sem razão (docs/05, "Suspeita").
var suspeita := 0

var _cfg: Dictionary
var _local_atual := ""
var _rotina: RefCounted
var _npcs: Dictionary = {}
var _fechados: Dictionary = {}       # npc -> true: não fala mais com o caçador
var _entrevistados: Dictionary = {}  # npc -> true
## A criatura percebeu que está sendo testada (docs/03, "Reação ao caçador").
var criatura_alertada := false
## Resultado final do caso, depois de agir (vazio enquanto a investigação continua).
var desfecho: Dictionary = {}

var _fichas: Dictionary = {}
var _ficha_verdade: Dictionary
var _cfg_testes: Dictionary
var _cfg_criaturas: Dictionary
var _testes_feitos := 0
## Para o relatório: primeira visita a cada lugar (minuto) e se os registros foram pesquisados.
var visitas: Dictionary = {}
## Condição Sensitivo (docs/12): pode tocar as pistas anotadas (psicometria), uma vez cada.
var sensitivo := false
var _tocadas: Dictionary = {}
var pesquisou := false


func _init(caso_gerado: Dictionary, criaturas: Dictionary, dados_bairro: Dictionary, config_investigacao: Dictionary) -> void:
	caso = caso_gerado
	_cfg = config_investigacao
	bairro = Bairro.new(dados_bairro)
	minuto = int(caso["contrato"]["minuto"])
	var fichas := {}
	for id in Solucionador._candidatas(criaturas, dados_bairro["tipo"], Solucionador.tipos_de_locais(dados_bairro)):
		fichas[id] = criaturas[id]
	caderno = Caderno.new(fichas)
	caderno.definir_modo(_cfg["modo_padrao"])
	# A rotina é refeita com a mesma semente do caso: as pessoas estão onde estariam.
	_rotina = Rotina.new(Catalogo.carregar_config_populacao()["dados"], Rng.new(int(caso["sub_semente"])), bairro)
	for npc in caso["npcs"]:
		_npcs[npc["id"]] = npc
	_fichas = fichas
	_cfg_testes = Catalogo.carregar_config_testes()["dados"]
	_cfg_criaturas = Catalogo.carregar_config_criaturas()["dados"]
	_ficha_verdade = criaturas[caso["verdade"]["especie"]]


func encerrado() -> bool:
	return not desfecho.is_empty()


func testes_disponiveis() -> Array:
	return _cfg_testes["testes"]


## Faz um teste de campo num alvo (pessoa ou lugar). O tempo avança até a manhã do resultado.
## {"ok", "erro", "positivo", "teste", "alvo", "percebeu", "reacao", "minutos"}
func aplicar_teste(teste_id: String, alvo: String) -> Dictionary:
	var teste: Dictionary = {}
	for t in _cfg_testes["testes"]:
		if t["id"] == teste_id:
			teste = t
	if teste.is_empty():
		return {"ok": false, "erro": "teste desconhecido"}
	if teste["alvo"] == "pessoa" and not _npcs.has(alvo):
		return {"ok": false, "erro": "esse teste é feito numa pessoa"}
	if teste["alvo"] == "local" and not bairro.existe(alvo):
		return {"ok": false, "erro": "esse teste é feito num lugar"}
	var antes := minuto
	minuto = RegrasDeCampo.minuto_do_resultado(teste, minuto, _ficha_verdade, _cfg_criaturas, _cfg_testes)
	_testes_feitos += 1
	var percebeu := RegrasDeCampo.percebeu(_ficha_verdade, _cfg_testes, int(caso["sub_semente"]), _testes_feitos)
	if percebeu:
		criatura_alertada = true
	return {
		"ok": true,
		"erro": "",
		"teste": teste,
		"alvo": alvo,
		"positivo": RegrasDeCampo.positivo(teste, _ficha_verdade, caso["verdade"], alvo),
		"percebeu": percebeu,
		"reacao": _cfg_criaturas["reacao_por_inteligencia"][_ficha_verdade["inteligencia"]] if percebeu else "",
		"minutos": minuto - antes,
	}


## Encerra o caso agindo (docs/05, "Decisão"). Depois disso, a investigação acaba.
func agir(resolucao: String, especie: String, alvo: String = "") -> Dictionary:
	if encerrado():
		return {"ok": false, "erro": "o caso já foi encerrado"}
	var todas: Dictionary = Catalogo.carregar_criaturas()["criaturas"]
	var resultado := RegrasDeCampo.decidir(resolucao, especie, alvo, caso, todas, _cfg_testes, minuto)
	if resultado["ok"]:
		desfecho = resultado
	return resultado


## Cartas e presentes que chegam depois do caso (core/casos/cartas.gd). Vazio enquanto aberto.
func cartas() -> Array[Dictionary]:
	if not encerrado():
		return [] as Array[Dictionary]
	return Cartas.gerar(caso, desfecho, Catalogo.carregar_criaturas()["criaturas"], bairro.dados,
		Catalogo.carregar_textos_cartas()["dados"], _cfg_testes["resolucoes_que_encerram_os_ataques"])


## Lugares que dá para visitar (todos menos as casas), em ordem.
func locais() -> Array[String]:
	var lista: Array[String] = []
	for local in bairro.ids_locais():
		if bairro.local(local)["tipo"] != "casa":
			lista.append(local)
	return lista


func local_atual() -> String:
	return _local_atual


## Vai a um lugar e examina tudo de uma vez (interface em texto).
## Devolve {"ok", "erro", "novas": [ids], "minutos"}.
func ir(local: String) -> Dictionary:
	var r := chegar(local)
	var novas: Array = []
	if r["ok"]:
		for pista in pistas_no_local():
			if caderno.anotar_pista(pista):
				novas.append(pista["id"])
	return {"ok": r["ok"], "erro": r["erro"], "novas": novas, "minutos": r["minutos"]}


## Vai a um lugar e gasta o tempo de ir e de olhar em volta, mas não anota nada:
## no 3D as pistas ficam no lugar e o jogador precisa achar cada uma (examinar_pista).
## Devolve {"ok", "erro", "minutos"}.
func chegar(local: String) -> Dictionary:
	if not bairro.existe(local):
		return {"ok": false, "erro": "lugar desconhecido", "minutos": 0}
	var custo := int(_cfg["minutos_examinar_local"])
	if local != _local_atual:
		custo += int(_cfg["minutos_ir_ao_local"])
	minuto += custo
	_local_atual = local
	if not visitas.has(local):
		visitas[local] = minuto
	return {"ok": true, "erro": "", "minutos": custo}


## Pistas físicas do lugar atual, agora: marcas deste lugar, ainda válidas e que o
## equipamento do caçador consegue detectar. Em ordem de id (sempre a mesma).
func pistas_no_local() -> Array:
	var lista: Array = []
	if _local_atual.is_empty():
		return lista
	for pista in caso["pistas"]:
		if pista["tipo"] != "marca" or pista["local"] != _local_atual:
			continue
		if _detectavel(pista) and Pistas.disponivel(pista, minuto):
			lista.append(pista)
	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
	return lista


## Examina uma pista que está no lugar atual e anota no caderno.
## Devolve {"ok", "erro", "nova": bool}.
func examinar_pista(pista_id: String) -> Dictionary:
	for pista in pistas_no_local():
		if pista["id"] == pista_id:
			return {"ok": true, "erro": "", "nova": caderno.anotar_pista(pista)}
	return {"ok": false, "erro": "essa pista não está aqui (ou já sumiu)", "nova": false}


## Psicometria: tocar uma pista anotada dá uma visão vaga do que a deixou. Leva 20 minutos.
## {"ok", "erro", "visao"}
func tocar(pista_id: String) -> Dictionary:
	if not sensitivo:
		return {"ok": false, "erro": "só um sensitivo tem visões", "visao": ""}
	var pista: Dictionary = {}
	for p in caderno.pistas():
		if p["id"] == pista_id:
			pista = p
	if pista.is_empty():
		return {"ok": false, "erro": "essa pista não está no caderno", "visao": ""}
	if _tocadas.has(pista_id):
		return {"ok": false, "erro": "você já tocou nessa", "visao": ""}
	_tocadas[pista_id] = true
	minuto += 20
	var visao := Psicometria.visao(caso, pista, Catalogo.carregar_criaturas()["criaturas"], Catalogo.carregar_config_casos()["dados"])
	return {"ok": true, "erro": "", "visao": visao}


## Pesquisa boletins e registros antigos (delegacia, cartório, jornal).
func pesquisar() -> Dictionary:
	var custo := int(_cfg["minutos_pesquisar_registros"])
	minuto += custo
	pesquisou = true
	var novas: Array = []
	for pista in caso["pistas"]:
		if pista["tipo"] != "registro" or int(pista["minuto"]) > minuto:
			continue
		if not _detectavel(pista) or not Pistas.disponivel(pista, minuto):
			continue
		if caderno.anotar_pista(pista):
			novas.append(pista["id"])
	return {"ok": true, "erro": "", "novas": novas, "minutos": custo}


## Casas do bairro, em ordem: [{"local", "familia": sobrenome ou ""}].
func casas() -> Array:
	var lista: Array = []
	for casa in bairro.locais_do_tipo("casa"):
		var sobrenome := ""
		for npc in caso["npcs"]:
			if npc["casa"] == casa:
				sobrenome = npc["sobrenome"]
				break
		lista.append({"local": casa, "familia": sobrenome})
	return lista


func npc(id: String) -> Dictionary:
	return _npcs.get(id, {})


## Quem está acordado no lugar atual, agora. O cliente sempre atende (ele chamou o caçador).
func pessoas_aqui() -> Array[String]:
	var ids: Array[String] = []
	if _local_atual.is_empty():
		return ids
	for npc_dados in caso["npcs"]:
		var p: Dictionary = _rotina.onde_esta(npc_dados, minuto)
		if p["local"] == _local_atual and not p["atividade"] in ["dormindo", "transformado"]:
			ids.append(npc_dados["id"])
	return ids


func pode_falar_com(npc_id: String) -> bool:
	return npc_id == caso["contrato"]["cliente"] or npc_id in pessoas_aqui()


func fechado(npc_id: String) -> bool:
	return _fechados.has(npc_id)


## Entrevista alguém que está por perto. Anota no caderno tudo o que a pessoa conta.
## {"ok", "erro", "novos": [ids de depoimento], "minutos"}
func entrevistar(npc_id: String) -> Dictionary:
	if not _npcs.has(npc_id):
		return {"ok": false, "erro": "pessoa desconhecida", "novos": [], "minutos": 0}
	if not pode_falar_com(npc_id):
		return {"ok": false, "erro": "essa pessoa não está aqui agora", "novos": [], "minutos": 0}
	if fechado(npc_id):
		return {"ok": false, "erro": "não quer mais falar com você", "novos": [], "minutos": 0}
	var custo := int(_cfg["minutos_entrevista"])
	minuto += custo
	_entrevistados[npc_id] = true
	var novos: Array = []
	for dep in caso["depoimentos"]:
		if dep["npc"] == npc_id and caderno.anotar_depoimento(dep):
			novos.append(dep["id"])
	return {"ok": true, "erro": "", "novos": novos, "minutos": custo}


## Confronta um depoimento de alguém com uma prova do caderno (pista ou depoimento).
## Se a prova desmente a mentira, a pessoa cede e conta a verdade (novo depoimento).
## Se não desmente, a pessoa se fecha e a suspeita sobre o caçador sobe.
## {"ok", "erro", "cedeu": bool, "revelado": id ou "", "minutos"}
func confrontar(npc_id: String, prova_id: String) -> Dictionary:
	var falha := {"ok": false, "erro": "", "cedeu": false, "revelado": "", "minutos": 0}
	if not _entrevistados.has(npc_id):
		falha["erro"] = "entreviste essa pessoa antes"
		return falha
	if not pode_falar_com(npc_id):
		falha["erro"] = "essa pessoa não está aqui agora"
		return falha
	if fechado(npc_id):
		falha["erro"] = "não quer mais falar com você"
		return falha
	var prova := _evidencia_do_caderno(prova_id)
	if prova.is_empty():
		falha["erro"] = "essa prova não está no caderno"
		return falha
	var custo := int(_cfg["minutos_confronto"])
	minuto += custo
	for dep in caderno.depoimentos():
		if dep["npc"] != npc_id or dep["mentira"].is_empty():
			continue
		if desmente(prova, dep):
			var verdade := _versao_verdadeira(dep)
			caderno.anotar_depoimento(verdade)
			return {"ok": true, "erro": "", "cedeu": true, "revelado": verdade["id"], "minutos": custo}
	_fechados[npc_id] = true
	suspeita += 1
	return {"ok": true, "erro": "", "cedeu": false, "revelado": "", "minutos": custo}


## A prova desmente a mentira deste depoimento? (docs/04: toda mentira contradiz um fato)
static func desmente(prova: Dictionary, dep: Dictionary) -> bool:
	match dep["mentira"].get("tipo", ""):
		"onde_estava":
			return prova.get("npc", "") != dep["npc"] and prova.get("causa", -1) == dep["causa"] and dep["npc"] in prova.get("viu_pessoas", [])
		"protege_familiar":
			return prova.get("tipo", "") == "ausencia" and prova.get("causa", -1) == dep["causa"] and prova.get("relato", {}).get("quem_saiu", "") == dep["relato"].get("sobre", "")
	return false


func _evidencia_do_caderno(id: String) -> Dictionary:
	for dep in caderno.depoimentos():
		if dep["id"] == id:
			return dep
	for pista in caderno.pistas():
		if pista["id"] == id:
			return pista
	return {}


func _versao_verdadeira(dep: Dictionary) -> Dictionary:
	var verdade: Dictionary = dep.duplicate(true)
	verdade["id"] = "%s_verdade" % dep["id"]
	verdade["confissao"] = dep["mentira"].duplicate()
	if dep["mentira"]["tipo"] == "onde_estava":
		verdade["local_declarado"] = dep["mentira"]["verdade"]
	verdade["mentira"] = {}
	return verdade


func _detectavel(pista: Dictionary) -> bool:
	return pista["detectar"] in _cfg["deteccao_inicial"]
