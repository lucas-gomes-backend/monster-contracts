extends RefCounted
## Relógio do mundo (docs/13, Parte A). É a ÚNICA fonte de tempo do núcleo
## (rules/determinismo.md): nada de relógio da máquina.
##
## O tempo é um inteiro: minutos desde 1970-01-01 00:00, no horário local de Santos.
## Toda conta é feita com inteiros, para dar o mesmo resultado em qualquer máquina.

const DIAS := ["domingo", "segunda", "terca", "quarta", "quinta", "sexta", "sabado"]
const MINUTOS_POR_DIA := 1440

## Início e fim da noite (horas). A noite vai das 18h às 6h.
const INICIO_NOITE := 18
const FIM_NOITE := 6

## Lua: duração média do mês sinódico (29,53 dias) em minutos, e uma lua nova de referência
## (2000-01-06 18:14 UTC = 15:14 no horário de Santos). A fase é calculada pela média,
## com erro de até cerca de meio dia, o que basta para o jogo.
const MES_LUNAR_MIN := 42524
const LUA_NOVA_REF := {"ano": 2000, "mes": 1, "dia": 6, "hora": 15, "minuto": 14}
## Uma fase "cheia" ou "nova" dura de 1 dia antes a 1 dia depois do pico.
const MEIA_JANELA_LUA_MIN := 1440

var _minutos: int


func _init(minutos_iniciais: int = 0) -> void:
	_minutos = minutos_iniciais


## Cria um relógio numa data e hora do calendário.
static func de_data(ano: int, mes: int, dia: int, hora: int = 0, minuto: int = 0) -> RefCounted:
	return load("res://core/tempo/relogio.gd").new(minutos_de(ano, mes, dia, hora, minuto))


## Minutos absolutos de uma data e hora.
static func minutos_de(ano: int, mes: int, dia: int, hora: int = 0, minuto: int = 0) -> int:
	return dias_de_civil(ano, mes, dia) * MINUTOS_POR_DIA + hora * 60 + minuto


func minutos() -> int:
	return _minutos


## Avança o relógio. O tempo nunca volta: um valor negativo é recusado
## (devolve false e o relógio não muda).
func avancar(minutos_a_mais: int) -> bool:
	if minutos_a_mais < 0:
		return false
	_minutos += minutos_a_mais
	return true


## A data atual: {ano, mes, dia, hora, minuto, dia_semana (0 = domingo), nome_dia}.
func data() -> Dictionary:
	return data_de(_minutos)


static func data_de(minutos_abs: int) -> Dictionary:
	var dias := _div(minutos_abs, MINUTOS_POR_DIA)
	var resto := minutos_abs - dias * MINUTOS_POR_DIA
	var civil := civil_de_dias(dias)
	var semana := posmod(dias + 4, 7)  # 1970-01-01 foi uma quinta-feira
	civil["hora"] = resto / 60
	civil["minuto"] = resto % 60
	civil["dia_semana"] = semana
	civil["nome_dia"] = DIAS[semana]
	return civil


func eh_noite() -> bool:
	var h: int = data()["hora"]
	return h >= INICIO_NOITE or h < FIM_NOITE


## Verdadeiro durante a noite que começa no dia "dia_antes" e termina em "dia_depois".
## Ex.: noite_entre("quinta", "sexta") = quinta depois das 18h ou sexta antes das 6h.
func noite_entre(dia_antes: String, dia_depois: String) -> bool:
	var d := data()
	if d["nome_dia"] == dia_antes and d["hora"] >= INICIO_NOITE:
		return true
	return d["nome_dia"] == dia_depois and d["hora"] < FIM_NOITE


func eh_data(mes: int, dia: int) -> bool:
	var d := data()
	return d["mes"] == mes and d["dia"] == dia


func eh_sexta_feira_13() -> bool:
	var d := data()
	return d["dia"] == 13 and d["nome_dia"] == "sexta"


## Idade da lua em minutos desde a última lua nova (0 até MES_LUNAR_MIN - 1).
func idade_lua_min() -> int:
	var ref := minutos_de(LUA_NOVA_REF["ano"], LUA_NOVA_REF["mes"], LUA_NOVA_REF["dia"], LUA_NOVA_REF["hora"], LUA_NOVA_REF["minuto"])
	return posmod(_minutos - ref, MES_LUNAR_MIN)


## "nova", "crescente", "cheia" ou "minguante".
func fase_lua() -> String:
	var idade := idade_lua_min()
	var meio := MES_LUNAR_MIN / 2
	if idade <= MEIA_JANELA_LUA_MIN or idade >= MES_LUNAR_MIN - MEIA_JANELA_LUA_MIN:
		return "nova"
	if absi(idade - meio) <= MEIA_JANELA_LUA_MIN:
		return "cheia"
	return "crescente" if idade < meio else "minguante"


# --- Calendário gregoriano só com inteiros (algoritmo de Howard Hinnant) ---

static func dias_de_civil(ano: int, mes: int, dia: int) -> int:
	var y := ano - (1 if mes <= 2 else 0)
	var era := _div(y, 400)
	var yoe := y - era * 400
	var mp := mes - 3 if mes > 2 else mes + 9
	var doy := (153 * mp + 2) / 5 + dia - 1
	var doe := yoe * 365 + yoe / 4 - yoe / 100 + doy
	return era * 146097 + doe - 719468


static func civil_de_dias(dias: int) -> Dictionary:
	var z := dias + 719468
	var era := _div(z, 146097)
	var doe := z - era * 146097
	var yoe := (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
	var doy := doe - (365 * yoe + yoe / 4 - yoe / 100)
	var mp := (5 * doy + 2) / 153
	var dia := doy - (153 * mp + 2) / 5 + 1
	var mes := mp + 3 if mp < 10 else mp - 9
	var ano := yoe + era * 400 + (1 if mes <= 2 else 0)
	return {"ano": ano, "mes": mes, "dia": dia}


## Divisão inteira arredondando para baixo (também para números negativos).
static func _div(a: int, b: int) -> int:
	var q := a / b
	if a % b != 0 and ((a < 0) != (b < 0)):
		q -= 1
	return q
