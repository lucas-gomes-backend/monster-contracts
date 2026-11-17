extends RefCounted
## Base de todos os testes.
##
## Cada arquivo de teste fica em res://tests/ com nome test_*.gd e estende este
## script. Cada método que começa com "test_" é um teste. O executor cria uma
## instância nova para cada teste, então não há estado compartilhado entre eles.
##
## Métricas: um teste pode registrar uma taxa (0.0 a 1.0) com record_metric().
## Toda métrica precisa ficar no portão (95% por padrão), senão a suíte falha.
## Exemplo da Fase 1: record_metric("casos_validos", validos / total).

var _failures: Array[String] = []
var _skip_reason: String = ""
var _metrics: Dictionary = {}


## Chamado antes de cada teste.
func before_each() -> void:
	pass


## Chamado depois de cada teste.
func after_each() -> void:
	pass


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		_fail("esperava verdadeiro", message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		_fail("esperava falso", message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		_fail("esperava %s, veio %s" % [var_to_str(expected), var_to_str(actual)], message)


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if typeof(actual) == typeof(unexpected) and actual == unexpected:
		_fail("não esperava %s" % var_to_str(unexpected), message)


func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.0001, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		_fail("esperava %f (±%f), veio %f" % [expected, tolerance, actual], message)


func assert_gte(actual: float, minimum: float, message: String = "") -> void:
	if actual < minimum:
		_fail("esperava pelo menos %s, veio %s" % [str(minimum), str(actual)], message)


func assert_has(collection: Variant, item: Variant, message: String = "") -> void:
	var found := false
	if collection is Array or collection is PackedStringArray:
		found = item in collection
	elif collection is Dictionary:
		found = collection.has(item)
	elif collection is String:
		found = collection.contains(str(item))
	if not found:
		_fail("esperava encontrar %s" % var_to_str(item), message)


## Falha o teste na hora, com uma mensagem.
func fail(message: String) -> void:
	_failures.append(message)


## Marca o teste como pulado. Testes pulados não contam no portão.
## Use para testes de sistemas que ainda não existem.
func skip(reason: String) -> void:
	_skip_reason = reason


## Registra uma taxa entre 0.0 e 1.0 que precisa ficar no portão.
func record_metric(metric_name: String, ratio: float) -> void:
	_metrics[metric_name] = clampf(ratio, 0.0, 1.0)


func _fail(what: String, message: String) -> void:
	_failures.append(what if message.is_empty() else "%s: %s" % [message, what])
