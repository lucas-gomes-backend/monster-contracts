extends RefCounted
## Registro de eventos: a FONTE DA VERDADE do mundo (docs/10).
##
## Só aceita acréscimos, nunca edição. Pistas, memórias de testemunhas, boletins, cartas
## e o relatório do caso saem daqui, por isso são sempre coerentes entre si.
##
## Um evento é um dicionário:
##   {id, minuto, tipo, ator, local, dados}
##   id      inteiro sequencial (0, 1, 2, ...)
##   minuto  momento no relógio do mundo (core/tempo/relogio.gd)
##   tipo    ex.: "criatura.ataque", "npc.viu", "marca.depositada"
##   ator    quem fez (ex.: "lobisomem_br#07", "npc#231"), ou ""
##   local   onde (ex.: "paqueta/rua_3/lote_12"), ou ""
##   dados   detalhes do evento

var _eventos: Array[Dictionary] = []


## Acrescenta um evento e devolve uma cópia dele, já com id.
## Eventos entram em ordem de tempo: um evento anterior ao último é RECUSADO
## (devolve {} e o registro não muda).
func registrar(minuto: int, tipo: String, ator: String = "", local: String = "", dados: Dictionary = {}) -> Dictionary:
	if tipo.is_empty() or (not _eventos.is_empty() and minuto < _eventos[-1]["minuto"]):
		return {}
	var evento := {
		"id": _eventos.size(),
		"minuto": minuto,
		"tipo": tipo,
		"ator": ator,
		"local": local,
		"dados": dados.duplicate(true),
	}
	_eventos.append(evento)
	return evento.duplicate(true)


func tamanho() -> int:
	return _eventos.size()


## Um evento pelo id (cópia), ou {} se não existir.
func obter(id: int) -> Dictionary:
	if id < 0 or id >= _eventos.size():
		return {}
	return _eventos[id].duplicate(true)


## Busca eventos (cópias), em ordem de id. Filtros vazios são ignorados.
## "de" e "ate" são minutos, inclusivos; -1 = sem limite.
func buscar(tipo: String = "", ator: String = "", local: String = "", de: int = -1, ate: int = -1) -> Array[Dictionary]:
	var encontrados: Array[Dictionary] = []
	for evento in _eventos:
		if not tipo.is_empty() and evento["tipo"] != tipo:
			continue
		if not ator.is_empty() and evento["ator"] != ator:
			continue
		if not local.is_empty() and evento["local"] != local:
			continue
		if de >= 0 and evento["minuto"] < de:
			continue
		if ate >= 0 and evento["minuto"] > ate:
			continue
		encontrados.append(evento.duplicate(true))
	return encontrados


## Impressão digital do registro inteiro (SHA-256 do JSON com chaves ordenadas).
## Mesmo histórico = mesmo hash, em qualquer máquina.
func hash_canonico() -> String:
	return JSON.stringify(_eventos, "", true).sha256_text()
