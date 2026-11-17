extends "res://tests/framework/test_case.gd"
## Determinismo do gerador aleatório do mundo (rules/determinismo.md).
## Obrigatório: nenhuma falha é tolerada pelo portão.

const OBRIGATORIO := true

const Rng := preload("res://core/rng.gd")
const BASELINE_PATH := "res://tests/baselines/rng.json"


func _draw(rng: RefCounted, stream_name: String, count: int) -> Array:
	var generator: RandomNumberGenerator = rng.stream(stream_name)
	var values := []
	for i in count:
		values.append(generator.randi())
	return values


func test_rng_mesma_semente_gera_mesma_sequencia() -> void:
	assert_eq(_draw(Rng.new(42), "criaturas", 20), _draw(Rng.new(42), "criaturas", 20))


func test_rng_sementes_diferentes_geram_sequencias_diferentes() -> void:
	assert_ne(_draw(Rng.new(42), "criaturas", 20), _draw(Rng.new(43), "criaturas", 20))


func test_rng_streams_com_nomes_diferentes_sao_diferentes() -> void:
	var rng := Rng.new(42)
	assert_ne(_draw(rng, "criaturas", 20), _draw(rng, "npcs", 20))


func test_rng_consumir_um_stream_nao_altera_outro() -> void:
	var rng := Rng.new(42)
	var expected := _draw(Rng.new(42), "npcs", 10)
	_draw(rng, "criaturas", 500)
	assert_eq(_draw(rng, "npcs", 10), expected)


func test_rng_valores_batem_com_a_referencia_entre_plataformas() -> void:
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASELINE_PATH))
	assert_true(baseline != null, "arquivo de referência legível")
	if baseline == null:
		return
	var world_seed := int(baseline["world_seed"])
	var stream_name: String = baseline["stream"]
	# Guardado como texto: inteiros acima de 2^53 perdem precisão como número em JSON.
	assert_eq(Rng.derive_seed(world_seed, stream_name), String(baseline["derive_seed"]).to_int(), "semente derivada")
	var expected: Array = baseline["first_randi"].map(func(v): return int(v))
	assert_eq(_draw(Rng.new(world_seed), stream_name, expected.size()), expected, "primeiros valores")
