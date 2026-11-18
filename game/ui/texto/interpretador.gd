extends RefCounted
## Interface em texto da Fase 1 (docs/11): o caderno e a investigação jogados por comandos.
## Recebe uma linha, devolve o texto da resposta. Não guarda nada além da sessão.
##
## Referências curtas: pistas p1, p2...; características c1, c2...; lugares l1, l2...

const Relogio := preload("res://core/tempo/relogio.gd")
const Pistas := preload("res://core/casos/pistas.gd")
const Relatorio := preload("res://core/investigacao/relatorio.gd")
const Catalogo := preload("res://core/dados/catalogo.gd")

const NOMES_DIA := {"domingo": "Domingo", "segunda": "Segunda", "terca": "Terça", "quarta": "Quarta", "quinta": "Quinta", "sexta": "Sexta", "sabado": "Sábado"}
const PERGUNTAS := {"o_que": "O quê?", "quem": "Quem?", "por_que": "Por quê?"}

var sessao: RefCounted
var terminou := false

var _criaturas: Dictionary
var _textos: Dictionary
var _gatilhos: Dictionary
var _npcs: Dictionary = {}


func _init(sessao_investigacao: RefCounted, criaturas: Dictionary, textos_marcas: Dictionary) -> void:
	sessao = sessao_investigacao
	_criaturas = criaturas
	_textos = textos_marcas
	_gatilhos = Catalogo.carregar_textos_gatilhos()["dados"]
	for npc in sessao.caso["npcs"]:
		_npcs[npc["id"]] = npc


# --- Textos usados também pela janela (ui/jogo.gd) ---

## O desfecho do caso, depois de agir (usado também no mapa 3D).
func texto_resultado() -> String:
	return _resultado()


## O relatório com toda a verdade, depois de agir (usado também no mapa 3D).
func texto_relatorio() -> String:
	return _relatorio()


func texto_pista(pista: Dictionary) -> String:
	return _texto_pista(pista)


func texto_depoimento(dep: Dictionary) -> String:
	return _texto_depoimento(dep)


func texto_caracteristica(tag: String) -> String:
	return _textos.get(tag, {}).get("caracteristica", tag)


func data(minuto: int) -> String:
	return _data(minuto)


func nome_local(local: String) -> String:
	return _nome_local(local)


func nome(npc_id: String) -> String:
	return _nome(npc_id)


func descrever_pessoa(npc: Dictionary) -> String:
	return _descrever_pessoa(npc)


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
	var de_leitura := ["ajuda", "?", "contrato", "hora", "pistas", "depoimentos", "hipoteses", "bestiario", "caracteristicas", "sair", "resultado", "relatorio", "cartas"]
	if sessao.encerrado() and not comando in de_leitura:
		return "O caso já foi encerrado. Use 'resultado' ou 'sair'."
	match comando:
		"moradores":
			return _moradores()
		"testes":
			return _testes()
		"testar":
			return _testar(args)
		"agir":
			return _agir(args)
		"resultado":
			return _resultado()
		"relatorio":
			return _relatorio()
		"cartas":
			return _cartas()
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
		"casas":
			return _casas()
		"aqui", "pessoas":
			return _aqui()
		"entrevistar":
			return _entrevistar(args)
		"depoimentos":
			return _depoimentos()
		"confrontar":
			return _confrontar(args)
		"pistas":
			return _pistas()
		"bestiario":
			return _bestiario(args)
		"caracteristicas":
			return _caracteristicas()
		"tocar":
			return _tocar(args)
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
		"  casas                    casas do bairro (h1, h2...)",
		"  ir <lN|hN>               ir até um lugar ou casa e examinar (gasta tempo)",
		"  pesquisar                boletins e registros antigos (gasta tempo)",
		"  aqui                     quem está acordado aqui agora (n1, n2...)",
		"  entrevistar <nN|cliente> ouvir alguém (gasta tempo)",
		"  depoimentos              o que as pessoas contaram (d1, d2...)",
		"  confrontar <nN|cliente> <pN|dN>  mostrar uma prova que desmente a pessoa",
		"  pistas                   o que você já anotou (p1, p2...)",
		"  bestiario [espécie]      espécies e o que cada uma deixa",
		"  caracteristicas          características do bestiário (c1, c2...)",
		"  ligar <pN|dN> <cN>       ligar uma pista ou depoimento a uma característica",
		"  tocar <pN>               (sensitivo) tocar uma pista para ter uma visão vaga, 20 min",
		"  desligar <pN|dN> <cN>    desfazer uma ligação",
		"  hipoteses                ligações, espécies compatíveis, riscadas, circulada",
		"  riscar <espécie>         riscar uma espécie",
		"  circular <espécie>       circular o suspeito principal",
		"  modo <assistido|padrao|puro>",
		"  responder <o_que|quem|por_que> <resposta>",
		"  moradores                todos os moradores do bairro (m1, m2...)",
		"  testes                   testes de campo (t1, t2...)",
		"  testar <tN> <mN|lN|hN>   fazer um teste numa pessoa ou lugar (espera até a manhã do resultado)",
		"  agir <resolução> <espécie> [mN]   ENCERRA o caso: matar, banir, prender, curar,",
		"                           apaziguar, negociar, expor ou abandonar",
		"  resultado                o desfecho, depois de agir",
		"  relatorio                toda a verdade: pistas perdidas, ligações erradas, mentiras, ruído",
		"  cartas                   as cartas e presentes que chegaram depois do caso",
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
		local = _resolver(args[0], "h", _ids_casas())
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


