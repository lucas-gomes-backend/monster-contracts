extends RefCounted
## Interface em texto da Fase 1 (docs/11): o caderno e a investigação jogados por comandos.
## Recebe uma linha, devolve o texto da resposta. Não guarda nada além da sessão.
##
## Referências curtas: pistas p1, p2...; características c1, c2...; lugares l1, l2...

const Relogio := preload("res://core/tempo/relogio.gd")
const Pistas := preload("res://core/casos/pistas.gd")

const NOMES_DIA := {"domingo": "Domingo", "segunda": "Segunda", "terca": "Terça", "quarta": "Quarta", "quinta": "Quinta", "sexta": "Sexta", "sabado": "Sábado"}
const PERGUNTAS := {"o_que": "O quê?", "quem": "Quem?", "por_que": "Por quê?"}

var sessao: RefCounted
var terminou := false

var _criaturas: Dictionary
var _textos: Dictionary
var _npcs: Dictionary = {}


func _init(sessao_investigacao: RefCounted, criaturas: Dictionary, textos_marcas: Dictionary) -> void:
	sessao = sessao_investigacao
	_criaturas = criaturas
	_textos = textos_marcas
	for npc in sessao.caso["npcs"]:
		_npcs[npc["id"]] = npc


func abertura() -> String:
	return "\n".join([
		"MONSTER CONTRACTS — investigação em texto (Fase 1)",
		"Bairro: %s" % sessao.bairro.dados["nome"],
		"",
		executar("contrato"),
		"",
		"Digite 'ajuda' para ver os comandos.",
	])


func executar(linha: String) -> String:
	var partes := linha.strip_edges().split(" ", false)
	if partes.is_empty():
		return ""
	var comando := partes[0].to_lower()
	var args := partes.slice(1)
	match comando:
		"ajuda", "?":
			return _ajuda()
		"contrato":
			return _contrato()
		"hora":
			return "Agora: %s." % _data(sessao.minuto)
		"locais", "lugares":
			return _locais()
		"ir":
			return _ir(args)
		"pesquisar":
			return _pesquisar()
		"pistas":
			return _pistas()
		"bestiario":
			return _bestiario(args)
		"caracteristicas":
			return _caracteristicas()
		"ligar":
			return _ligar(args, true)
		"desligar":
			return _ligar(args, false)
		"hipoteses":
			return _hipoteses()
		"riscar":
			return _marcar_especie(args, "riscar")
		"circular":
			return _marcar_especie(args, "circular")
		"modo":
			return _modo(args)
		"responder":
			return _responder(args)
		"sair":
			terminou = true
			return "Caderno fechado."
	return "Não entendi \"%s\". Digite 'ajuda'." % comando


func _ajuda() -> String:
	return "\n".join([
		"Comandos:",
		"  contrato                 o que o cliente pediu",
		"  hora                     dia e hora agora",
		"  locais                   lugares do bairro (l1, l2...)",
		"  ir <lN>                  ir até um lugar e examinar (gasta tempo)",
		"  pesquisar                boletins e registros antigos (gasta tempo)",
		"  pistas                   o que você já anotou (p1, p2...)",
		"  bestiario [espécie]      espécies e o que cada uma deixa",
		"  caracteristicas          características do bestiário (c1, c2...)",
		"  ligar <pN> <cN>          ligar uma pista a uma característica",
		"  desligar <pN> <cN>       desfazer uma ligação",
		"  hipoteses                ligações, espécies compatíveis, riscadas, circulada",
		"  riscar <espécie>         riscar uma espécie",
		"  circular <espécie>       circular o suspeito principal",
		"  modo <assistido|padrao|puro>",
		"  responder <o_que|quem|por_que> <resposta>",
		"  sair",
	])


func _contrato() -> String:
	var c: Dictionary = sessao.caso["contrato"]
	var cliente: Dictionary = _npcs.get(c["cliente"], {})
	return "\n".join([
		"Cliente: %s %s, %d anos." % [cliente.get("nome", "?"), cliente.get("sobrenome", ""), int(cliente.get("idade", 0))],
		"Pedido: %s." % ("acabar com a coisa que anda atacando o bairro" if c["pedido"] == "matar" else "descobrir o que está acontecendo"),
		"Recompensa: R$ %d." % int(c["recompensa"]),
		"Prazo: %s." % _data(int(c["prazo_minuto"])),
	])


