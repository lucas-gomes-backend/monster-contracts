extends RefCounted
## Caminhos a pé pelas ruas de um bairro real: um grafo com pontos ao longo de cada rua
## (a cada PASSO metros) e ligações onde as ruas se encontram. As pessoas andam por ele,
## e não atravessando prédios.

const Lotes := preload("res://core/cidade/lotes.gd")

const PASSO := 6.0
## Pontos de ruas diferentes a menos disto viram um cruzamento.
const CRUZAMENTO := 3.0

var _grafo := AStar2D.new()


func _init(ruas: Array) -> void:
	var proximo := 0
	var por_celula := {}  # para achar pontos perto sem comparar todos com todos
	for rua in ruas:
		var p := Lotes._pontos(rua["pontos"])
		var anterior := -1
		for i in p.size() - 1:
			var partes := maxi(1, int(ceil(p[i].distance_to(p[i + 1]) / PASSO)))
			for k in partes + (1 if i == p.size() - 2 else 0):
				var ponto := p[i].lerp(p[i + 1], float(k) / partes)
				_grafo.add_point(proximo, ponto)
				if anterior >= 0:
					_grafo.connect_points(anterior, proximo)
				var celula := Vector2i(floori(ponto.x / CRUZAMENTO), floori(ponto.y / CRUZAMENTO))
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						for outro in por_celula.get(celula + Vector2i(dx, dy), []):
							if outro != anterior and _grafo.get_point_position(outro).distance_to(ponto) <= CRUZAMENTO:
								_grafo.connect_points(outro, proximo)
				if not por_celula.has(celula):
					por_celula[celula] = []
				por_celula[celula].append(proximo)
				anterior = proximo
				proximo += 1


## Caminho de um ponto a outro pelas ruas: começa e termina nos próprios pontos.
func caminho(de: Vector2, para: Vector2) -> PackedVector2Array:
	var saida := PackedVector2Array([de])
	if _grafo.get_point_count() > 0:
		var a := _grafo.get_closest_point(de)
		var b := _grafo.get_closest_point(para)
		saida.append_array(_grafo.get_point_path(a, b))
	saida.append(para)
	return saida


## O ponto das ruas mais perto de p (onde parar o carro numa viagem rápida).
func mais_perto(p: Vector2) -> Vector2:
	if _grafo.get_point_count() == 0:
		return p
	return _grafo.get_point_position(_grafo.get_closest_point(p))


func pontos() -> int:
	return _grafo.get_point_count()


## Um ponto qualquer das ruas (para quem anda a esmo), sorteado pelo gerador dado.
func ponto_qualquer(gerador: RandomNumberGenerator) -> Vector2:
	return _grafo.get_point_position(gerador.randi_range(0, _grafo.get_point_count() - 1))
