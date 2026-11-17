extends RefCounted
## Barramento de eventos (docs/10): um sistema publica, os interessados reagem.
##
## Todo evento publicado entra primeiro no registro (fonte da verdade) e depois é
## entregue aos assinantes, na ordem em que assinaram.
##
## Eventos publicados DE DENTRO de um assinante entram numa fila e são entregues
## depois que o evento atual terminar de ser entregue (ordem estável, sem recursão).

const Registro := preload("res://core/eventos/registro.gd")

var registro: RefCounted
var _assinantes: Dictionary = {}  # tipo -> Array[Callable]; "*" recebe todos
var _ordem_tipos: Array[String] = []
var _fila: Array[Dictionary] = []
var _entregando := false


func _init(registro_existente: RefCounted = null) -> void:
	registro = registro_existente if registro_existente != null else Registro.new()


## Assina um tipo de evento ("*" para todos). O assinante recebe o evento (cópia).
func assinar(tipo: String, assinante: Callable) -> void:
	if not _assinantes.has(tipo):
		_assinantes[tipo] = []
		_ordem_tipos.append(tipo)
	_assinantes[tipo].append(assinante)


## Registra o evento e entrega aos assinantes. Devolve o evento registrado,
## ou {} se o registro o recusou (nesse caso, ninguém recebe nada).
func publicar(minuto: int, tipo: String, ator: String = "", local: String = "", dados: Dictionary = {}) -> Dictionary:
	var evento: Dictionary = registro.registrar(minuto, tipo, ator, local, dados)
	if evento.is_empty():
		return {}
	_fila.append(evento)
	if not _entregando:
		_esvaziar_fila()
	return evento


## Remove todos os assinantes. Chame ao descartar o barramento: assinantes que guardam
## referência ao próprio barramento formam um ciclo, e o ciclo não é liberado sozinho.
func encerrar() -> void:
	_assinantes.clear()
	_ordem_tipos.clear()
	_fila.clear()


func _esvaziar_fila() -> void:
	_entregando = true
	while not _fila.is_empty():
		var evento: Dictionary = _fila.pop_front()
		for assinante in _assinantes.get(evento["tipo"], []):
			assinante.call(evento.duplicate(true))
		for assinante in _assinantes.get("*", []):
			assinante.call(evento.duplicate(true))
	_entregando = false