func _locais() -> String:
	var linhas: Array = ["Lugares (você está em: %s):" % (_nome_local(sessao.local_atual()) if not sessao.local_atual().is_empty() else "lugar nenhum ainda")]
	var lista: Array = sessao.locais()
	for i in lista.size():
		linhas.append("  l%d  %s" % [i + 1, _nome_local(lista[i])])
	return "\n".join(linhas)


func _ir(args: Array) -> String:
	if args.is_empty():
		return "Ir para onde? Use 'locais' e depois 'ir l1'."
	var local := _resolver(args[0], "l", sessao.locais())
	if local.is_empty():
		return "Lugar desconhecido: %s." % args[0]
	var r: Dictionary = sessao.ir(local)
	var linhas: Array = ["Você foi até %s e examinou o lugar (%d min). Agora: %s." % [_nome_local(local), int(r["minutos"]), _data(sessao.minuto)]]
	linhas.append_array(_linhas_novas(r["novas"]))
	return "\n".join(linhas)


func _pesquisar() -> String:
	var r: Dictionary = sessao.pesquisar()
	var linhas: Array = ["Você pesquisou boletins e registros antigos (%d min). Agora: %s." % [int(r["minutos"]), _data(sessao.minuto)]]
	linhas.append_array(_linhas_novas(r["novas"]))
	return "\n".join(linhas)


func _linhas_novas(novas: Array) -> Array:
	if novas.is_empty():
		return ["Nada de novo."]
	var linhas: Array = ["Anotado no caderno:"]
	var todas: Array = sessao.caderno.pistas()
	for i in todas.size():
		if todas[i]["id"] in novas:
			linhas.append("  p%d  %s" % [i + 1, _texto_pista(todas[i])])
	return linhas


func _pistas() -> String:
	var todas: Array = sessao.caderno.pistas()
	if todas.is_empty():
		return "O caderno ainda não tem pistas. Vá até um lugar ('ir') ou pesquise ('pesquisar')."
	var linhas: Array = ["Pistas:"]
	for i in todas.size():
		var p: Dictionary = todas[i]
		var vence := "não vence" if int(p["valida_ate"]) < 0 else "some %s" % _data(int(p["valida_ate"]))
		linhas.append("  p%d  [%s] %s (%s)" % [i + 1, _nome_local(p["local"]) if not str(p["local"]).is_empty() else "registros", _texto_pista(p), vence])
	return "\n".join(linhas)


func _bestiario(args: Array) -> String:
	var especies: Array = sessao.caderno.especies()
	if args.is_empty():
		var nomes: Array = []
		for id in especies:
			nomes.append("%s (%s)" % [_criaturas[id]["nome"], id])
		return "Bestiário: %s.\nUse 'bestiario <espécie>' para ver as características." % ", ".join(nomes)
	var id: String = args[0]
	if not id in especies:
		return "Espécie desconhecida: %s." % id
	var linhas: Array = ["%s:" % _criaturas[id]["nome"]]
	var vocab: Array = sessao.caderno.vocabulario()
	for tag in sessao.caderno.caracteristicas_de(id):
		linhas.append("  c%d  %s" % [vocab.find(tag) + 1, _textos.get(tag, {}).get("caracteristica", tag)])
	return "\n".join(linhas)


func _caracteristicas() -> String:
	var linhas: Array = ["Características do bestiário:"]
	var vocab: Array = sessao.caderno.vocabulario()
	for i in vocab.size():
		linhas.append("  c%d  %s" % [i + 1, _textos.get(vocab[i], {}).get("caracteristica", vocab[i])])
	return "\n".join(linhas)


func _ligar(args: Array, ligar: bool) -> String:
	if args.size() < 2:
		return "Use: %s <pN> <cN>." % ("ligar" if ligar else "desligar")
	var ids_pistas: Array = []
	for p in sessao.caderno.pistas():
		ids_pistas.append(p["id"])
	var fonte := _resolver(args[0], "p", ids_pistas)
	var tag := _resolver(args[1], "c", sessao.caderno.vocabulario())
	if fonte.is_empty():
		return "Pista desconhecida: %s." % args[0]
	if tag.is_empty():
		return "Característica desconhecida: %s." % args[1]
	if not ligar:
		sessao.caderno.desligar(fonte, tag)
		return "Ligação desfeita."
	var erro: String = sessao.caderno.ligar(fonte, tag)
	return "Ligado: %s -> %s" % [args[0], _textos.get(tag, {}).get("caracteristica", tag)] if erro.is_empty() else "Não deu: %s." % erro