func _ids_casas() -> Array:
	var ids: Array = []
	for casa in sessao.casas():
		ids.append(casa["local"])
	return ids


func _casas() -> String:
	var linhas: Array = ["Casas:"]
	var lista: Array = sessao.casas()
	for i in lista.size():
		var familia: String = lista[i]["familia"]
		linhas.append("  h%d  %s%s" % [i + 1, _nome_local(lista[i]["local"]), " (família %s)" % familia if not familia.is_empty() else " (vazia)"])
	return "\n".join(linhas)


func _aqui() -> String:
	if sessao.local_atual().is_empty():
		return "Você ainda não foi a lugar nenhum. O cliente atende sempre: 'entrevistar cliente'."
	var pessoas: Array = sessao.pessoas_aqui()
	var linhas: Array = ["Em %s agora (%s):" % [_nome_local(sessao.local_atual()), _data(sessao.minuto)]]
	if pessoas.is_empty():
		linhas.append("  Ninguém acordado por aqui.")
	for i in pessoas.size():
		var n: Dictionary = sessao.npc(pessoas[i])
		linhas.append("  n%d  %s%s" % [i + 1, _descrever_pessoa(n), " (não quer falar)" if sessao.fechado(n["id"]) else ""])
	return "\n".join(linhas)


func _ids_moradores() -> Array:
	var ids: Array = []
	for n in sessao.caso["npcs"]:
		ids.append(n["id"])
	return ids


func _moradores() -> String:
	var linhas: Array = ["Moradores do bairro:"]
	var ids := _ids_moradores()
	for i in ids.size():
		var n: Dictionary = sessao.npc(ids[i])
		linhas.append("  m%d  %s — %s" % [i + 1, _descrever_pessoa(n), _nome_local(n["casa"])])
	return "\n".join(linhas)


func _testes() -> String:
	var linhas: Array = ["Testes de campo:"]
	var testes: Array = sessao.testes_disponiveis()
	for i in testes.size():
		linhas.append("  t%d  %s (em %s): %s" % [i + 1, testes[i]["nome"], "uma pessoa" if testes[i]["alvo"] == "pessoa" else "um lugar", testes[i]["descricao"]])
	return "\n".join(linhas)


func _testar(args: Array) -> String:
	if args.size() < 2:
		return "Use: testar <tN> <mN|lN|hN>."
	var ids_testes: Array = []
	for t in sessao.testes_disponiveis():
		ids_testes.append(t["id"])
	var teste_id := _resolver(args[0], "t", ids_testes)
	if teste_id.is_empty():
		return "Teste desconhecido: %s." % args[0]
	var alvo := _resolver_pessoa(args[1])
	if alvo.is_empty():
		alvo = _resolver(args[1], "l", sessao.locais())
	if alvo.is_empty():
		alvo = _resolver(args[1], "h", _ids_casas())
	if alvo.is_empty():
		return "Alvo desconhecido: %s." % args[1]
	return texto_teste(sessao.aplicar_teste(teste_id, alvo))


