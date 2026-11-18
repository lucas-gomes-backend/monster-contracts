extends RefCounted
## Quem faz divisa com quem entre os bairros do mapa real, e em que bairro um ponto está.
## Todos os bairros usam a mesma origem (tools/cidade/config.json): os limites se encaixam,
## então dá para andar de um para o outro sem tela de carregamento (docs/07, "Bordas").

## Dois limites a menos disto (metros) contam como divisa: os dados do mapa têm frestas.
const DISTANCIA_DE_DIVISA := 8.0


## {id: [ids vizinhos em ordem]} a partir de {id: limite (PackedVector2Array)}.
static func vizinhos(limites: Dictionary) -> Dictionary:
	var ids := limites.keys()
	ids.sort()
	var resultado := {}
	for id in ids:
		resultado[id] = []
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			if encostam(limites[ids[i]], limites[ids[j]]):
				resultado[ids[i]].append(ids[j])
				resultado[ids[j]].append(ids[i])
	return resultado


## Os dois limites se tocam (ou ficam a menos de DISTANCIA_DE_DIVISA)?
static func encostam(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	return _perto(a, b) or _perto(b, a)


static func _perto(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	for p in a:
		if Geometry2D.is_point_in_polygon(p, b):
			return true
		for k in b.size():
			var q := Geometry2D.get_closest_point_to_segment(p, b[k], b[(k + 1) % b.size()])
			if p.distance_to(q) <= DISTANCIA_DE_DIVISA:
				return true
	return false


## O bairro onde o ponto está, ou "". Se estiver em dois (frestas e sobreposições dos
## dados), o preferido ganha: assim quem está na divisa não fica trocando de bairro.
static func bairro_em(ponto: Vector2, limites: Dictionary, preferido: String = "") -> String:
	if not preferido.is_empty() and limites.has(preferido) and Geometry2D.is_point_in_polygon(ponto, limites[preferido]):
		return preferido
	var ids := limites.keys()
	ids.sort()
	for id in ids:
		if Geometry2D.is_point_in_polygon(ponto, limites[id]):
			return id
	return ""