func _hipoteses() -> String:
	var caderno: RefCounted = sessao.caderno
	var ids_pistas: Array = []
	for p in caderno.pistas():
		ids_pistas.append(p["id"])
	var vocab: Array = caderno.vocabulario()
	var linhas: Array = ["Hipóteses (modo %s):" % caderno.modo]
	var ligacoes: Dictionary = caderno.ligacoes()
	if ligacoes.is_empty():
		linhas.append("  Nenhuma ligação ainda.")
	for fonte in ligacoes:
		for tag in ligacoes[fonte]:
			linhas.append("  p%d -> c%d  %s" % [ids_pistas.find(fonte) + 1, vocab.find(tag) + 1, _textos.get(tag, {}).get("caracteristica", tag)])
	linhas.append("Compatíveis: %s" % _nomes(caderno.compativeis()))
	linhas.append("Riscadas: %s" % _nomes(caderno.riscadas()))
	linhas.append("Circulada: %s" % (_criaturas[caderno.circulada()]["nome"] if not caderno.circulada().is_empty() else "-"))
	for pergunta in PERGUNTAS:
		linhas.append("%s %s" % [PERGUNTAS[pergunta], caderno.respostas()[pergunta] if not caderno.respostas()[pergunta].is_empty() else "-"])
	for s in caderno.sugestoes():
		linhas.append("  Sugestão: ligar p%d a c%d." % [ids_pistas.find(s["fonte"]) + 1, vocab.find(s["tag"]) + 1])
	return "\n".join(linhas)


func _marcar_especie(args: Array, acao: String) -> String:
	if args.is_empty():
		return "Qual espécie?"
	var ok: bool = sessao.caderno.riscar(args[0]) if acao == "riscar" else sessao.caderno.circular(args[0])
	if not ok:
		return "Espécie desconhecida: %s." % args[0]
	return "%s %s." % [_criaturas[args[0]]["nome"], "riscado(a)" if acao == "riscar" else "circulado(a)"]


func _modo(args: Array) -> String:
	if args.is_empty() or not sessao.caderno.definir_modo(args[0]):
		return "Modos: assistido, padrao, puro."
	return "Modo: %s." % args[0]


func _responder(args: Array) -> String:
	if args.size() < 2 or not sessao.caderno.responder(args[0], " ".join(args.slice(1))):
		return "Use: responder <o_que|quem|por_que> <resposta>."
	return "Anotado."


func _resolver(ref: String, prefixo: String, lista: Array) -> String:
	if ref.begins_with(prefixo) and ref.substr(1).is_valid_int():
		var i := ref.substr(1).to_int() - 1
		return lista[i] if i >= 0 and i < lista.size() else ""
	return ref if ref in lista else ""


func _texto_pista(pista: Dictionary) -> String:
	if pista["tipo"] == "registro" and not pista.has("tag"):
		var ataque: Dictionary = sessao.caso["registro"].obter(int(pista["causa"]))
		return "Boletim de ocorrência: ataque em %s, %s." % [_nome_local(ataque.get("local", "")), _data(int(ataque.get("minuto", 0)))]
	return _textos.get(pista.get("tag", ""), {}).get("pista", "Algo estranho.")


func _nome_local(local: String) -> String:
	return sessao.bairro.local(local).get("nome", local)


func _nomes(ids: Array) -> String:
	var nomes: Array = []
	for id in ids:
		nomes.append(_criaturas[id]["nome"])
	return ", ".join(nomes) if not nomes.is_empty() else "-"


func _data(minuto: int) -> String:
	var d := Relogio.data_de(minuto)
	return "%s, %02d/%02d/%d, %02d:%02d" % [NOMES_DIA[d["nome_dia"]], d["dia"], d["mes"], d["ano"], d["hora"], d["minuto"]]