## Texto do resultado de um teste de campo (sessao.aplicar_teste). Usado também no mapa 3D.
func texto_teste(r: Dictionary) -> String:
	if not r["ok"]:
		return "Não deu: %s." % r["erro"]
	var alvo: String = r["alvo"]
	var nome_alvo := _nome(alvo) if not sessao.npc(alvo).is_empty() else _nome_local(alvo)
	var texto: String = r["teste"]["positivo" if r["positivo"] else "negativo"]
	var linhas: Array = ["%s (%s). Agora: %s." % [r["teste"]["nome"], _duracao(int(r["minutos"])), _data(sessao.minuto)], texto.replace("{alvo}", nome_alvo)]
	if r["percebeu"]:
		linhas.append("Você tem a sensação de que foi observado. A criatura pode ter percebido o teste.")
	return "\n".join(linhas)


func _agir(args: Array) -> String:
	if args.is_empty():
		return "Use: agir <resolução> <espécie> [mN], ou 'agir abandonar'."
	var resolucao: String = args[0]
	var especie: String = args[1] if args.size() > 1 else ""
	var alvo := _resolver_pessoa(args[2]) if args.size() > 2 else ""
	var r: Dictionary = sessao.agir(resolucao, especie, alvo)
	if not r["ok"]:
		return "Não deu: %s." % r["erro"]
	return "Caso encerrado.\n" + _resultado() + "\nUse 'relatorio' para ver toda a verdade."


func _resultado() -> String:
	var r: Dictionary = sessao.desfecho
	if r.is_empty():
		return "O caso ainda está aberto. Para encerrar: 'agir <resolução> <espécie> [mN]'."
	var verdade: Dictionary = sessao.caso["verdade"]
	var linhas: Array = []
	if r["resolucao"] == "abandonar":
		linhas.append("Você abandonou o caso.")
	else:
		linhas.append("%s: %s" % ["SUCESSO" if r["sucesso"] else "FRACASSO", r["motivo"]])
		linhas.append("Você apostou em: %s." % _criaturas[r["especie"]]["nome"])
	if sessao.caso["estrutura"] == "golpe":
		linhas.append("A verdade: não havia criatura. Era um golpe de %s." % _nome(verdade["hospedeiro"]))
	else:
		linhas.append("A verdade: era %s%s." % [_criaturas[verdade["especie"]]["nome"], " (%s)" % _nome(verdade["hospedeiro"]) if not str(verdade["hospedeiro"]).is_empty() else ""])
	if r.get("prazo_estourado", false):
		linhas.append("O prazo do cliente tinha acabado quando você agiu: ele já tinha desistido e não pagou.")
	if r.get("amaldicoado_morto", false):
		linhas.append("Quem morreu era uma pessoa amaldiçoada, que podia ter sido curada.")
	if not str(r.get("inocente_prejudicado", "")).is_empty():
		linhas.append("%s era inocente e foi prejudicado(a) pela sua ação." % _nome(r["inocente_prejudicado"]))
	linhas.append("Recompensa: R$ %d. Suspeita no bairro: %d." % [int(r["recompensa"]), sessao.suspeita])
	return "\n".join(linhas)


const TEXTO_SEGREDO := {"caso_extraconjugal": "esconder um caso extraconjugal", "furtos": "esconder uns furtos", "crime_antigo": "esconder um crime antigo", "familia": "proteger a família"}
const TEXTO_RUIDO := {"furto_de_galinhas": "Um vizinho furtando galinhas", "caes_de_rua": "Cães de rua revirando o lixo", "briga_de_bar": "Uma briga de bar"}


