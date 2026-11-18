extends Node3D
## A criatura no campo (docs/06): um vulto que vem atrás do caçador e ataca, e reage ao que
## ele usa pelos ESTADOS do núcleo (core/confronto/estado_criatura.gd), não por vida.
##   livre: vem e ataca | afastada: recua | contida: parada | vulnerável: cambaleia devagar
##   resolvida: some. Atingida por qualquer coisa, interrompe o ataque por um tempo.
## O círculo de sal barra quem tem o sal como fraqueza (core/confronto/circulo_de_sal.gd).
## Sem colisão com prédios por enquanto: anda em linha reta.

const Estado := preload("res://core/confronto/estado_criatura.gd")
const Circulo := preload("res://core/confronto/circulo_de_sal.gd")
const Blocos := preload("res://presentation/greybox/blocos.gd")

const CORES := {"livre": Color(0.12, 0.1, 0.1), "contida": Color(0.55, 0.55, 0.6), "vulneravel": Color(0.6, 0.15, 0.1)}

var estado: RefCounted
var ficha: Dictionary
var _cfg: Dictionary
var _g: RandomNumberGenerator
var _espera := 0.0
var _corpo: MeshInstance3D
var pressionando := false


func montar(ficha_da_criatura: Dictionary, cfg_confronto_criatura: Dictionary, cfg_campo: Dictionary, g: RandomNumberGenerator) -> void:
	name = "Criatura"
	ficha = ficha_da_criatura
	_cfg = cfg_campo
	_g = g
	estado = Estado.new(ficha, cfg_confronto_criatura)
	_corpo = Blocos.bloco(self, Vector3(float(_cfg["raio"]) * 1.6, 2.1, float(_cfg["raio"]) * 1.2), Vector3(0, 1.05, 0), CORES["livre"], 1.0, false) as MeshInstance3D


func raio() -> float:
	return float(_cfg["raio"])


## Usa um item nela (tiro, lâmina, sal, água benta...). Interrompe o ataque se pegou algo.
func receber(item: String, interrompe: float) -> Dictionary:
	var r: Dictionary = estado.usar(item)
	_espera = maxf(_espera, interrompe)
	_pintar()
	return r


## Um passo: anda conforme o estado e, se alcançar o caçador, ataca.
## Devolve {} ou {"parte", "gravidade"} do ferimento que causou.
func andar(segundos: float, alvo: Vector3, circulos: Array) -> Dictionary:
	estado.passar(segundos)
	_espera = maxf(0.0, _espera - segundos)
	_pintar()
	pressionando = false
	if estado.estado == Estado.RESOLVIDA:
		visible = false
		return {}
	var plano := Vector3(alvo.x - position.x, 0.0, alvo.z - position.z)
	var distancia := plano.length()
	var direcao := plano / maxf(distancia, 0.001)
	var rapidez: float = float(_cfg["velocidade"]) + float(_cfg["velocidade_por_agressividade"]) * estado.agressividade
	match estado.estado:
		Estado.CONTIDA:
			return {}
		Estado.VULNERAVEL:
			rapidez *= 0.25
	if estado.esta_afastada():
		position -= direcao * rapidez * segundos
		return {}
	var passo := minf(rapidez * segundos, maxf(0.0, distancia - float(_cfg["alcance_do_ataque"]) * 0.8))
	var proximo := position + direcao * passo
	# O círculo de sal: quem tem o sal como fraqueza não entra.
	if Circulo.barra(ficha):
		for c in circulos:
			var ponto := Vector2(proximo.x, proximo.z)
			if c.ativo() and ponto.distance_to(c.centro) < c.raio + raio():
				pressionando = true
				var fora: Vector2 = c.centro + (ponto - c.centro).normalized() * (c.raio + raio())
				proximo = Vector3(fora.x, position.y, fora.y)
	position = proximo
	if distancia > 0.05:
		rotation.y = atan2(-direcao.x, -direcao.z)
	var agora := Vector2(position.x, position.z).distance_to(Vector2(alvo.x, alvo.z))
	if estado.estado == Estado.LIVRE and _espera <= 0.0 and agora <= float(_cfg["alcance_do_ataque"]) and not pressionando:
		_espera = float(_cfg["intervalo_entre_ataques"])
		return _ferimento()
	return {}


func _ferimento() -> Dictionary:
	var pesos: Dictionary = _cfg["partes_atingidas"]
	var partes := pesos.keys()
	partes.sort()
	var total := 0
	for p in partes:
		total += int(pesos[p])
	var sorteio := _g.randi_range(1, total)
	var parte: String = partes[0]
	for p in partes:
		sorteio -= int(pesos[p])
		if sorteio <= 0:
			parte = p
			break
	var chance: float = float(_cfg["chance_de_grave"]) + float(_cfg["chance_de_grave_por_agressividade"]) * estado.agressividade
	return {"parte": parte, "gravidade": "grave" if _g.randf() < chance else "leve"}


func _pintar() -> void:
	if _corpo == null:
		return
	var cor: Color = CORES.get(estado.estado, CORES["livre"])
	if _corpo.material_override is ShaderMaterial:
		(_corpo.material_override as ShaderMaterial).set_shader_parameter("cor", cor)
