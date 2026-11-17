extends SceneTree
## Executor de testes com portão de qualidade.
##
## Uso (na pasta do repositório):
##   godot --headless --path game -s res://tests/run_tests.gd
##   godot --headless --path game -s res://tests/run_tests.gd -- --gate=0.95 --filter=gerador
##
## Regras do portão:
##   1. TODO teste executado precisa passar (100%). Pulados não contam.
##   2. Toda métrica registrada com record_metric() precisa ser >= ao portão de
##      métricas (--gate, 95% por padrão). Ex.: fração de casos gerados válidos.
##   3. Precisa existir pelo menos um teste executado.
##   4. Arquivo de teste que não carrega é falha.
## Se alguma regra falhar, o processo termina com código 1 (o CI fica vermelho).

const DEFAULT_METRIC_GATE := 0.95
const TESTS_ROOT := "res://tests"
const REPORT_PATH := "user://test_report.json"

var _metric_gate := DEFAULT_METRIC_GATE
var _filter := ""
var _rodou := false
var _quadros := 0
const QUADROS_ANTES_DE_RODAR := 3


func _initialize() -> void:
	_parse_args()


## Os testes rodam no primeiro quadro de física com delta, com a árvore de cenas já montada: assim um
## teste pode pôr uma cena na árvore e andar com move_and_slide (que usa o delta da física).
## Ver tests/unit/test_fisica_cacador.gd.
func _physics_process(_delta: float) -> bool:
	# Nos primeiros quadros o delta que os nós enxergam ainda é 0 (e move_and_slide não
	# anda): espera alguns quadros de física antes de rodar.
	_quadros += 1
	if not _rodou and _quadros >= QUADROS_ANTES_DE_RODAR:
		_rodou = true
		quit(_run())
	return false


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--gate="):
			_metric_gate = clampf(arg.trim_prefix("--gate=").to_float(), 0.0, 1.0)
		elif arg.begins_with("--filter="):
			_filter = arg.trim_prefix("--filter=").to_lower()


func _run() -> int:
	var files := _find_test_files(TESTS_ROOT)
	files.sort()

	var passed := 0
	var failed := 0
	var skipped := 0
	var failures: Array[String] = []
	var metrics: Dictionary = {}

	print("")
	print("== Testes (todos precisam passar; métricas >= %d%%) ==" % roundi(_metric_gate * 100.0))

	for path in files:
		var script: Script = load(path)
		if script == null or not script.can_instantiate():
			failed += 1
			failures.append("%s: o arquivo não carrega" % path)
			print("  [ERRO]   %s (o arquivo não carrega)" % path)
			continue

		for test_name in _test_methods(script):
			var label := "%s::%s" % [path.get_file().get_basename(), test_name]
			if not _filter.is_empty() and not label.to_lower().contains(_filter):
				continue

			var test: Object = script.new()
			test.before_each()
			test.call(test_name)
			test.after_each()

			for metric_name in test._metrics:
				metrics["%s/%s" % [label, metric_name]] = test._metrics[metric_name]

			if not test._skip_reason.is_empty():
				skipped += 1
				print("  [PULADO] %s (%s)" % [label, test._skip_reason])
			elif test._failures.is_empty():
				passed += 1
				print("  [OK]     %s" % label)
			else:
				failed += 1
				print("  [FALHA]  %s" % label)
				for f in test._failures:
					print("           - %s" % f)
					failures.append("%s: %s" % [label, f])

	var executed := passed + failed
	print("")
	print("Aprovados: %d  Falhas: %d  Pulados: %d" % [passed, failed, skipped])

	var gate_ok := executed > 0 and failed == 0
	if executed == 0:
		print("PORTÃO: nenhum teste foi executado.")

	for metric_label in metrics:
		var value: float = metrics[metric_label]
		var ok := value >= _metric_gate
		print("Métrica %s: %.1f%% %s" % [metric_label, value * 100.0, "OK" if ok else "ABAIXO DO PORTÃO"])
		if not ok:
			gate_ok = false

	_write_report(passed, failed, skipped, metrics, failures, gate_ok)

	print("PORTÃO: %s" % ("APROVADO" if gate_ok else "REPROVADO"))
	print("")
	return 0 if gate_ok else 1


func _find_test_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				found.append_array(_find_test_files(full))
		elif entry.begins_with("test_") and entry.ends_with(".gd"):
			found.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
	return found


func _test_methods(script: Script) -> Array[String]:
	var names: Array[String] = []
	for method in script.get_script_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with("test_") and not names.has(method_name):
			names.append(method_name)
	return names


func _write_report(passed: int, failed: int, skipped: int, metrics: Dictionary, failures: Array[String], gate_ok: bool) -> void:
	var report := {
		"metric_gate": _metric_gate,
		"passed": passed,
		"failed": failed,
		"skipped": skipped,
		"metrics": metrics,
		"failures": failures,
		"gate_ok": gate_ok,
	}
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "  "))