func _relatorio() -> String:
	if not sessao.encerrado():
		return "O relatório sai quando o caso for encerrado ('agir')."
	var r: Dictionary = Relatorio.gerar(sessao, _criaturas, _gatilhos)
	var v: Dictionary = r["verdade"]
	var linhas: Array = ["RELATÓRIO DO CASO Nº %d" % int(sessao.caso["semente"]), "", _resultado(), ""]

	linhas.append("POR QUÊ")
	linhas.append("  %s%s" % [v["por_que"], " (%s)" % _nome(v["npc_ligado"]) if not str(v["npc_ligado"]).is_empty() and v["hospedeiro"] != v["npc_ligado"] else ""])
	var horas := int(r["tempo"]["minutos_gastos"]) / 60
	linhas.append("  Você levou %d horas desde o contrato%s." % [horas, ", e passou do prazo" if r["tempo"]["passou_do_prazo"] else ", dentro do prazo"])
	linhas.append("")

	var encontradas: int = r["pistas"]["encontradas"].size()
	var perdidas: Array = r["pistas"]["perdidas"]
	var de_quem := "DO CULPADO" if v["estrutura"] == "golpe" else "DA CRIATURA"
	linhas.append("PISTAS %s: você achou %d de %d" % [de_quem, encontradas, encontradas + perdidas.size()])
	var por_id := {}
	for p in sessao.caso["pistas"]:
		por_id[p["id"]] = p
	for perdida in perdidas:
		var p: Dictionary = por_id[perdida["id"]]
		linhas.append("  - %s [%s]: %s." % [_texto_pista(p), _nome_local(p["local"]) if not str(p["local"]).is_empty() else "registros", perdida["motivo"]])
	linhas.append("")

	var certas: Array = r["ligacoes"]["certas"]
	var erradas: Array = r["ligacoes"]["erradas"]
	linhas.append("SUAS LIGAÇÕES NO CADERNO: %d certas, %d erradas" % [certas.size(), erradas.size()])
	for e in erradas:
		linhas.append("  - \"%s\" não era \"%s\"." % [_resumo(e["fonte"]).trim_suffix("."), texto_caracteristica(e["tag"]).trim_suffix(".")])
	linhas.append("")

	linhas.append("QUEM MENTIU")
	if r["mentiras"].is_empty():
		linhas.append("  Ninguém mentiu neste caso.")
	for m in r["mentiras"]:
		var situacao := "você descobriu" if m["descoberta"] else ("você ouviu e acreditou" if m["ouvida"] else "você não chegou a ouvir")
		var verdade_txt := ""
		if m["tipo"] == "onde_estava":
			verdade_txt = "estava em %s, não em casa" % _nome_local(m["verdade"])
		else:
			verdade_txt = "%s %s" % [_nome(m["sobre"]), str(m["verdade"]).replace("saiu_as_", "saiu de casa às ")]
		linhas.append("  - %s mentiu para %s. A verdade: %s. (%s)" % [_nome(m["npc"]), TEXTO_SEGREDO.get(m["motivo"], m["motivo"]), verdade_txt, situacao])
	linhas.append("")

	linhas.append("RUÍDO (coisas normais que confundem)")
	for ru in r["ruido"]:
		linhas.append("  - %s em %s, %s. Você anotou %d pista(s) disso." % [TEXTO_RUIDO.get(ru["ruido"], ru["ruido"]), _nome_local(ru["local"]), _dia(int(ru["minuto"])), int(ru["pistas_anotadas"])])
	linhas.append("")

	var d: Dictionary = r["depoimentos"]
	linhas.append("DEPOIMENTOS: você ouviu %d de %d." % [int(d["ouvidos"]), int(d["total"])])
	if int(d["sobre_o_hospedeiro_nao_ouvidos"]) > 0:
		linhas.append("  %d vizinho(s) tinham visto alguém sair de casa na noite do ataque, e você não conversou com eles." % int(d["sobre_o_hospedeiro_nao_ouvidos"]))
	linhas.append("")
	linhas.append(_cartas())
	return "\n".join(linhas)


## Cartas e presentes que chegam depois do caso (sessao.cartas()).
func _cartas() -> String:
	if not sessao.encerrado():
		return "As cartas chegam depois que o caso for encerrado ('agir')."
	var cartas: Array[Dictionary] = sessao.cartas()
	var linhas: Array = ["CARTAS E PRESENTES (chegaram nos dias seguintes)"]
	if cartas.is_empty():
		linhas.append("  Nenhuma carta.")
	for c in cartas:
		var quem: String = "alguém que não se identificou" if str(c["remetente"]).is_empty() else _nome(c["remetente"])
		linhas.append("  - De %s:" % quem)
		linhas.append("    \"%s\"" % c["texto"])
		if not str(c["presente"]).is_empty():
			linhas.append("    Junto veio %s." % c["presente"])
	return "\n".join(linhas)


func _resumo(id: String) -> String:
	for p in sessao.caderno.pistas():
		if p["id"] == id:
			return _texto_pista(p)
	for d in sessao.caderno.depoimentos():
		if d["id"] == id:
			return _texto_depoimento(d).left(70) + "…"
	return id


func _duracao(minutos: int) -> String:
	return "%dh%02d" % [minutos / 60, minutos % 60]


func _resolver_pessoa(ref: String) -> String:
	if ref == "cliente":
		return sessao.caso["contrato"]["cliente"]
	if ref.begins_with("m"):
		var morador := _resolver(ref, "m", _ids_moradores())
		if not morador.is_empty():
			return morador
	var id := _resolver(ref, "n", sessao.pessoas_aqui())
	return id if not id.is_empty() else (ref if not sessao.npc(ref).is_empty() else "")


