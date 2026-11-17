extends RefCounted
## Procura símbolos proibidos no código do núcleo (rules/determinismo.md e
## rules/implementacao.md). Usado pelos testes de arquitetura.

const RULES := [
	{"pattern": "\\brandi(_range)?\\s*\\(", "why": "aleatoriedade global sem semente; use core/rng.gd"},
	{"pattern": "\\brandf(_range|n)?\\s*\\(", "why": "aleatoriedade global sem semente; use core/rng.gd"},
	{"pattern": "\\brandomize\\s*\\(", "why": "aleatoriedade global sem semente; use core/rng.gd"},
	{"pattern": "(^|[^.\\w])seed\\s*\\(", "why": "semente global; use core/rng.gd"},
	{"pattern": "RandomNumberGenerator\\.new\\s*\\(", "why": "gerador solto; use core/rng.gd", "allow": ["res://core/rng.gd"]},
	{"pattern": "\\bTime\\.get_", "why": "relógio da máquina; use o relógio do mundo"},
	{"pattern": "\\bOS\\.get_(unix_time|ticks|system_time|datetime)", "why": "relógio da máquina; use o relógio do mundo"},
	{"pattern": "^\\s*extends\\s+(Node|Node2D|Node3D|Control|CanvasItem|CanvasLayer|Viewport)\\b", "why": "o núcleo não depende de nós nem de cenas"},
	{"pattern": "\\bget_tree\\s*\\(", "why": "o núcleo não acessa a árvore de cenas"},
	{"pattern": "\\bget_node(_or_null)?\\s*\\(", "why": "o núcleo não acessa nós"},
	{"pattern": "res://(presentation|ui)/", "why": "o núcleo não referencia apresentação nem interface"},
]

var _compiled: Array = []


func _init() -> void:
	for rule in RULES:
		var regex := RegEx.new()
		regex.compile(rule["pattern"])
		_compiled.append({"regex": regex, "why": rule["why"], "allow": rule.get("allow", [])})


## Devolve as violações de um texto, no formato "arquivo:linha: motivo".
func scan_source(source: String, file_path: String) -> Array[String]:
	var violations: Array[String] = []
	var lines := source.split("\n")
	for i in lines.size():
		var code := _strip_comment(lines[i])
		if code.strip_edges().is_empty():
			continue
		for rule in _compiled:
			if file_path in rule["allow"]:
				continue
			if rule["regex"].search(code):
				violations.append("%s:%d: %s" % [file_path, i + 1, rule["why"]])
	return violations


## Varre todos os .gd de uma pasta, recursivamente.
func scan_dir(dir_path: String) -> Dictionary:
	var result := {"files": 0, "violations": [] as Array[String]}
	for path in list_scripts(dir_path):
		result["files"] += 1
		result["violations"].append_array(scan_source(FileAccess.get_file_as_string(path), path))
	return result


static func list_scripts(dir_path: String) -> Array[String]:
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
				found.append_array(list_scripts(full))
		elif entry.ends_with(".gd"):
			found.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
	found.sort()
	return found


## Remove o comentário e o conteúdo das strings de uma linha, para que só o código
## de verdade seja analisado. As strings viram aspas vazias.
## Exceção: caminhos "res://" continuam visíveis, porque referenciar apresentação
## por caminho é justamente o que uma das regras proíbe.
static func _strip_comment(line: String) -> String:
	var out := ""
	var quote := ""
	var literal := ""
	var i := 0
	while i < line.length():
		var c := line[i]
		if quote.is_empty():
			if c == "#":
				break
			if c == "\"" or c == "'":
				quote = c
				literal = ""
			out += c
		elif c == "\\":
			i += 1
		elif c == quote:
			if literal.begins_with("res://"):
				out += literal
			out += c
			quote = ""
		else:
			literal += c
		i += 1
	return out
