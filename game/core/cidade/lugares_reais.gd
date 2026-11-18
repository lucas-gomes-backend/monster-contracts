extends RefCounted
## Põe os lugares de um bairro abstrato (casas, padaria, igreja... de core/mundo/bairro.gd)
## nos lotes de prédio do bairro real (core/cidade/lotes.gd). Cada lugar ganha um lote só
## dele, de preferência na rua real indicada nos dados (o nome da rua sem acento, em
## minúsculas, ex.: "rua_sao_bento"), e uma porta: o ponto na calçada em frente ao lote,
## por onde as pessoas entram e saem. Sorteio pelo rng do mundo (stream "lugares:<bairro>").
##
## {id do lugar: {"lote": id do lote, "porta": Vector2, "rua": nome da rua do lote}}

const Lotes := preload("res://core/cidade/lotes.gd")

## A porta fica um pouco para fora do lote, já na calçada.
const PORTA_PARA_FORA := 0.8
const ACENTOS := {"á": "a", "à": "a", "â": "a", "ã": "a", "é": "e", "ê": "e", "í": "i", "ó": "o", "ô": "o", "õ": "o", "ú": "u", "ü": "u", "ç": "c"}


static func atribuir(bairro: RefCounted, real: Dictionary, lotes: Array, rng: RefCounted) -> Dictionary:
	var gerador: RandomNumberGenerator = rng.stream("lugares:%s" % bairro.id)
	var nome_da_rua := {}  # osm -> slug
	for rua in real["ruas"]:
		nome_da_rua[int(rua["osm"])] = slug(rua["nome"])
	var livres: Array = []
	for lote in lotes:
		if lote["tipo"] == Lotes.TIPO_PREDIO:
			livres.append(lote)
	var resultado := {}
	for id_lugar in bairro.ids_locais():
		if livres.is_empty():
			break
		var rua_pedida: String = bairro.rua_de(id_lugar)
		var na_rua: Array = []
		for lote in livres:
			if nome_da_rua.get(int(lote["rua"]), "") == rua_pedida:
				na_rua.append(lote)
		var opcoes: Array = na_rua if not na_rua.is_empty() else livres
		var escolhido: Dictionary = opcoes[gerador.randi_range(0, opcoes.size() - 1)]
		livres.erase(escolhido)
		resultado[id_lugar] = {"lote": escolhido["id"], "porta": porta(escolhido, real),
			"rua": nome_da_rua.get(int(escolhido["rua"]), "")}
	return resultado


## O ponto na calçada em frente ao lote: o meio do lado do lote virado para a rua dele.
static func porta(lote: Dictionary, real: Dictionary) -> Vector2:
	var u: Vector2 = lote["eixo"]
	var v := Vector2(-u.y, u.x)
	var c: Vector2 = lote["centro"]
	var meio_fundo: float = float(lote["fundo"]) / 2.0
	var lados := [c + v * meio_fundo, c - v * meio_fundo]
	var melhor: Vector2 = lados[0]
	var menor := INF
	for rua in real["ruas"]:
		if int(rua["osm"]) != int(lote["rua"]):
			continue
		var p := Lotes._pontos(rua["pontos"])
		for lado in lados:
			for i in p.size() - 1:
				var d: float = lado.distance_to(Geometry2D.get_closest_point_to_segment(lado, p[i], p[i + 1]))
				if d < menor:
					menor = d
					melhor = lado
	return melhor + (melhor - c).normalized() * PORTA_PARA_FORA


## "Rua São Bento" -> "rua_sao_bento" (como as ruas dos dados dos bairros abstratos).
static func slug(nome: String) -> String:
	var minusculo := nome.to_lower()
	var saida := ""
	for letra in minusculo:
		letra = ACENTOS.get(letra, letra)
		if (letra >= "a" and letra <= "z") or (letra >= "0" and letra <= "9"):
			saida += letra
		elif not saida.ends_with("_") and not saida.is_empty():
			saida += "_"
	return saida.trim_suffix("_")
