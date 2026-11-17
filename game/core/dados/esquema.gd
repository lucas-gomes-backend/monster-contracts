extends RefCounted
## Validador de um subconjunto de JSON Schema, sem dependências.
##
## Entende: type (um ou vários), enum, required, properties, additionalProperties: false,
## items, minItems, maxItems, uniqueItems, minLength, pattern, minimum, maximum e
## $ref para "#/$defs/<nome>".
##
## Observação: o JSON do Godot lê todo número como float. "integer" aceita float sem
## parte fracionária.

var _root: Dictionary
var _regex_cache: Dictionary = {}


func _init(schema: Dictionary) -> void:
	_root = schema


## Devolve a lista de erros, no formato "caminho: problema". Vazia = válido.
func validate(value: Variant) -> Array[String]:
	var errors: Array[String] = []
	_check(value, _root, "$", errors)
	return errors


func _resolve(schema: Dictionary) -> Dictionary:
	if not schema.has("$ref"):
		return schema
	var ref: String = schema["$ref"]
	var prefix := "#/$defs/"
	if ref.begins_with(prefix) and _root.get("$defs", {}).has(ref.trim_prefix(prefix)):
		return _root["$defs"][ref.trim_prefix(prefix)]
	return {"$erro_ref": ref}


func _check(value: Variant, raw_schema: Dictionary, path: String, errors: Array[String]) -> void:
	var schema := _resolve(raw_schema)
	if schema.has("$erro_ref"):
		errors.append("%s: referência desconhecida %s" % [path, schema["$erro_ref"]])
		return

	if schema.has("type"):
		var types: Array = schema["type"] if schema["type"] is Array else [schema["type"]]
		var ok := false
		for t in types:
			if _is_type(value, t):
				ok = true
				break
		if not ok:
			errors.append("%s: esperava %s" % [path, " ou ".join(types)])
			return

	if schema.has("enum") and not _in_enum(value, schema["enum"]):
		errors.append("%s: valor %s fora da lista permitida" % [path, var_to_str(value)])
		return

	match typeof(value):
		TYPE_STRING:
			if schema.has("minLength") and value.length() < int(schema["minLength"]):
				errors.append("%s: texto curto demais" % path)
			if schema.has("pattern") and not _regex(schema["pattern"]).search(value):
				errors.append("%s: \"%s\" não segue o padrão %s" % [path, value, schema["pattern"]])
		TYPE_INT, TYPE_FLOAT:
			if schema.has("minimum") and value < schema["minimum"]:
				errors.append("%s: menor que o mínimo %s" % [path, str(schema["minimum"])])
			if schema.has("maximum") and value > schema["maximum"]:
				errors.append("%s: maior que o máximo %s" % [path, str(schema["maximum"])])
		TYPE_ARRAY:
			_check_array(value, schema, path, errors)
		TYPE_DICTIONARY:
			_check_object(value, schema, path, errors)


func _check_array(value: Array, schema: Dictionary, path: String, errors: Array[String]) -> void:
	if schema.has("minItems") and value.size() < int(schema["minItems"]):
		errors.append("%s: precisa de pelo menos %d itens" % [path, int(schema["minItems"])])
	if schema.has("maxItems") and value.size() > int(schema["maxItems"]):
		errors.append("%s: aceita no máximo %d itens" % [path, int(schema["maxItems"])])
	if schema.get("uniqueItems", false):
		var seen := {}
		for item in value:
			var key := var_to_str(item)
			if seen.has(key):
				errors.append("%s: item repetido %s" % [path, key])
			seen[key] = true
	if schema.has("items"):
		for i in value.size():
			_check(value[i], schema["items"], "%s[%d]" % [path, i], errors)


func _check_object(value: Dictionary, schema: Dictionary, path: String, errors: Array[String]) -> void:
	for key in schema.get("required", []):
		if not value.has(key):
			errors.append("%s: falta o campo obrigatório \"%s\"" % [path, key])
	var props: Dictionary = schema.get("properties", {})
	var keys := value.keys()
	keys.sort()
	for key in keys:
		if props.has(key):
			_check(value[key], props[key], "%s.%s" % [path, key], errors)
		elif schema.get("additionalProperties", true) == false:
			errors.append("%s: campo desconhecido \"%s\"" % [path, key])


func _is_type(value: Variant, type_name: String) -> bool:
	match type_name:
		"object":
			return value is Dictionary
		"array":
			return value is Array
		"string":
			return value is String
		"boolean":
			return value is bool
		"null":
			return value == null
		"number":
			return value is int or value is float
		"integer":
			return value is int or (value is float and is_equal_approx(value, floorf(value)))
	return false


func _in_enum(value: Variant, allowed: Array) -> bool:
	for option in allowed:
		if typeof(option) == typeof(value) and option == value:
			return true
	return false


func _regex(pattern: String) -> RegEx:
	if not _regex_cache.has(pattern):
		var regex := RegEx.new()
		regex.compile(pattern)
		_regex_cache[pattern] = regex
	return _regex_cache[pattern]
