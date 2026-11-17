extends RefCounted
## Contas de mira, exame e foto, sem física: só posições e ângulos.
## Assim os testes conferem tudo sem rodar a cena.


## Ângulo (graus) entre a direção do olhar e o ponto.
static func angulo_ate(origem: Vector3, frente: Vector3, ponto: Vector3) -> float:
	var ate := ponto - origem
	if ate.length() < 0.0001:
		return 0.0
	return rad_to_deg(frente.normalized().angle_to(ate.normalized()))


## Índice do ponto mais perto do centro da mira; -1 se nenhum.
## O ângulo é medido do olho (a câmera); o alcance, do corpo (é a mão que pega).
static func escolher_alvo(olho: Vector3, frente: Vector3, corpo: Vector3, pontos: Array, alcance: float, angulo_max: float) -> int:
	var melhor := -1
	var melhor_angulo := INF
	for i in pontos.size():
		var ponto: Vector3 = pontos[i]
		if corpo.distance_to(ponto) > alcance:
			continue
		var angulo := angulo_ate(olho, frente, ponto)
		if angulo <= angulo_max and angulo < melhor_angulo:
			melhor = i
			melhor_angulo = angulo
	return melhor


## Índices dos pontos que saem na foto: dentro do alcance e do campo de visão da câmera.
## O campo é um cone com o meio fov vertical, um pouco menor que o quadro: o que está
## no cantinho não vale como registro.
static func no_quadro(origem: Vector3, frente: Vector3, pontos: Array, alcance: float, fov: float) -> Array[int]:
	var dentro: Array[int] = []
	for i in pontos.size():
		var ponto: Vector3 = pontos[i]
		if origem.distance_to(ponto) <= alcance and angulo_ate(origem, frente, ponto) <= fov / 2.0:
			dentro.append(i)
	return dentro


## Gira o objeto examinado pelo arraste do mouse. rotacao = (x: inclinação, y: giro), em graus.
## A inclinação fica entre -80 e 80 para o objeto não virar de cabeça para baixo de repente.
static func girar(rotacao: Vector2, arraste: Vector2, sensibilidade: float) -> Vector2:
	var inclinacao := clampf(rotacao.x + arraste.y * sensibilidade, -80.0, 80.0)
	var giro := wrapf(rotacao.y + arraste.x * sensibilidade, -180.0, 180.0)
	return Vector2(inclinacao, giro)


## Aproxima um valor do alvo a cada quadro (mira entrando e saindo suave).
static func suavizar(atual: float, alvo: float, velocidade: float, delta: float) -> float:
	return lerpf(atual, alvo, minf(1.0, velocidade * delta))
