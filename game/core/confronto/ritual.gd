extends RefCounted
## Um ritual em andamento (docs/06, "Rituais"). Passos em ordem, cada um com teste:
##   apertar: o marcador vai e volta; aperta quando ele está na janela
##   segurar: o marcador só anda enquanto segura; solta quando ele está na janela
##   palavra: escolhe a palavra certa. Errada: o ritual FALHA (materiais perdidos, recomeça)
## Errar o tempo perde o passo (repete). Uma interrupção (a criatura acerta o caçador)
## também perde o passo. A janela encolhe com o medo (tremor) e com o braço ferido
## (dificuldade > 1), e treme. O centro da janela de cada passo é sorteado no stream dado.
## Números e rituais em data/config/rituais.json.

const ANDANDO := "andando"
const COMPLETO := "completo"
const FALHOU := "falhou"

var def: Dictionary
var passo: int = 0
var situacao: String = ANDANDO
var erros_de_tempo: int = 0
## Palavras erradas que ainda não fazem o ritual falhar (habilidade Palavras certas).
var perdoes: int = 0
var centro: float = 0.5
var _cfg: Dictionary
var _g: RandomNumberGenerator


func _init(definicao: Dictionary, cfg_rituais: Dictionary, g: RandomNumberGenerator) -> void:
	def = definicao
	_cfg = cfg_rituais
	_g = g
	_novo_centro()


## Os bolsos têm os materiais? Se tiver, gasta. {"ok", "falta": item que falta}
static func gastar_materiais(definicao: Dictionary, bolsos: RefCounted) -> Dictionary:
	for m in definicao["materiais"]:
		if bolsos.quantidade(m["item"]) < int(m["quantidade"]):
			return {"ok": false, "falta": m["item"]}
	for m in definicao["materiais"]:
		for i in bolsos.itens.size():
			if bolsos.itens[i]["item"] == m["item"]:
				for k in int(m["quantidade"]):
					bolsos.usar(i)
	return {"ok": true, "falta": ""}


func passo_atual() -> Dictionary:
	return def["passos"][passo] if passo < def["passos"].size() else {}


## Posição do marcador (0 a 1) depois de t segundos: vai e volta.
func marcador(t: float) -> float:
	return 1.0 - absf(fposmod(t * float(_cfg["velocidade_do_marcador"]), 2.0) - 1.0)


## Largura da janela de acerto: encolhe com o medo e o braço ferido, nunca abaixo do mínimo.
func largura(tremor: float, dificuldade: float = 1.0) -> float:
	var base := float(_cfg["janela_base"]) * (1.0 - tremor * float(_cfg["medo_encolhe_a_janela"])) / maxf(dificuldade, 0.01)
	return maxf(base, float(_cfg["janela_minima"]))


## Onde a janela está no instante t (ela treme com o medo).
func centro_em(t: float, tremor: float) -> float:
	return clampf(centro + sin(t * 9.0) * tremor * float(_cfg["tremor_da_janela"]), 0.0, 1.0)


## Tentativa de tempo (apertar ou soltar) com o marcador em "posicao" no instante t.
## Acertou: o passo avança. Errou: o passo se perde e repete. Devolve se acertou.
func tentar(posicao: float, t: float, tremor: float, dificuldade: float = 1.0) -> bool:
	if situacao != ANDANDO or passo_atual().get("tipo", "") == "palavra":
		return false
	var acertou := absf(posicao - centro_em(t, tremor)) <= largura(tremor, dificuldade) / 2.0
	if acertou:
		_avancar()
	else:
		erros_de_tempo += 1
		_novo_centro()
	return acertou


## Escolhe uma palavra. Errada: o ritual falha.
func escolher(opcao: int) -> bool:
	var p := passo_atual()
	if situacao != ANDANDO or p.get("tipo", "") != "palavra":
		return false
	if opcao != int(p["certa"]):
		if perdoes > 0:
			perdoes -= 1
			return false
		situacao = FALHOU
		return false
	_avancar()
	return true


## A criatura interrompeu: o passo atual se perde (repete).
func interromper() -> void:
	if situacao == ANDANDO:
		_novo_centro()


func _avancar() -> void:
	passo += 1
	if passo >= def["passos"].size():
		situacao = COMPLETO
	else:
		_novo_centro()


func _novo_centro() -> void:
	centro = 0.25 + _g.randf() * 0.5
