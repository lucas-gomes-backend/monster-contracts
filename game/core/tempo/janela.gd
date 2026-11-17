extends RefCounted
## Janela de horário: "das X às Y", opcionalmente só em certos dias da semana.
## Janelas que cruzam a meia-noite (ex.: 20h às 6h) pertencem ao dia em que começaram.

const Relogio := preload("res://core/tempo/relogio.gd")


## O minuto está dentro da janela [inicio, fim) nos dias pedidos (vazio = todo dia)?
static func dentro(minuto: int, inicio: int, fim: int, dias: Array = []) -> bool:
	var data := Relogio.data_de(minuto)
	var hora: int = data["hora"]
	var cruza := inicio > fim
	var na_hora := (hora >= inicio or hora < fim) if cruza else (hora >= inicio and hora < fim)
	if not na_hora:
		return false
	if dias.is_empty():
		return true
	var dia_semana: int = data["dia_semana"]
	if cruza and hora < fim:
		dia_semana = posmod(dia_semana - 1, 7)
	return Relogio.DIAS[dia_semana] in dias
