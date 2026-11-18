extends Control
## Menu radial dos bolsos (docs/06): segurar Q abre, o mouse escolhe a fatia, soltar usa.
## Desenha as fatias com o nome e a quantidade de cada item (core/confronto/bolsos.gd).

const Bolsos := preload("res://core/confronto/bolsos.gd")
const RAIO := 110.0

var bolsos: RefCounted
var escolhida: int = -1
var _direcao := Vector2.ZERO


func abrir() -> void:
	visible = true
	escolhida = -1
	_direcao = Vector2.ZERO
	queue_redraw()


## O mouse anda: a direção acumulada escolhe a fatia.
func mover(relativo: Vector2) -> void:
	_direcao = (_direcao + relativo * 0.02).limit_length(1.0)
	escolhida = Bolsos.fatia(_direcao, bolsos.itens.size())
	queue_redraw()


func _draw() -> void:
	if bolsos == null:
		return
	var centro := size / 2.0
	draw_circle(centro, RAIO + 30.0, Color(0, 0, 0, 0.55))
	var n: int = bolsos.itens.size()
	var fonte := ThemeDB.fallback_font
	for i in n:
		var angulo := TAU * i / n
		var ponto := centro + Vector2(sin(angulo), -cos(angulo)) * RAIO
		var b: Dictionary = bolsos.itens[i]
		var cor := Color(1, 0.9, 0.5) if i == escolhida else (Color(0.85, 0.85, 0.85) if int(b["quantidade"]) > 0 else Color(0.45, 0.45, 0.45))
		if i == escolhida:
			draw_circle(ponto, 30.0, Color(0.3, 0.25, 0.1, 0.8))
		var texto := "%s x%d" % [b["nome"], int(b["quantidade"])]
		var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(fonte, ponto - Vector2(largura / 2.0, -4.0), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, cor)
