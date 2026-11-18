extends Node3D
## Polícia básica no bairro atual (docs/07, "Polícia e suspeita"): cega ao sobrenatural,
## reage só à suspeita. Normal: ninguém. Observado: policiais patrulhando as ruas.
## Procurado ou barrado: além da patrulha, um policial vai atrás do caçador; se chegar
## perto, aborda (a cena da cidade detém o caçador). Sorteio pelo rng do mundo.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Caminhos := preload("res://core/cidade/caminhos.gd")
const Suspeita := preload("res://core/mundo/suspeita.gd")
const Morador := preload("res://presentation/personagem/morador.gd")

const COR_DA_FARDA := Color(0.16, 0.22, 0.42)
## De quanto em quanto tempo quem persegue refaz o caminho até o caçador (segundos).
const REFAZER_PERSEGUICAO := 1.5

var nivel: String = Suspeita.NORMAL
## [{"no", "rota", "passo", "perseguindo": bool}]
var policiais: Array[Dictionary] = []
var _cfg: Dictionary
var _caminhos: RefCounted
var _gerador: RandomNumberGenerator
var _desde_refazer := 0.0


func montar(id: String, real: Dictionary, semente: int) -> void:
	name = "Policia"
	_cfg = Catalogo.carregar_config_suspeita()["dados"]["policia"]
	_caminhos = Caminhos.new(real["ruas"])
	_gerador = Rng.new(semente).stream("policia:%s" % id)
	var maximo := maxi(int(_cfg["patrulha_observado"]), int(_cfg["patrulha_procurado"]))
	for i in maximo:
		var no := Morador.new()
		no.montar("%s/policial_%d" % [id, i], "policial", COR_DA_FARDA)
		no.visible = false
		add_child(no)
		policiais.append({"no": no, "rota": PackedVector2Array(), "passo": 0, "perseguindo": false})


## A suspeita mudou de nível: entra ou sai gente da patrulha; procurado, um persegue.
func atualizar(novo_nivel: String) -> void:
	nivel = novo_nivel
	var quantos := 0
	if nivel == Suspeita.OBSERVADO:
		quantos = int(_cfg["patrulha_observado"])
	elif nivel == Suspeita.PROCURADO or nivel == Suspeita.BARRADO:
		quantos = int(_cfg["patrulha_procurado"])
	if _caminhos.pontos() == 0:
		quantos = 0
	for i in policiais.size():
		var p: Dictionary = policiais[i]
		var deve := i < quantos
		if deve and not p["no"].visible:
			var inicio: Vector2 = _caminhos.ponto_qualquer(_gerador)
			p["no"].position = Vector3(inicio.x, 0.0, inicio.y)
			p["no"].visible = true
			_patrulhar(p)
		elif not deve:
			p["no"].visible = false
			p["rota"] = PackedVector2Array()
		p["perseguindo"] = deve and i == 0 and (nivel == Suspeita.PROCURADO or nivel == Suspeita.BARRADO)


func _patrulhar(p: Dictionary) -> void:
	var aqui := Vector2(p["no"].position.x, p["no"].position.z)
	p["rota"] = _caminhos.caminho(aqui, _caminhos.ponto_qualquer(_gerador))
	p["passo"] = 1


## Anda a patrulha e quem persegue vai até o caçador. Devolve true se alguém o abordou.
func andar(delta: float, cacador: Vector3) -> bool:
	_desde_refazer += delta
	var alvo := Vector2(cacador.x, cacador.z)
	for p in policiais:
		var no: Node3D = p["no"]
		if not no.visible:
			continue
		if p["perseguindo"]:
			if Vector2(no.position.x, no.position.z).distance_to(alvo) <= float(_cfg["alcance_da_abordagem"]):
				return true
			if p["rota"].is_empty() or _desde_refazer >= REFAZER_PERSEGUICAO:
				p["rota"] = _caminhos.caminho(Vector2(no.position.x, no.position.z), alvo)
				p["passo"] = 1
		var rota: PackedVector2Array = p["rota"]
		var resta: float = float(_cfg["velocidade"]) * delta
		while resta > 0.0 and p["passo"] < rota.size():
			var aqui := Vector2(no.position.x, no.position.z)
			var destino: Vector2 = rota[p["passo"]]
			var falta := aqui.distance_to(destino)
			if falta <= resta:
				no.position = Vector3(destino.x, 0.0, destino.y)
				resta -= falta
				p["passo"] += 1
			else:
				var adiante := aqui + (destino - aqui) / falta * resta
				no.position = Vector3(adiante.x, 0.0, adiante.y)
				no.rotation.y = atan2(-(destino - aqui).x, -(destino - aqui).y)
				resta = 0.0
		if p["passo"] >= rota.size() and not p["perseguindo"]:
			_patrulhar(p)
	if _desde_refazer >= REFAZER_PERSEGUICAO:
		_desde_refazer = 0.0
	return false


func visiveis() -> int:
	var n := 0
	for p in policiais:
		if p["no"].visible:
			n += 1
	return n