func _entrevistar(args: Array) -> String:
	if args.is_empty():
		return "Entrevistar quem? Use 'aqui' para ver quem está por perto, ou 'entrevistar cliente'."
	var id := _resolver_pessoa(args[0])
	if id.is_empty():
		return "Pessoa desconhecida: %s." % args[0]
	var r: Dictionary = sessao.entrevistar(id)
	if not r["ok"]:
		return "Não deu: %s." % r["erro"]
	var linhas: Array = ["Você conversou com %s (%d min)." % [_nome(id), int(r["minutos"])]]
	if r["novos"].is_empty():
		linhas.append("Não viu nem ouviu nada de diferente.")
	else:
		linhas.append_array(_linhas_depoimentos(r["novos"]))
	return "\n".join(linhas)


func _depoimentos() -> String:
	var todos: Array = sessao.caderno.depoimentos()
	if todos.is_empty():
		return "Ninguém contou nada ainda. Use 'aqui' e 'entrevistar'."
	var ids: Array = []
	for d in todos:
		ids.append(d["id"])
	return "Depoimentos:\n" + "\n".join(_linhas_depoimentos(ids))


func _linhas_depoimentos(ids: Array) -> Array:
	var linhas: Array = []
	var todos: Array = sessao.caderno.depoimentos()
	for i in todos.size():
		if todos[i]["id"] in ids:
			linhas.append("  d%d  %s" % [i + 1, _texto_depoimento(todos[i])])
	return linhas


func _confrontar(args: Array) -> String:
	if args.size() < 2:
		return "Use: confrontar <nN|cliente> <pN|dN>."
	var id := _resolver_pessoa(args[0])
	if id.is_empty():
		return "Pessoa desconhecida: %s." % args[0]
	var prova := _resolver_evidencia(args[1])
	if prova.is_empty():
		return "Prova desconhecida: %s." % args[1]
	var r: Dictionary = sessao.confrontar(id, prova)
	if not r["ok"]:
		return "Não deu: %s." % r["erro"]
	if r["cedeu"]:
		var linhas: Array = ["%s fica em silêncio, depois cede e conta a verdade:" % _nome(id)]
		linhas.append_array(_linhas_depoimentos([r["revelado"]]))
		return "\n".join(linhas)
	return "%s se ofende e encerra a conversa. A notícia corre: você está chamando atenção (suspeita %d)." % [_nome(id), sessao.suspeita]


func _texto_depoimento(dep: Dictionary) -> String:
	var quem := _nome(dep["npc"])
	var causa: Dictionary = sessao.caso["registro"].obter(int(dep["causa"]))
	# Só o dia: a hora é a que a testemunha declara, que pode estar errada.
	var quando := _dia(int(causa.get("minuto", 0)) - 6 * 60)
	match dep["tipo"]:
		"ausencia":
			return "%s viu %s saindo de casa por volta das %02dh (noite de %s)." % [quem, _nome(dep["relato"]["quem_saiu"]), int(dep["relato"]["hora_declarada"]), quando]
		"alibi":
			return "%s jura que %s ficou em casa a noite toda (noite de %s)." % [quem, _nome(dep["relato"]["sobre"]), quando]
	var r: Dictionary = dep["relato"]
	var partes: Array = []
	if dep.has("confissao"):
		partes.append("Admite que estava em %s." % _nome_local(dep["local_declarado"]))
	else:
		partes.append("%s diz que estava em %s por volta das %02dh (noite de %s)." % [quem, _nome_local(dep["local_declarado"]), int(r["hora_declarada"]), quando])
	if r.has("forma"):
		partes.append("Viu %s (%s)." % [r["forma"], r["tamanho"]])
	partes.append("Ouviu %s." % r["som"])
	if not str(dep["interpretacao"]).is_empty():
		partes.append("Acha que era: %s." % dep["interpretacao"])
	for tag in dep["tags"]:
		partes.append(_textos.get(tag, {}).get("pista", ""))
	if not dep["viu_pessoas"].is_empty():
		var nomes: Array = []
		for outro in dep["viu_pessoas"]:
			nomes.append(_nome(outro))
		partes.append("Estavam lá também: %s." % ", ".join(nomes))
	return " ".join(partes)


