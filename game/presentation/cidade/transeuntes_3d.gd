extends Node3D
## Transeuntes de um bairro: figurantes andando a esmo pelas ruas (core/cidade/caminhos.gd),
## de um ponto qualquer a outro, para a cidade parecer viva. Não fazem parte da simulação:
## não são moradores, testemunhas nem suspeitos, e não dá para conversar com eles.
## Quantos ficam na rua depende da hora (config/transeuntes.json). Sorteio pelo rng do
## mundo (stream "transeuntes:<bairro>"): mesma semente, mesmo movimento.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Caminhos := preload("res://core/cidade/caminhos.gd")
const Morador := preload("res://presentation/personagem/morador.gd")

var por_hora: Array = []
## [{"no": Morador, "rota": PackedVector2Array, "passo": int, "velocidade": float, "ativo": bool}]
var andantes: Array[Dictionary] = []
var _caminhos: RefCounted
var _gerador: RandomNumberGenerator
var _quantos := 0


func montar(id: String, real: Dictionary, semente: int) -> void:
	name = "Transeuntes"
	var cfg: Dictionary = Catalogo.carregar_config_transeuntes()["dados"]
	por_hora = cfg["por_hora"]
	_caminhos = Caminhos.new(real["ruas"])
	_gerador = Rng.new(semente).stream("transeuntes:%s" % id)
	var maximo := 0
	for n in por_hora:
		maximo = maxi(maximo, int(n))
	for i in maximo:
		var no := Morador.new()
		no.montar("%s/transeunte_%02d" % [id, i], "transeunte")
		no.visible = false
		add_child(no)
		andantes.append({"no": no, "rota": PackedVector2Array(), "passo": 0,
			"velocidade": _gerador.randf_range(cfg["velocidade"][0], cfg["velocidade"][1]), "ativo": false})


## A hora mudou: entra gente na rua (num ponto qualquer) ou, se sobrar, quem chegar ao
## destino vai embora.
func atualizar(hora: int) -> void:
	if _caminhos.pontos() == 0:
		return
	_quantos = int(por_hora[clampi(hora, 0, 23)])
	var ativos := 0
	for a in andantes:
		if a["ativo"]:
			ativos += 1
	for a in andantes:
		if ativos >= _quantos:
			break
		if not a["ativo"]:
			var inicio: Vector2 = _caminhos.ponto_qualquer(_gerador)
			a["no"].position = Vector3(inicio.x, 0.0, inicio.y)
			a["no"].visible = true
			a["ativo"] = true
			_nova_rota(a)
			ativos += 1


func _nova_rota(a: Dictionary) -> void:
	var aqui := Vector2(a["no"].position.x, a["no"].position.z)
	a["rota"] = _caminhos.caminho(aqui, _caminhos.ponto_qualquer(_gerador))
	a["passo"] = 1


## Anda quem está na rua. Ao chegar, sorteia outro destino, ou vai embora se a hora pede
## menos gente.
func andar(delta: float) -> void:
	var ativos := 0
	for a in andantes:
		if a["ativo"]:
			ativos += 1
	for a in andantes:
		if not a["ativo"]:
			continue
		var no: Node3D = a["no"]
		var rota: PackedVector2Array = a["rota"]
		var resta: float = float(a["velocidade"]) * delta
		while resta > 0.0 and a["passo"] < rota.size():
			var aqui := Vector2(no.position.x, no.position.z)
			var alvo: Vector2 = rota[a["passo"]]
			var falta := aqui.distance_to(alvo)
			if falta <= resta:
				no.position = Vector3(alvo.x, 0.0, alvo.y)
				resta -= falta
				a["passo"] += 1
			else:
				var adiante := aqui + (alvo - aqui) / falta * resta
				no.position = Vector3(adiante.x, 0.0, adiante.y)
				no.rotation.y = atan2(-(alvo - aqui).x, -(alvo - aqui).y)
				resta = 0.0
		if a["passo"] >= rota.size():
			if ativos > _quantos:
				a["ativo"] = false
				no.visible = false
				ativos -= 1
			else:
				_nova_rota(a)


func ativos() -> int:
	var n := 0
	for a in andantes:
		if a["ativo"]:
			n += 1
	return n
