extends RefCounted
## Uma criatura viva no mundo: a máquina de estados da docs/03 ("Simulação").
##
##   dormente --(despertar/provocar)--> ativa --(janela + necessidade)--> cacando
##   cacando --(ataque)--> alimentada --(necessidade volta)--> cacando ...
##   janela fecha com a necessidade pendente --> escalando (nível sobe, vítimas pioram)
##   percebe o caçador --> reagindo (reação depende da inteligência)
##
## Tudo o que acontece vira evento no barramento (core/eventos). As marcas deixadas
## apontam para o evento de ataque que as causou ("evento_origem"), e é daí que nascem
## as pistas. Toda aleatoriedade vem do stream "criatura:<id>" do RNG do mundo.
##
## Chame passo(minuto) a cada hora de jogo, com minutos sempre crescentes.

const Relogio := preload("res://core/tempo/relogio.gd")

var ficha: Dictionary
var id: String
var estado := "dormente"
var nivel_escalada := 0

var _rng: RandomNumberGenerator
var _barramento: RefCounted
var _config: Dictionary
var _locais: Array
var _ultimo_alimento := -1
var _provocado := false
var _estava_na_janela := false
var _pendente_na_janela := false


func _init(ficha_criatura: Dictionary, instancia_id: String, rng_mundo: RefCounted, barramento: RefCounted, config: Dictionary, locais: Array) -> void:
	ficha = ficha_criatura
	id = instancia_id
	_rng = rng_mundo.stream("criatura:%s" % instancia_id)
	_barramento = barramento
	_config = config
	_locais = locais.duplicate()


## Acorda a criatura (o gatilho do caso aconteceu).
func despertar(minuto: int, gatilho: String) -> void:
	if estado != "dormente":
		return
	estado = "ativa"
	_publicar(minuto, "criatura.despertou", {"gatilho": gatilho})


## Alguém provocou a criatura (ex.: desmatamento para o Curupira). Também a desperta.
func provocar(minuto: int, motivo: String) -> void:
	despertar(minuto, motivo)
	_provocado = true
	_publicar(minuto, "criatura.provocada", {"motivo": motivo})


## A criatura percebeu que está sendo investigada.
func perceber_cacador(minuto: int) -> void:
	if estado == "dormente":
		return
	var reacao: String = _config["reacao_por_inteligencia"][ficha["inteligencia"]]
	estado = "reagindo"
	if reacao == "muda_de_rotina" and _locais.size() > 1:
		_locais.push_back(_locais.pop_front())
	_publicar(minuto, "criatura.reagiu", {"reacao": reacao})


## Um passo da simulação (uma hora de jogo).
func passo(minuto: int) -> void:
	if estado == "dormente":
		return
	if estado == "reagindo":
		estado = "ativa"

	var dentro := em_janela(minuto)
	if _estava_na_janela and not dentro and _pendente_na_janela:
		_escalar(minuto)
	_estava_na_janela = dentro
	if not dentro:
		return

	if not necessidade_pendente(minuto):
		estado = "alimentada"
		_pendente_na_janela = false
		return

	_pendente_na_janela = true
	if estado != "cacando":
		estado = "cacando"
		_publicar(minuto, "criatura.caca_iniciada", {"nivel_escalada": nivel_escalada})

	var chance: float = _config["chance_ataque_por_hora"]
	if ficha["ciclo"].get("lua", "") == "cheia_bonus" and Relogio.new(minuto).fase_lua() == "cheia":
		chance += _config["bonus_lua_cheia"]
	if _rng.randf() < chance:
		_atacar(minuto)


## A criatura pode agir neste minuto? (horário da ficha + dias da semana)
func em_janela(minuto: int) -> bool:
	var ciclo: Dictionary = ficha["ciclo"]
	var janela: Array = _config["janelas"][ciclo["horario"]]
	var inicio := int(janela[0])
	var fim := int(janela[1])
	var data := Relogio.data_de(minuto)
	var hora: int = data["hora"]
	var cruza_meia_noite := inicio > fim
	var dentro := (hora >= inicio or hora < fim) if cruza_meia_noite else (hora >= inicio and hora < fim)
	if not dentro:
		return false

	var dias: Array = ciclo.get("dias", [])
	if dias.is_empty():
		return true
	# A janela que cruza a meia-noite pertence ao dia em que começou.
	var dia_semana: int = data["dia_semana"]
	if cruza_meia_noite and hora < fim:
		dia_semana = posmod(dia_semana - 1, 7)
	var nome_dia: String = Relogio.DIAS[dia_semana]
	if dias.size() == 2 and _consecutivos(dias[0], dias[1]):
		return nome_dia == dias[0]  # "quinta, sexta" = a noite de quinta para sexta
	return nome_dia in dias


func necessidade_pendente(minuto: int) -> bool:
	var frequencia: String = ficha["necessidade"]["frequencia"]
	match frequencia:
		"continua":
			return true
		"quando_provocada":
			return _provocado
	var periodo_min: int = int(_config["periodo_necessidade_horas"][frequencia]) * 60
	return _ultimo_alimento < 0 or minuto - _ultimo_alimento >= periodo_min


func _atacar(minuto: int) -> void:
	var vitimas: Array = ficha["caca"]["vitimas"]
	var limite := mini(nivel_escalada, vitimas.size() - 1)
	var alvo: String = vitimas[_rng.randi_range(0, limite)]
	var local: String = _locais[_rng.randi_range(0, _locais.size() - 1)] if not _locais.is_empty() else ""
	var ataque := _publicar(minuto, "criatura.ataque", {"alvo": alvo, "nivel_escalada": nivel_escalada}, local)

	var onde_valido: Array = _config["onde_deposita_marca"]
	for marca in ficha["marcas"]:
		if not marca["onde"] in onde_valido:
			continue
		if _rng.randf() < float(_config["chance_marca"][marca["freq"]]):
			_publicar(minuto, "marca.depositada", {
				"tag": marca["tag"],
				"onde": marca["onde"],
				"detectar": marca["detectar"],
				"freq": marca["freq"],
				"evento_origem": ataque["id"],
			}, local)

	_publicar(minuto, "criatura.alimentou", {"evento_origem": ataque["id"]}, local)
	_ultimo_alimento = minuto
	_provocado = false
	_pendente_na_janela = false
	estado = "alimentada"


func _escalar(minuto: int) -> void:
	estado = "escalando"
	if nivel_escalada < int(_config["escalada_maxima"]):
		nivel_escalada += 1
		_publicar(minuto, "criatura.escalou", {"nivel_escalada": nivel_escalada})


func _publicar(minuto: int, tipo: String, dados: Dictionary, local: String = "") -> Dictionary:
	var completos := dados.duplicate()
	completos["especie"] = ficha["id"]
	return _barramento.publicar(minuto, tipo, id, local, completos)


static func _consecutivos(a: String, b: String) -> bool:
	var ia := Relogio.DIAS.find(a)
	var ib := Relogio.DIAS.find(b)
	return ia >= 0 and ib >= 0 and posmod(ia + 1, 7) == ib
