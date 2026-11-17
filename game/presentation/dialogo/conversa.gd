extends RefCounted
## Conversa com uma pessoa do caso, por opções fixas (docs/05, "Entrevistas" e "Confrontar
## com provas"). Não decide nada sozinha: pergunta à sessão de investigação do núcleo
## (core/investigacao/sessao.gd) e transforma a resposta em falas e opções para a janela.
##
## Estado devolvido: {"nome", "descricao", "falas": [String], "opcoes": [{"id", "texto"}], "acabou": bool}

const LIMITE_DO_ROTULO := 70

var sessao: RefCounted
var fmt: RefCounted
var npc_id: String = ""
var _menu: String = "inicio"


## sessao: core/investigacao/sessao.gd; fmt: ui/texto/interpretador.gd (os textos).
func _init(sessao_investigacao: RefCounted, interpretador: RefCounted) -> void:
	sessao = sessao_investigacao
	fmt = interpretador


## Começa a conversa. Quem não está por perto ou se fechou não conversa.
func abrir(id: String) -> Dictionary:
	npc_id = id
	_menu = "inicio"
	if not sessao.pode_falar_com(id):
		return _estado(["(Não tem ninguém aqui para conversar.)"], [], true)
	if sessao.fechado(id):
		return _estado(["Já falei tudo o que tinha para falar. Me deixa em paz."], [], true)
	var abertura := "Pois não?"
	if _eh_cliente():
		abertura = "Que bom que você veio. Eu não aguento mais isso."
	return _estado([abertura], _opcoes_inicio(), false)


## Escolhe uma opção pelo id e devolve o novo estado.
func escolher(opcao: String) -> Dictionary:
	if opcao == "sair":
		return _estado(["Tá. Qualquer coisa, me procura."], [], true)
	if opcao == "voltar":
		_menu = "inicio"
		return _estado(["E então?"], _opcoes_inicio(), false)
	if opcao == "contrato":
		var linhas: Array = ["Eu te conto de novo:"]
		linhas.append_array(fmt.executar("contrato").split("\n"))
		return _estado(linhas, _opcoes_inicio(), false)
	if opcao == "perguntar":
		return _perguntar()
	if opcao == "provas":
		_menu = "provas"
		var provas := _opcoes_provas()
		if provas.size() == 1:
			return _estado(["(Você ainda não tem nada no caderno para mostrar.)"], _opcoes_inicio(), false)
		return _estado(["(Qual prova você mostra?)"], provas, false)
	if opcao.begins_with("prova:"):
		return _confrontar(opcao.trim_prefix("prova:"))
	return _estado(["(Opção desconhecida.)"], _opcoes_inicio(), false)


func _perguntar() -> Dictionary:
	var r: Dictionary = sessao.entrevistar(npc_id)
	if not r["ok"]:
		return _estado(["(%s)" % r["erro"]], [], true)
	var falas: Array = []
	if r["novos"].is_empty():
		falas.append("Não vi nada de estranho, não. Só o que todo mundo comenta.")
	else:
		falas.append("Olha, vou te contar o que eu sei...")
		for dep in sessao.caderno.depoimentos():
			if dep["id"] in r["novos"]:
				falas.append("[anotado] " + fmt.texto_depoimento(dep))
	falas.append("(%d minutos se passaram.)" % int(r["minutos"]))
	return _estado(falas, _opcoes_inicio(), false)


func _confrontar(prova_id: String) -> Dictionary:
	var r: Dictionary = sessao.confrontar(npc_id, prova_id)
	_menu = "inicio"
	if not r["ok"]:
		return _estado(["(Não deu: %s.)" % r["erro"]], _opcoes_inicio(), false)
	if r["cedeu"]:
		var falas: Array = ["...", "Tá bom. Eu não contei tudo."]
		for dep in sessao.caderno.depoimentos():
			if dep["id"] == r["revelado"]:
				falas.append("[anotado] " + fmt.texto_depoimento(dep))
		return _estado(falas, _opcoes_inicio(), false)
	return _estado(["Você está me acusando de alguma coisa? Some daqui.",
		"(A pessoa se fechou. A notícia corre: suspeita %d.)" % sessao.suspeita], [], true)


func _opcoes_inicio() -> Array:
	var opcoes: Array = []
	if _eh_cliente():
		opcoes.append({"id": "contrato", "texto": "Me conta de novo o que você quer."})
	opcoes.append({"id": "perguntar", "texto": "O que você viu ou ouviu nessas noites?"})
	opcoes.append({"id": "provas", "texto": "Mostrar uma prova do caderno."})
	opcoes.append({"id": "sair", "texto": "Obrigado. Até mais."})
	return opcoes


## Provas do caderno: pistas e depoimentos de outras pessoas, mais a opção de voltar.
func _opcoes_provas() -> Array:
	var opcoes: Array = []
	for pista in sessao.caderno.pistas():
		opcoes.append({"id": "prova:" + pista["id"], "texto": _curto(fmt.texto_pista(pista))})
	for dep in sessao.caderno.depoimentos():
		if dep["npc"] != npc_id:
			opcoes.append({"id": "prova:" + dep["id"], "texto": _curto(fmt.texto_depoimento(dep))})
	opcoes.append({"id": "voltar", "texto": "(Guardar o caderno.)"})
	return opcoes


func _estado(falas: Array, opcoes: Array, acabou: bool) -> Dictionary:
	var pessoa: Dictionary = sessao.npc(npc_id)
	return {
		"nome": fmt.nome(npc_id),
		"descricao": _sem_nome(fmt.descrever_pessoa(pessoa), fmt.nome(npc_id)) if not pessoa.is_empty() else "",
		"falas": falas,
		"opcoes": opcoes,
		"acabou": acabou,
	}


func _eh_cliente() -> bool:
	return npc_id == sessao.caso["contrato"]["cliente"]


## "Fulano de Tal, 29 anos, padeiro" vira "29 anos, padeiro": o nome já está no título.
static func _sem_nome(descricao: String, nome: String) -> String:
	return descricao.trim_prefix(nome + ", ")


static func _curto(texto: String) -> String:
	if texto.length() <= LIMITE_DO_ROTULO:
		return texto
	return texto.substr(0, LIMITE_DO_ROTULO - 3) + "..."
