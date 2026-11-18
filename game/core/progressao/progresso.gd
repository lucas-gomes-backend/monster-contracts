extends RefCounted
## Progressão do caçador no corte vertical (docs/08): dinheiro (reais inteiros), uma
## reputação, e o nível de qualidade (1 Improvisado, 2 Comum, 3 Profissional) de cada
## categoria de equipamento. Todo ganho e gasto vira um lançamento no extrato.
## Números em data/config/progressao.json.

var dinheiro: int = 0
var reputacao: int = 0
var qualidade: Dictionary = {}  # categoria -> nível 1..3
var extrato: Array[Dictionary] = []  # [{"valor", "motivo"}]
## Regiões da cidade abertas (as outras ficam bloqueadas no mapa de viagem).
var regioes_liberadas: Array[String] = []
var _cfg: Dictionary


func _init(cfg_progressao: Dictionary) -> void:
	_cfg = cfg_progressao
	dinheiro = int(_cfg["dinheiro_inicial"])
	for r in _cfg["regioes_liberadas"]:
		regioes_liberadas.append(str(r))
	for categoria in _cfg["nivel_inicial"]:
		qualidade[categoria] = int(_cfg["nivel_inicial"][categoria])


func liberada(regiao: String) -> bool:
	return regiao in regioes_liberadas


func nivel_de_reputacao() -> String:
	var nome := ""
	for n in _cfg["reputacao"]["niveis"]:
		if reputacao >= int(n["a_partir_de"]):
			nome = n["nome"]
	return nome


func _indice_de_reputacao(nome: String) -> int:
	var niveis: Array = _cfg["reputacao"]["niveis"]
	for i in niveis.size():
		if niveis[i]["nome"] == nome:
			return i
	return 0


func ganhar(valor: int, motivo: String) -> void:
	dinheiro += valor
	extrato.append({"valor": valor, "motivo": motivo})


## Gasta, se tiver. Devolve se deu.
func gastar(valor: int, motivo: String) -> bool:
	if valor > dinheiro:
		return false
	dinheiro -= valor
	extrato.append({"valor": -valor, "motivo": motivo})
	return true


## Pagamento e reputação pelo desfecho do caso (core/investigacao/regras_de_campo.gd decidir).
## Recompensa só vem se resolveu dentro do prazo; bônus por prazo folgado e sem inocentes.
## Devolve {"dinheiro", "reputacao", "linhas": [texto]}.
func fechar_caso(desfecho: Dictionary, contrato: Dictionary) -> Dictionary:
	var rep: Dictionary = _cfg["reputacao"]
	var bonus: Dictionary = _cfg["bonus"]
	var ganho := 0
	var pontos := 0
	var linhas: Array[String] = []
	var inocente: bool = not str(desfecho.get("inocente_prejudicado", "")).is_empty() or bool(desfecho.get("amaldicoado_morto", false))
	if desfecho.get("resolucao", "") == "abandonar":
		pontos += int(rep["abandono"])
		linhas.append("Caso abandonado.")
	elif desfecho.get("sucesso", false):
		ganho = int(desfecho.get("recompensa", 0))
		pontos += int(rep["caso_resolvido"])
		if ganho > 0:
			linhas.append("Pagamento do contrato: R$ %d." % ganho)
			pontos += int(rep["no_prazo"])
			var extra := int(round(float(contrato.get("recompensa", ganho)) * float(bonus["no_prazo"])))
			ganho += extra
			linhas.append("Bônus por resolver no prazo: R$ %d." % extra)
			if not inocente:
				var limpo := int(round(float(contrato.get("recompensa", 0)) * float(bonus["sem_inocentes"])))
				ganho += limpo
				pontos += int(rep["sem_inocentes"])
				linhas.append("Bônus por ninguém inocente sair ferido: R$ %d." % limpo)
		else:
			linhas.append("Resolvido, mas o prazo já tinha passado: sem pagamento.")
	else:
		pontos += int(rep["fracasso"])
		linhas.append("Fracasso.")
	if inocente:
		pontos += int(rep["inocente_prejudicado"])
		linhas.append("Um inocente pagou pelo seu erro.")
	if ganho > 0:
		ganhar(ganho, "caso")
	var antes := nivel_de_reputacao()
	reputacao = maxi(0, reputacao + pontos)
	if nivel_de_reputacao() != antes:
		linhas.append("Reputação agora: %s." % nivel_de_reputacao())
	return {"dinheiro": ganho, "reputacao": pontos, "linhas": linhas}


## Melhoria de qualidade: pode comprar? {"ok", "motivo"}
func pode_comprar(melhoria: Dictionary) -> Dictionary:
	if int(qualidade.get(melhoria["categoria"], 1)) >= int(melhoria["nivel"]):
		return {"ok": false, "motivo": "já tem"}
	if int(qualidade.get(melhoria["categoria"], 1)) + 1 < int(melhoria["nivel"]):
		return {"ok": false, "motivo": "precisa do nível anterior"}
	if _indice_de_reputacao(nivel_de_reputacao()) < _indice_de_reputacao(melhoria["reputacao"]):
		return {"ok": false, "motivo": "exige reputação %s" % melhoria["reputacao"]}
	if dinheiro < int(melhoria["preco"]):
		return {"ok": false, "motivo": "falta dinheiro"}
	return {"ok": true, "motivo": ""}


func comprar_melhoria(melhoria: Dictionary) -> Dictionary:
	var r := pode_comprar(melhoria)
	if r["ok"]:
		gastar(int(melhoria["preco"]), melhoria["nome"])
		qualidade[melhoria["categoria"]] = int(melhoria["nivel"])
	return r


func nome_da_qualidade(categoria: String) -> String:
	return _cfg["qualidade"]["niveis"][int(qualidade.get(categoria, 1)) - 1]


## Multiplicadores de uma arma pela qualidade: {"dispersao", "recarga"}.
func multiplicadores_da_arma(arma: String) -> Dictionary:
	var i := int(qualidade.get(arma, 2)) - 1
	var t: Dictionary = _cfg["qualidade"]["armas"]
	return {"dispersao": float(t["dispersao"][i]), "recarga": float(t["recarga"][i])}


## Tamanho da mochila pela qualidade: Vector2i(largura, altura).
func tamanho_da_mochila() -> Vector2i:
	var t: Array = _cfg["qualidade"]["mochila"][int(qualidade.get("mochila", 2)) - 1]
	return Vector2i(int(t[0]), int(t[1]))
