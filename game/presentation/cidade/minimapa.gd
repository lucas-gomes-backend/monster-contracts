extends Control
## Minimapa no canto superior direito, como em GTA: centrado no caçador e girando com a
## câmera (para a frente é sempre para cima). Desenha, a partir dos dados dos bairros
## carregados, as ruas, os prédios, o limite do bairro atual (como a linha no chão) e os
## vizinhos. Lá embaixo, mostra as galerias. Não renderiza a cena de novo: só linhas.

const Lotes := preload("res://core/cidade/lotes.gd")

const TAMANHO := 140.0
const MARGEM := 8.0
## Pixels por metro: 140 px mostram uns 150 m em volta.
const ESCALA := 0.9
const COR_FUNDO := Color(0.12, 0.13, 0.12, 0.85)
const COR_MOLDURA := Color(0.9, 0.88, 0.8)
const COR_RUA := Color(0.75, 0.75, 0.72)
const COR_CAMINHO := Color(0.6, 0.5, 0.4)
const COR_PREDIO := Color(0.42, 0.45, 0.5)
const COR_BORDA := Color(0.95, 0.85, 0.45)
const COR_VIZINHO := Color(0.6, 0.6, 0.6, 0.6)
const COR_GALERIA := Color(0.25, 0.4, 0.3)
const COR_SETA := Color(1.0, 0.35, 0.25)

## A cena da cidade (bairro_cena.gd): de onde vêm bairros, caçador e zona.
var cena: Node3D


func _ready() -> void:
	_posicionar()


func _posicionar() -> void:
	position = Vector2(640.0 - TAMANHO - MARGEM, MARGEM)
	size = Vector2(TAMANHO, TAMANHO)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Ponto do mundo (x, z) para a tela do minimapa: centrado no caçador e girado pelo
## giro da câmera, para a frente da câmera apontar para cima.
static func para_minimapa(ponto: Vector2, centro_mundo: Vector2, giro: float) -> Vector2:
	return Vector2(TAMANHO, TAMANHO) / 2.0 + (ponto - centro_mundo).rotated(giro) * ESCALA


func _draw() -> void:
	if cena == null or cena.cacador == null or cena.bairro == null:
		return
	_posicionar()
	var centro := Vector2(cena.cacador.position.x, cena.cacador.position.z)
	var giro: float = cena.cacador.yaw
	draw_rect(Rect2(Vector2.ZERO, size), COR_FUNDO)
	if cena.zona == "esgoto":
		for corredor in cena.bairro.galerias.get("corredores", []):
			draw_colored_polygon(_na_tela(corredor, centro, giro), COR_GALERIA)
	else:
		for id in cena.carregados:
			var b: Node3D = cena.carregados[id]
			for lote in b.lotes:
				if lote["tipo"] == Lotes.TIPO_PREDIO:
					draw_colored_polygon(_na_tela(Lotes.cantos(lote), centro, giro), COR_PREDIO)
			for rua in b.dados["ruas"]:
				var cor := COR_CAMINHO if rua["tipo"] in ["steps", "footway", "pedestrian"] else COR_RUA
				draw_polyline(_na_tela(Lotes._pontos(rua["pontos"]), centro, giro), cor, maxf(1.0, float(rua["largura"]) * ESCALA))
			if b != cena.bairro:
				draw_polyline(_anel(b, centro, giro), COR_VIZINHO, 1.0)
		draw_polyline(_anel(cena.bairro, centro, giro), COR_BORDA, 2.0)
	# A seta do caçador: sempre no meio, apontando para cima (para onde a câmera olha).
	var meio := size / 2.0
	draw_colored_polygon(PackedVector2Array([meio + Vector2(0, -7), meio + Vector2(5, 5), meio + Vector2(-5, 5)]), COR_SETA)
	# O norte gira com o mapa.
	var norte := meio + Vector2(0, -1).rotated(giro) * (TAMANHO / 2.0 - 9.0)
	draw_string(ThemeDB.fallback_font, norte + Vector2(-4, 4), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COR_MOLDURA)
	draw_rect(Rect2(Vector2.ZERO, size), COR_MOLDURA, false, 2.0)


func _anel(b: Node3D, centro: Vector2, giro: float) -> PackedVector2Array:
	var pontos := _na_tela(Lotes._pontos(b.dados["limite"]), centro, giro)
	pontos.append(pontos[0])
	return pontos


func _na_tela(pontos: PackedVector2Array, centro: Vector2, giro: float) -> PackedVector2Array:
	var saida := PackedVector2Array()
	for p in pontos:
		saida.append(para_minimapa(p, centro, giro))
	return saida
