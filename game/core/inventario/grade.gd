extends RefCounted
## Grade de inventário (docs/08): mochila ou porta-malas. Cada item ocupa um formato
## (largura x altura, pode girar) e empilha até o limite dele. Peso em gramas (inteiro).
## Os itens vêm de data/items/itens.json ({id: definição}).
##
## Entrada: {"n": número único, "item", "x", "y", "w", "h", "quantidade"}

var largura: int
var altura: int
var entradas: Array[Dictionary] = []
var _defs: Dictionary
var _proximo := 1


func _init(l: int, a: int, definicoes: Dictionary) -> void:
	largura = l
	altura = a
	_defs = definicoes


## O retângulo (x, y, w, h) cabe na grade sem bater em ninguém (menos a entrada "ignorar")?
func cabe(x: int, y: int, w: int, h: int, ignorar: int = 0) -> bool:
	if x < 0 or y < 0 or x + w > largura or y + h > altura:
		return false
	for e in entradas:
		if e["n"] == ignorar:
			continue
		if x < e["x"] + e["w"] and e["x"] < x + w and y < e["y"] + e["h"] and e["y"] < y + h:
			return false
	return true


## Põe "quantidade" do item na posição, girado ou não. Devolve o número da entrada (0 = não coube).
func colocar(item: String, x: int, y: int, girado: bool, quantidade: int) -> int:
	var d: Dictionary = _defs[item]
	var w: int = d["formato"][1] if girado else d["formato"][0]
	var h: int = d["formato"][0] if girado else d["formato"][1]
	if quantidade < 1 or quantidade > int(d["pilha"]) or not cabe(x, y, w, h):
		return 0
	var n := _proximo
	_proximo += 1
	entradas.append({"n": n, "item": item, "x": x, "y": y, "w": w, "h": h, "quantidade": quantidade})
	return n


## Guarda o que couber: primeiro completa pilhas do mesmo item, depois procura lugar
## (linha por linha, tentando deitado e em pé). Devolve quanto NÃO coube.
func adicionar(item: String, quantidade: int) -> int:
	var resta := quantidade
	var pilha: int = _defs[item]["pilha"]
	for e in entradas:
		if resta <= 0:
			break
		if e["item"] == item and int(e["quantidade"]) < pilha:
			var poe := mini(resta, pilha - int(e["quantidade"]))
			e["quantidade"] = int(e["quantidade"]) + poe
			resta -= poe
	while resta > 0:
		var lugar := achar_lugar(item)
		if lugar.is_empty():
			break
		var poe := mini(resta, pilha)
		colocar(item, lugar["x"], lugar["y"], lugar["girado"], poe)
		resta -= poe
	return resta


func achar_lugar(item: String) -> Dictionary:
	var f: Array = _defs[item]["formato"]
	for y in altura:
		for x in largura:
			for girado in [false, true]:
				var w: int = f[1] if girado else f[0]
				var h: int = f[0] if girado else f[1]
				if cabe(x, y, w, h):
					return {"x": x, "y": y, "girado": girado}
	return {}


## Tira até "quantidade" do item (das últimas pilhas para as primeiras). Devolve quanto tirou.
func retirar(item: String, quantidade: int) -> int:
	var tirou := 0
	for i in range(entradas.size() - 1, -1, -1):
		if tirou >= quantidade:
			break
		var e: Dictionary = entradas[i]
		if e["item"] != item:
			continue
		var tira := mini(quantidade - tirou, int(e["quantidade"]))
		e["quantidade"] = int(e["quantidade"]) - tira
		tirou += tira
		if int(e["quantidade"]) <= 0:
			entradas.remove_at(i)
	return tirou


## Tira a entrada inteira. Devolve a entrada tirada (ou {}).
func tirar_entrada(n: int) -> Dictionary:
	for i in entradas.size():
		if entradas[i]["n"] == n:
			var e: Dictionary = entradas[i]
			entradas.remove_at(i)
			return e
	return {}


## Move (e gira) uma entrada para (x, y). Devolve se deu.
func mover(n: int, x: int, y: int, girar: bool = false) -> bool:
	for e in entradas:
		if e["n"] != n:
			continue
		var w: int = e["h"] if girar else e["w"]
		var h: int = e["w"] if girar else e["h"]
		if not cabe(x, y, w, h, n):
			return false
		e["x"] = x
		e["y"] = y
		e["w"] = w
		e["h"] = h
		return true
	return false


## A entrada que ocupa a casa (x, y), ou {}.
func em(x: int, y: int) -> Dictionary:
	for e in entradas:
		if x >= e["x"] and x < e["x"] + e["w"] and y >= e["y"] and y < e["y"] + e["h"]:
			return e
	return {}


func quantidade(item: String) -> int:
	var n := 0
	for e in entradas:
		if e["item"] == item:
			n += int(e["quantidade"])
	return n


func peso_g() -> int:
	var total := 0
	for e in entradas:
		total += int(_defs[e["item"]]["peso_g"]) * int(e["quantidade"])
	return total


## Golpe grave: cada item frágil pode quebrar (sorteio no stream dado). Devolve os quebrados.
func quebrar_frageis(chance: float, g: RandomNumberGenerator) -> Array[String]:
	var quebrados: Array[String] = []
	for i in range(entradas.size() - 1, -1, -1):
		var e: Dictionary = entradas[i]
		if _defs[e["item"]]["fragil"] and g.randf() < chance:
			quebrados.append(str(e["item"]))
			entradas.remove_at(i)
	quebrados.reverse()
	return quebrados


## Multiplicadores do peso: velocidade e fôlego caem entre o leve e o pesado.
static func efeito_do_peso(peso: int, cfg_peso: Dictionary) -> Dictionary:
	var leve := int(cfg_peso["leve_ate_g"])
	var pesado := int(cfg_peso["pesado_a_partir_g"])
	var t := clampf(float(peso - leve) / float(maxi(pesado - leve, 1)), 0.0, 1.0)
	return {"velocidade": lerpf(1.0, float(cfg_peso["velocidade_no_pesado"]), t), "folego": lerpf(1.0, float(cfg_peso["folego_no_pesado"]), t)}
