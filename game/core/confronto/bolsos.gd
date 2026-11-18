extends RefCounted
## Bolsos e cinto (docs/06, "Itens de acesso rápido"): até 8 itens no menu radial. O que vai
## nos bolsos é decisão de preparação; abrir a mochila no confronto fica para depois.

var itens: Array[Dictionary] = []  # [{"item", "nome", "quantidade"}], na ordem do menu


func _init(bolsos: Array) -> void:
	for b in bolsos:
		itens.append({"item": str(b["item"]), "nome": str(b["nome"]), "quantidade": int(b["quantidade"])})


## Tira um do bolso i. Devolve o item, ou "" se acabou ou não existe.
func usar(i: int) -> String:
	if i < 0 or i >= itens.size() or int(itens[i]["quantidade"]) <= 0:
		return ""
	itens[i]["quantidade"] = int(itens[i]["quantidade"]) - 1
	return itens[i]["item"]


func quantidade(item: String) -> int:
	for b in itens:
		if b["item"] == item:
			return int(b["quantidade"])
	return 0


## Qual fatia do menu radial a direção (do centro) aponta: 0 em cima, no sentido horário.
static func fatia(direcao: Vector2, quantas: int) -> int:
	if direcao.length() < 0.2 or quantas <= 0:
		return -1
	var angulo := fposmod(atan2(direcao.x, -direcao.y), TAU)
	var largura := TAU / quantas
	return int(fposmod(angulo + largura / 2.0, TAU) / largura) % quantas
