extends RefCounted
## Aleatoriedade determinística do mundo. É a ÚNICA fonte de aleatoriedade do núcleo
## (rules/determinismo.md). Mesma semente + mesmo nome de stream = mesma sequência,
## em qualquer máquina.
##
## Cada sistema pede o próprio stream, por nome (ex.: "criaturas", "npc:231",
## "caso:4821"). Streams são independentes: criar ou consumir um não muda os outros.

var _world_seed: int


func _init(world_seed: int) -> void:
	_world_seed = world_seed


## Semente principal do mundo.
func world_seed() -> int:
	return _world_seed


## Um gerador novo, já posicionado no início do stream pedido.
func stream(stream_name: String) -> RandomNumberGenerator:
	var generator := RandomNumberGenerator.new()
	generator.seed = derive_seed(_world_seed, stream_name)
	return generator


## Deriva uma semente estável a partir da semente-base e de um nome.
## Usa SHA-256 (igual em todas as plataformas) e mantém 60 bits positivos.
static func derive_seed(base_seed: int, key: String) -> int:
	var digest := ("%d|%s" % [base_seed, key]).sha256_text()
	return digest.substr(0, 15).hex_to_int()
