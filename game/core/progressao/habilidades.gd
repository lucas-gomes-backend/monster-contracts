extends RefCounted
## Habilidades humanas (docs/12, Parte A). Evoluem pela PRÁTICA: cada ação dá experiência na
## árvore dela (config "xp"); cada "xp_por_ponto" vira um ponto para gastar naquela árvore.
## Um teto total de pontos obriga a especializar. O efeito de cada habilidade é um valor por
## nível (multiplicador ou quantidade). Números em data/config/habilidades.json.

var xp: Dictionary = {}  # árvore -> experiência
var niveis: Dictionary = {}  # habilidade -> nível aprendido
var _cfg: Dictionary
var _arvore_de: Dictionary = {}  # habilidade -> árvore
var _def: Dictionary = {}  # habilidade -> definição


func _init(cfg_habilidades: Dictionary) -> void:
	_cfg = cfg_habilidades
	for a in _cfg["arvores"]:
		xp[a["id"]] = 0
		for h in a["habilidades"]:
			_arvore_de[h["id"]] = a["id"]
			_def[h["id"]] = h
			niveis[h["id"]] = 0


## Pratica uma ação ("acerto", "passo_de_ritual"...). Devolve se ganhou ponto novo.
func praticar(acao: String) -> bool:
	if not _cfg["xp"].has(acao):
		return false
	var regra: Dictionary = _cfg["xp"][acao]
	var antes := pontos_ganhos(regra["arvore"])
	xp[regra["arvore"]] = int(xp[regra["arvore"]]) + int(regra["xp"])
	return pontos_ganhos(regra["arvore"]) > antes


func pontos_ganhos(arvore: String) -> int:
	return int(xp.get(arvore, 0)) / int(_cfg["xp_por_ponto"])


func pontos_gastos(arvore: String = "") -> int:
	var n := 0
	for h in niveis:
		if arvore.is_empty() or _arvore_de[h] == arvore:
			n += int(niveis[h])
	return n


func pontos_livres(arvore: String) -> int:
	return pontos_ganhos(arvore) - pontos_gastos(arvore)


func nivel_maximo(habilidade: String) -> int:
	var efeito: Dictionary = _def[habilidade]["efeito"]
	var maximo := 0
	for chave in efeito:
		maximo = maxi(maximo, (efeito[chave] as Array).size())
	return maximo


## Pode aprender (mais um nível de) a habilidade? {"ok", "motivo"}
func pode_aprender(habilidade: String) -> Dictionary:
	if not _def.has(habilidade):
		return {"ok": false, "motivo": "não existe"}
	if int(niveis[habilidade]) >= nivel_maximo(habilidade):
		return {"ok": false, "motivo": "já está no máximo"}
	if pontos_gastos() >= int(_cfg["teto_de_pontos"]):
		return {"ok": false, "motivo": "chegou no teto de %d pontos" % int(_cfg["teto_de_pontos"])}
	if pontos_livres(_arvore_de[habilidade]) <= 0:
		return {"ok": false, "motivo": "sem pontos em %s (pratique mais)" % _arvore_de[habilidade]}
	return {"ok": true, "motivo": ""}


func aprender(habilidade: String) -> Dictionary:
	var r := pode_aprender(habilidade)
	if r["ok"]:
		niveis[habilidade] = int(niveis[habilidade]) + 1
	return r


## O efeito somado das habilidades aprendidas: multiplica (padrão 1.0) ou soma quantidades
## ("perdoa_palavra", "trata_mais", padrão 0).
func efeito(chave: String) -> float:
	var quantidade := chave in ["perdoa_palavra", "trata_mais"]
	var valor := 0.0 if quantidade else 1.0
	for h in niveis:
		var n: int = niveis[h]
		var tabela: Dictionary = _def[h]["efeito"]
		if n <= 0 or not tabela.has(chave):
			continue
		var v := float(tabela[chave][n - 1])
		valor = valor + v if quantidade else valor * v
	return valor


func arvores() -> Array:
	return _cfg["arvores"]