func _resolver_evidencia(ref: String) -> String:
	var pistas: Array = []
	for p in sessao.caderno.pistas():
		pistas.append(p["id"])
	var deps: Array = []
	for d in sessao.caderno.depoimentos():
		deps.append(d["id"])
	var id := _resolver(ref, "p", pistas)
	return id if not id.is_empty() else _resolver(ref, "d", deps)


func _descrever_pessoa(n: Dictionary) -> String:
	return "%s %s, %d anos, %s" % [n["nome"], n["sobrenome"], int(n["idade"]), str(n["ocupacao"].get("id", "")).replace("_", " ")]


func _nome(npc_id: String) -> String:
	var n: Dictionary = sessao.npc(npc_id)
	return "%s %s" % [n["nome"], n["sobrenome"]] if not n.is_empty() else npc_id


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


## Sensitivo: tocar uma pista anotada (psicometria).
func _tocar(args: Array) -> String:
	if args.is_empty():
		return "Use: tocar <pN>."
	var id := _resolver_evidencia(args[0])
	if id.is_empty() or not id.begins_with("pista"):
		return "Pista desconhecida: %s." % args[0]
	var r: Dictionary = sessao.tocar(id)
	return r["visao"] if r["ok"] else "Não deu: %s." % r["erro"]


func _ligar(args: Array, ligar: bool) -> String:
	if args.size() < 2:
		return "Use: %s <pN> <cN>." % ("ligar" if ligar else "desligar")
	var fonte := _resolver_evidencia(args[0])
	var tag := _resolver(args[1], "c", sessao.caderno.vocabulario())
	if fonte.is_empty():
		return "Pista ou depoimento desconhecido: %s." % args[0]
	if tag.is_empty():
		return "Característica desconhecida: %s." % args[1]
	if not ligar:
		sessao.caderno.desligar(fonte, tag)
		return "Ligação desfeita."
	var erro: String = sessao.caderno.ligar(fonte, tag)
	return "Ligado: %s -> %s" % [args[0], _textos.get(tag, {}).get("caracteristica", tag)] if erro.is_empty() else "Não deu: %s." % erro


func _hipoteses() -> String:
	var caderno: RefCounted = sessao.caderno
	var vocab: Array = caderno.vocabulario()
	var linhas: Array = ["Hipóteses (modo %s):" % caderno.modo]
	var ligacoes: Dictionary = caderno.ligacoes()
	if ligacoes.is_empty():
		linhas.append("  Nenhuma ligação ainda.")
	for fonte in ligacoes:
		for tag in ligacoes[fonte]:
			linhas.append("  %s -> c%d  %s" % [_ref(fonte), vocab.find(tag) + 1, _textos.get(tag, {}).get("caracteristica", tag)])
	linhas.append("Compatíveis: %s" % _nomes(caderno.compativeis()))
	linhas.append("Riscadas: %s" % _nomes(caderno.riscadas()))
	linhas.append("Circulada: %s" % (_criaturas[caderno.circulada()]["nome"] if not caderno.circulada().is_empty() else "-"))
	for pergunta in PERGUNTAS:
		linhas.append("%s %s" % [PERGUNTAS[pergunta], caderno.respostas()[pergunta] if not caderno.respostas()[pergunta].is_empty() else "-"])
	for s in caderno.sugestoes():
		linhas.append("  Sugestão: ligar %s a c%d." % [_ref(s["fonte"]), vocab.find(s["tag"]) + 1])
	return "\n".join(linhas)


## Referência curta (p3, d2) de uma pista ou depoimento do caderno.
func _ref(id: String) -> String:
	var pistas: Array = sessao.caderno.pistas()
	for i in pistas.size():
		if pistas[i]["id"] == id:
			return "p%d" % (i + 1)
	var deps: Array = sessao.caderno.depoimentos()
	for i in deps.size():
		if deps[i]["id"] == id:
			return "d%d" % (i + 1)
	return id


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


## "Quinta, 07/05/2015" (sem a hora).
func _dia(minuto: int) -> String:
	var d := Relogio.data_de(minuto)
	return "%s, %02d/%02d/%d" % [NOMES_DIA[d["nome_dia"]], d["dia"], d["mes"], d["ano"]]


func _data(minuto: int) -> String:
	var d := Relogio.data_de(minuto)
	return "%s, %02d/%02d/%d, %02d:%02d" % [NOMES_DIA[d["nome_dia"]], d["dia"], d["mes"], d["ano"], d["hora"], d["minuto"]]
