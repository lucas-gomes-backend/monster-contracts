extends "res://tests/framework/test_case.gd"
## Regras de arquitetura do núcleo (rules/determinismo.md, rules/implementacao.md).
## O núcleo (res://core) não usa aleatoriedade solta, nem o relógio da máquina,
## nem depende de nós, cenas, apresentação ou interface.

const CodeScanner := preload("res://tests/framework/code_scanner.gd")


func test_nucleo_codigo_atual_nao_tem_simbolos_proibidos() -> void:
	var result := CodeScanner.new().scan_dir("res://core")
	assert_gte(result["files"], 1, "o núcleo tem scripts para varrer")
	for violation in result["violations"]:
		fail(violation)


func test_scanner_randi_global_e_detectado() -> void:
	assert_eq(CodeScanner.new().scan_source("var x := randi() % 6", "res://core/x.gd").size(), 1)


func test_scanner_relogio_da_maquina_e_detectado() -> void:
	assert_eq(CodeScanner.new().scan_source("var t := Time.get_unix_time_from_system()", "res://core/x.gd").size(), 1)


func test_scanner_dependencia_de_cena_e_detectada() -> void:
	var source := "extends Node3D\nfunc f():\n\tget_tree().quit()\n\tvar s = load(\"res://presentation/x.tscn\")"
	assert_eq(CodeScanner.new().scan_source(source, "res://core/x.gd").size(), 3)


func test_scanner_comentarios_e_strings_nao_contam() -> void:
	var source := "# randi() só no comentário\nvar dica := \"use rng, não # randi()\""
	assert_eq(CodeScanner.new().scan_source(source, "res://core/x.gd").size(), 0)


func test_scanner_gerador_permitido_so_no_rng() -> void:
	var line := "var g := RandomNumberGenerator.new()"
	var scanner := CodeScanner.new()
	assert_eq(scanner.scan_source(line, "res://core/rng.gd").size(), 0, "permitido em core/rng.gd")
	assert_eq(scanner.scan_source(line, "res://core/outro.gd").size(), 1, "proibido no resto do núcleo")


func test_scanner_sorteio_num_stream_do_mundo_nao_conta() -> void:
	var source := "var a := _rng.randi_range(0, 3)\nvar b := gerador.randf()"
	assert_eq(CodeScanner.new().scan_source(source, "res://core/x.gd").size(), 0)


func test_scanner_metodo_seed_de_objeto_nao_conta() -> void:
	assert_eq(CodeScanner.new().scan_source("generator.seed = 3", "res://core/x.gd").size(), 0)
