extends RefCounted
## Negociação com a criatura (docs/06, "Negociar"): um confronto de diálogo. Só com criaturas
## astutas ou ardilosas e de disposição neutra ou protetora (o Curupira).
##   - A personalidade (sorteada pela semente) muda o que agrada e o que ofende.
##   - Cada oferta: agrada (satisfação +1), ofende (paciência -2) ou não serve (paciência -1).
##   - Acordo: oferecer o que atende o gatilho do caso ("por quê?") depois de agradar.
##     Os termos do acordo são o custo. Criatura ardilosa pode trair depois.
##   - Paciência zerada: recusa (vira confronto).
## Textos e números em data/config/negociacao.json.

const CONVERSANDO := "conversando"
const ACORDO := "acordo"
const RECUSA := "recusa"

var ficha: Dictionary
var gatilho: String
var personalidade: String
var paciencia: int
var satisfacao: int = 0
var situacao: String = CONVERSANDO
var termos: Array[String] = []
var traira: bool = false
var ultima_fala: String = ""
var _cfg: Dictionary
var _g: RandomNumberGenerator


## Dá para negociar com esta criatura?
static func pode(ficha_da_criatura: Dictionary) -> bool:
	return ficha_da_criatura["inteligencia"] in ["astuta", "ardilosa"] and ficha_da_criatura["disposicao"] in ["neutra", "protetora"] and not "humano" in ficha_da_criatura["familia"]


func _init(ficha_da_criatura: Dictionary, gatilho_do_caso: String, cfg_negociacao: Dictionary, g: RandomNumberGenerator) -> void:
	ficha = ficha_da_criatura
	gatilho = gatilho_do_caso
	_cfg = cfg_negociacao
	_g = g
	var personalidades: Array = _cfg["personalidades"]
	personalidade = personalidades[_g.randi_range(0, personalidades.size() - 1)]
	paciencia = int(_cfg["paciencia_inicial"])
	ultima_fala = "%s %s" % [_cfg["abertura"][personalidade], _cfg["exigencias"].get(gatilho, _cfg["exigencias"]["padrao"])]


func ofertas() -> Array:
	return _cfg["ofertas"]


## O caçador oferece a oferta i. "bolsos" para gastar o item que ela exige.
## Devolve a fala da criatura.
func oferecer(i: int, bolsos: RefCounted = null) -> String:
	if situacao != CONVERSANDO or i < 0 or i >= ofertas().size():
		return ultima_fala
	var oferta: Dictionary = ofertas()[i]
	var falas: Dictionary = _cfg["falas"]
	if oferta.has("exige_item"):
		if bolsos == null or not _gastar(bolsos, oferta["exige_item"]):
			ultima_fala = falas["sem_item"]
			return ultima_fala
	if personalidade in oferta["ofende"]:
		paciencia -= 2
		ultima_fala = falas["ofendeu"]
	elif personalidade in oferta["agrada"]:
		satisfacao += 1
		ultima_fala = falas["agradou"]
	elif not oferta.get("atende_gatilho", false):
		paciencia -= 1
		ultima_fala = falas["indiferente"]
	if oferta.get("atende_gatilho", false):
		if satisfacao >= int(_cfg["satisfacao_para_acordo"]):
			situacao = ACORDO
			termos.append(str(oferta.get("termo", "")))
			traira = _g.randf() < float(_cfg["chance_de_traicao"][ficha["inteligencia"]])
			ultima_fala = falas["acordo"]
			return ultima_fala
		paciencia -= 1
		ultima_fala = falas["indiferente"]
	if paciencia <= 0:
		situacao = RECUSA
		ultima_fala = falas["recusa"]
	return ultima_fala


func _gastar(bolsos: RefCounted, item: String) -> bool:
	for j in bolsos.itens.size():
		if bolsos.itens[j]["item"] == item and int(bolsos.itens[j]["quantidade"]) > 0:
			bolsos.usar(j)
			return true
	return false
