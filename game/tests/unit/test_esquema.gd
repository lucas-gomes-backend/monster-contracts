extends "res://tests/framework/test_case.gd"
## Validador de JSON Schema (core/dados/esquema.gd).

const Esquema := preload("res://core/dados/esquema.gd")

const SCHEMA := {
	"type": "object",
	"additionalProperties": false,
	"required": ["id", "perigo"],
	"properties": {
		"id": {"type": "string", "pattern": "^[a-z_]+$"},
		"perigo": {"type": "integer", "minimum": 1, "maximum": 5},
		"tipo": {"enum": ["a", "b"]},
		"lista": {"type": "array", "minItems": 1, "uniqueItems": true, "items": {"$ref": "#/$defs/letra"}},
		"opcional": {"type": ["string", "null"]},
	},
	"$defs": {"letra": {"enum": ["x", "y"]}},
}


func _erros(valor: Variant) -> Array[String]:
	return Esquema.new(SCHEMA).validate(valor)


func test_esquema_objeto_valido_nao_tem_erros() -> void:
	assert_eq(_erros({"id": "lobo", "perigo": 3.0, "tipo": "a", "lista": ["x", "y"], "opcional": null}).size(), 0)


func test_esquema_campo_obrigatorio_ausente_e_erro() -> void:
	assert_eq(_erros({"id": "lobo"}).size(), 1)


func test_esquema_tipo_errado_e_erro() -> void:
	assert_eq(_erros({"id": 3, "perigo": 2}).size(), 1)


func test_esquema_inteiro_com_fracao_e_erro() -> void:
	assert_eq(_erros({"id": "lobo", "perigo": 2.5}).size(), 1)


func test_esquema_fora_do_minimo_e_maximo_e_erro() -> void:
	assert_eq(_erros({"id": "lobo", "perigo": 0}).size(), 1, "abaixo do mínimo")
	assert_eq(_erros({"id": "lobo", "perigo": 9}).size(), 1, "acima do máximo")


func test_esquema_valor_fora_do_enum_e_erro() -> void:
	assert_eq(_erros({"id": "lobo", "perigo": 1, "tipo": "z"}).size(), 1)


func test_esquema_padrao_nao_seguido_e_erro() -> void:
	assert_eq(_erros({"id": "Lobo Mau", "perigo": 1}).size(), 1)


func test_esquema_campo_desconhecido_e_erro() -> void:
	assert_eq(_erros({"id": "lobo", "perigo": 1, "extra": true}).size(), 1)


func test_esquema_lista_vazia_repetida_ou_ref_invalida_e_erro() -> void:
	assert_eq(_erros({"id": "lobo", "perigo": 1, "lista": []}).size(), 1, "lista vazia")
	assert_eq(_erros({"id": "lobo", "perigo": 1, "lista": ["x", "x"]}).size(), 1, "item repetido")
	assert_eq(_erros({"id": "lobo", "perigo": 1, "lista": ["z"]}).size(), 1, "item fora do enum via $ref")
