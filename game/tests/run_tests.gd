extends SceneTree
## Executor de testes com portão de qualidade.
##
## Uso (na pasta do repositório):
##   godot --headless --path game -s res://tests/run_tests.gd
##   godot --headless --path game -s res://tests/run_tests.gd -- --gate=0.95 --filter=gerador
##
## Regras do portão:
##   1. A taxa de testes aprovados (sem contar os pulados) precisa ser >= ao portão.
##   2. Toda métrica registrada com record_metric() precisa ser >= ao portão.
##   3. Precisa existir pelo menos um teste executado.
##   4. Testes OBRIGATÓRIOS não podem falhar nenhuma vez: tudo em res://tests/arch/
##      e todo arquivo que declara `const OBRIGATORIO := true` (ex.: determinismo).
## Se alguma regra falhar, o processo termina com código 1 (o CI fica vermelho).

const DEFAULT_GATE := 0.95
const TESTS_ROOT := "res://tests"
const REPORT_PATH := "user://test_report.json"

var _gate := DEFAULT_GATE
var _filter := ""


func _initialize() -> void:
	_parse_args()
	var exit_code := _run()
	quit(exit_code)


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--gate="):
			_gate = clampf(arg.trim_prefix("--gate=").to_float(), 0.0, 1.0)
		elif arg.begins_with("--filter="):
			_filter = arg.trim_prefix("--filter=").to_lower()


func _run() -> int:
	var files := _find_test_files(TESTS_ROOT)
	files.sort()

	var passed := 0
	var failed := 0
	var skipped := 0
	var failures: Array[String] = []
	var mandatory_failures: Array[String] = []
	var metrics: Dictionary = {}

	print("")
	print("== Testes (portão de %d%%) ==" % roundi(_gate * 100.0))

	for path in files:
		var script: Script = load(path)
		if script == null or not script.can_instantiate():
			failed += 1
			failures.append("%s: não foi possível carregar o script" % path)
			print("  [ERRO] %s" % path)
			continue

		var mandatory: bool = path.begins_with(TESTS_ROOT.path_join("arch")) or script.get_script_constant_map().get("OBRIGATORIO", false) == true

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
				print("  [FALHA]  %s%s" % [label, " (OBRIGATÓRIO)" if mandatory else ""])
				for f in test._failures:
					print("           - %s" % f)
					failures.append("%s: %s" % [label, f])
				if mandatory:
					mandatory_failures.append(label)

	var executed := passed + failed
	var pass_rate := (float(passed) / executed) if executed > 0 else 0.0

	print("")
	print("Aprovados: %d  Falhas: %d  Pulados: %d" % [passed, failed, skipped])
	print("Taxa de aprovação: %.1f%% (portão: %.1f%%)" % [pass_rate * 100.0, _gate * 100.0])

	var gate_ok := executed > 0 and pass_rate >= _gate
	if executed == 0:
		print("PORTÃO: nenhum teste foi executado.")
	if not mandatory_failures.is_empty():
		gate_ok = false
		print("Testes obrigatórios com falha: %d (não podem falhar nenhuma vez)" % mandatory_failures.size())

	for metric_label in metrics:
		var value: float = metrics[metric_label]
		var ok := value >= _gate
		print("Métrica %s: %.1f%% %s" % [metric_label, value * 100.0, "OK" if ok else "ABAIXO DO PORTÃO"])
		if not ok:
			gate_ok = false

	_write_report(passed, failed, skipped, pass_rate, metrics, failures, gate_ok)

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


func _write_report(passed: int, failed: int, skipped: int, pass_rate: float, metrics: Dictionary, failures: Array[String], gate_ok: bool) -> void:
	var report := {
		"gate": _gate,
		"passed": passed,
		"failed": failed,
		"skipped": skipped,
		"pass_rate": pass_rate,
		"metrics": metrics,
		"failures": failures,
		"gate_ok": gate_ok,
	}
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "  "))
