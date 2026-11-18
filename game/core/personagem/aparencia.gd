extends RefCounted
## Aparência do caçador (docs/09): sliders de 0 a 1, pele, cabelo, barba e uma roupa por
## parte. É só dado: quem monta o boneco é presentation/personagem/corpo.gd. O disfarce vale
## quando as peças vestidas batem com as do disfarce (config/aparencia.json).

var sliders: Dictionary = {}
var pele: String
var cabelo: String
var cor_do_cabelo: String
var barba: String
var roupas: Dictionary = {}
var _cfg: Dictionary


func _init(cfg_aparencia: Dictionary) -> void:
	_cfg = cfg_aparencia
	for s in _cfg["sliders"]:
		sliders[s] = float(_cfg["sliders"][s]["padrao"])
	var p: Dictionary = _cfg["padrao"]
	pele = p["pele"]
	cabelo = p["cabelo"]
	cor_do_cabelo = p["cor_do_cabelo"]
	barba = p["barba"]
	roupas = (p["roupas"] as Dictionary).duplicate()


func definir_slider(id: String, valor: float) -> void:
	if sliders.has(id):
		sliders[id] = clampf(valor, 0.0, 1.0)


## Escolhe uma opção de uma lista ("peles", "cabelos", "barbas", "cores_de_cabelo" ou uma
## parte de roupa). Devolve se a opção existe.
func escolher(lista: String, id: String) -> bool:
	var opcoes: Array = _cfg["roupas"][lista] if _cfg["roupas"].has(lista) else _cfg.get(lista, [])
	if not opcoes.any(func(o): return o["id"] == id):
		return false
	match lista:
		"peles":
			pele = id
		"cabelos":
			cabelo = id
		"barbas":
			barba = id
		"cores_de_cabelo":
			cor_do_cabelo = id
		_:
			roupas[lista] = id
	return true


func opcoes(lista: String) -> Array:
	return _cfg["roupas"][lista] if _cfg["roupas"].has(lista) else _cfg.get(lista, [])


## A cor de uma opção (pele, cor de cabelo, roupa).
func cor(lista: String, id: String) -> Color:
	for o in opcoes(lista):
		if o["id"] == id:
			return Color(str(o.get("cor", "#808080")))
	return Color(0.5, 0.5, 0.5)


## O disfarce que as roupas formam, ou {}.
func disfarce() -> Dictionary:
	for d in _cfg["disfarces"]:
		var ok := true
		for parte in d["pecas"]:
			if roupas.get(parte, "") != d["pecas"][parte]:
				ok = false
		if ok:
			return d
	return {}


## Efeito do disfarce vestido (ou o padrão, se não houver).
func efeito(chave: String, padrao: float = 1.0) -> float:
	return float(disfarce().get("efeito", {}).get(chave, padrao))


## Tudo num dicionário (para guardar ou passar adiante).
func como_dados() -> Dictionary:
	return {"sliders": sliders.duplicate(), "pele": pele, "cabelo": cabelo, "cor_do_cabelo": cor_do_cabelo, "barba": barba, "roupas": roupas.duplicate()}


func de_dados(d: Dictionary) -> void:
	for s in d.get("sliders", {}):
		definir_slider(s, float(d["sliders"][s]))
	for chave in ["pele", "cabelo", "cor_do_cabelo", "barba"]:
		if d.has(chave):
			set(chave, d[chave])
	for parte in d.get("roupas", {}):
		roupas[parte] = d["roupas"][parte]
