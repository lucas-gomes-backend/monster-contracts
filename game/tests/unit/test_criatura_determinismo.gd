extends "res://tests/framework/test_case.gd"
## Determinismo da simulação de criaturas (rules/determinismo.md).

const Catalogo := preload("res://core/dados/catalogo.gd")
const Criatura := preload("res://core/criaturas/criatura.gd")
const Rng := preload("res://core/rng.gd")
const Barramento := preload("res://core/eventos/barramento.gd")
const Relogio := preload("res://core/tempo/relogio.gd")

const LOCAIS := ["paqueta/galinheiro_1", "paqueta/cemiterio", "morro_sao_bento/chiqueiro"]


## Simula as espécies pedidas no mesmo mundo, por 60 dias. Devolve o registro.
func _mundo(semente: int, especies: Array) -> RefCounted:
	var criaturas: Dictionary = Catalogo.carregar_criaturas()["criaturas"]
	var config: Dictionary = Catalogo.carregar_config_criaturas()["dados"]
	var rng := Rng.new(semente)
	var barramento := Barramento.new()
	var inicio := Relogio.minutos_de(2015, 11, 9)
	var vivas := []
	for especie in especies:
		var c := Criatura.new(criaturas[especie], "%s#1" % especie, rng, barramento, config, LOCAIS)
		c.despertar(inicio, "teste")
		vivas.append(c)
	for hora in 60 * 24:
		for c in vivas:
			c.passo(inicio + hora * 60)
	return barramento.registro


func test_criaturas_mesma_semente_gera_o_mesmo_mundo() -> void:
	var especies := ["lobisomem_br", "corpo_seco", "mula_sem_cabeca"]
	assert_eq(_mundo(42, especies).hash_canonico(), _mundo(42, especies).hash_canonico())


func test_criaturas_semente_diferente_gera_mundo_diferente() -> void:
	var especies := ["lobisomem_br", "corpo_seco", "mula_sem_cabeca"]
	assert_ne(_mundo(42, especies).hash_canonico(), _mundo(43, especies).hash_canonico())


func test_criaturas_outra_especie_no_mundo_nao_muda_o_que_uma_faz() -> void:
	# Streams independentes: o lobisomem age igual, com ou sem o corpo-seco no mundo.
	var sozinho: Array = _mundo(42, ["lobisomem_br"]).buscar("", "lobisomem_br#1")
	var acompanhado: Array = _mundo(42, ["lobisomem_br", "corpo_seco"]).buscar("", "lobisomem_br#1")
	assert_eq(sozinho.size(), acompanhado.size(), "mesma quantidade de eventos")
	var iguais := sozinho.size() == acompanhado.size()
	for i in mini(sozinho.size(), acompanhado.size()):
		var a: Dictionary = sozinho[i]
		var b: Dictionary = acompanhado[i]
		if a["minuto"] != b["minuto"] or a["tipo"] != b["tipo"] or a["local"] != b["local"]:
			iguais = false
	assert_true(iguais, "mesmos eventos, nos mesmos momentos e lugares")
