extends Node3D
## Espíritos errantes (docs/12, Sensitivo): só o sensitivo os vê. Aparecem em volta do caçador
## e vêm atrás dele; perto, incomodam (exaustão e medo). O círculo de sal os segura do lado de
## fora. A quantidade vem do estágio da condição. Sorteio da posição num stream do core/rng.gd.

const Blocos := preload("res://presentation/greybox/blocos.gd")

var espiritos: Array[Node3D] = []
var _cfg: Dictionary  # espiritos_errantes
var _g: RandomNumberGenerator


func montar(cfg_errantes: Dictionary, g: RandomNumberGenerator) -> void:
	name = "Espiritos"
	_cfg = cfg_errantes
	_g = g


## Quantos espíritos o estágio pede; cria ou tira para bater.
func ajustar(quantos: int, perto_de: Vector3) -> void:
	while espiritos.size() < quantos:
		var e := Node3D.new()
		e.name = "Espirito%d" % espiritos.size()
		var corpo: Node3D = Blocos.bloco(e, Vector3(0.6, 1.7, 0.4), Vector3(0, 0.95, 0), Color(0.3, 0.38, 0.55), 1.0, false)
		corpo.transparency = 0.35
		add_child(e)
		var angulo := _g.randf() * TAU
		e.position = perto_de + Vector3(cos(angulo), 0.0, sin(angulo)) * float(_cfg["aparecem_a"])
		espiritos.append(e)
	while espiritos.size() > quantos:
		var e: Node3D = espiritos.pop_back()
		e.queue_free()


## Um passo: vêm na direção do caçador (sem entrar nos círculos de sal ativos que o
## protegem). Devolve quantos estão perto o bastante para incomodar (barrado no sal não conta).
func andar(segundos: float, alvo: Vector3, circulos: Array) -> int:
	var perto := 0
	for e in espiritos:
		var d := Vector3(alvo.x - e.position.x, 0.0, alvo.z - e.position.z)
		var dist := d.length()
		var barrado := false
		if dist > 1.2:
			var proximo := e.position + d / dist * minf(float(_cfg["velocidade"]) * segundos, dist - 1.2)
			for c in circulos:
				var p := Vector2(proximo.x, proximo.z)
				if c.ativo() and p.distance_to(c.centro) < c.raio + 0.4:
					var fora: Vector2 = c.centro + (p - c.centro).normalized() * (c.raio + 0.4)
					proximo = Vector3(fora.x, proximo.y, fora.y)
					barrado = true
			e.position = proximo
		# Do lado de fora do sal, não alcança o caçador.
		if not barrado and Vector2(e.position.x, e.position.z).distance_to(Vector2(alvo.x, alvo.z)) <= float(_cfg["incomodam_a"]):
			perto += 1
	return perto
