extends "res://tests/framework/test_case.gd"
## Testa o próprio framework: as asserções precisam detectar falhas.

const TestCase := preload("res://tests/framework/test_case.gd")


func _probe() -> RefCounted:
	return TestCase.new()


func test_assert_eq_detecta_diferenca() -> void:
	var p := _probe()
	p.assert_eq(1, 2)
	assert_eq(p._failures.size(), 1)


func test_assert_eq_diferencia_tipos() -> void:
	var p := _probe()
	p.assert_eq(1, 1.0)
	assert_eq(p._failures.size(), 1, "int e float são tipos diferentes")


func test_assert_eq_aceita_igual() -> void:
	var p := _probe()
	p.assert_eq("lobisomem", "lobisomem")
	assert_eq(p._failures.size(), 0)


func test_assert_almost_eq() -> void:
	var p := _probe()
	p.assert_almost_eq(0.95, 0.9500001)
	p.assert_almost_eq(0.95, 0.90)
	assert_eq(p._failures.size(), 1)


func test_assert_has() -> void:
	var p := _probe()
	p.assert_has(["curupira", "saci"], "saci")
	p.assert_has({"bairro": "Paquetá"}, "bairro")
	p.assert_has(["curupira"], "mula")
	assert_eq(p._failures.size(), 1)


func test_skip_e_metricas() -> void:
	var p := _probe()
	p.skip("ainda não existe")
	p.record_metric("casos_validos", 1.4)
	assert_eq(p._skip_reason, "ainda não existe")
	assert_almost_eq(p._metrics["casos_validos"], 1.0, 0.0001, "métrica é limitada a 1.0")
