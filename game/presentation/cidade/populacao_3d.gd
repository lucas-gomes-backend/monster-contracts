extends Node3D
## A gente de um bairro real na rua (Fase 4): os moradores gerados pelo núcleo
## (core/npcs/gerador_populacao.gd) nos lugares postos nos lotes (core/cidade/lugares_reais.gd).
## A cada minuto do relógio da cidade, a rotina (core/npcs/rotina.gd) diz onde cada um está.
## Quem está trabalhando ou passeando aparece na porta do lugar; quem está em casa, dormindo
## ou fora do bairro some lá dentro. Quando alguém muda de lugar, anda até lá pelas ruas
## (core/cidade/caminhos.gd), e não atravessando prédios.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Rng := preload("res://core/rng.gd")
const Bairro := preload("res://core/mundo/bairro.gd")
const Populacao := preload("res://core/npcs/gerador_populacao.gd")
const Rotina := preload("res://core/npcs/rotina.gd")
const Lugares := preload("res://core/cidade/lugares_reais.gd")
const Caminhos := preload("res://core/cidade/caminhos.gd")
const Morador := preload("res://presentation/personagem/morador.gd")

const VISIVEIS := ["trabalhando", "lazer"]
## Quem está no mesmo lugar não fica empilhado: lado a lado na calçada.
const LADO_A_LADO := 0.8

var bairro: RefCounted
var npcs: Array[Dictionary] = []
var lugares: Dictionary = {}
var velocidade: float = 1.6
## {npc_id: {"no": Morador, "local", "atividade", "rota": PackedVector2Array, "passo": int}}
var pessoas: Dictionary = {}
var _rotina: RefCounted
var _caminhos: RefCounted
var _primeira_vez := true


## Monta a gente do bairro real (id com dados em data/neighborhoods). lotes: os do Bairro3D.
func montar(id: String, real: Dictionary, lotes: Array, semente: int) -> void:
	name = "Populacao"
	var rng := Rng.new(semente)
	var cfg: Dictionary = Catalogo.carregar_config_populacao()["dados"]
	velocidade = Catalogo.carregar_config_relogio_da_cidade()["dados"]["velocidade_a_pe"]
	bairro = Bairro.new(Catalogo.carregar_bairro(id)["dados"])
	npcs = Populacao.gerar(bairro, cfg, rng)
	_rotina = Rotina.new(cfg, rng, bairro)
	lugares = Lugares.atribuir(bairro, real, lotes, rng)
	_caminhos = Caminhos.new(real["ruas"])
	for i in npcs.size():
		var npc := npcs[i]
		var no := Morador.new()
		no.montar(npc["id"], "%s %s" % [npc["nome"], npc["sobrenome"]])
		no.visible = false
		add_child(no)
		pessoas[npc["id"]] = {"no": no, "local": "", "atividade": "", "rota": PackedVector2Array(), "passo": 0, "indice": i}


## Onde fica a porta de um lugar (com a pessoa ao lado das outras), ou null.
func porta_de(local: String, indice: int) -> Variant:
	if not lugares.has(local):
		return null
	var p: Vector2 = lugares[local]["porta"]
	return p + Vector2(((indice % 5) - 2) * LADO_A_LADO, 0.0)


## O relógio da cidade andou: cada um vai para onde a rotina manda.
func atualizar(minuto: int) -> void:
	for npc in npcs:
		var estado: Dictionary = _rotina.onde_esta(npc, minuto)
		var p: Dictionary = pessoas[npc["id"]]
		if estado["local"] == p["local"] and estado["atividade"] == p["atividade"]:
			continue
		var de: Variant = porta_de(p["local"], p["indice"])
		var para: Variant = porta_de(estado["local"], p["indice"])
		p["local"] = estado["local"]
		p["atividade"] = estado["atividade"]
		var no: Node3D = p["no"]
		if _primeira_vez or de == null or para == null or de == para:
			p["rota"] = PackedVector2Array()
			if para != null:
				no.position = Vector3(para.x, 0.0, para.y)
			no.visible = para != null and estado["atividade"] in VISIVEIS
		else:
			p["rota"] = _caminhos.caminho(de, para)
			p["passo"] = 1
			no.position = Vector3(de.x, 0.0, de.y)
			no.visible = true
	_primeira_vez = false


## Anda quem está a caminho (velocidade_a_pe, em segundos reais).
func andar(delta: float) -> void:
	for id in pessoas:
		var p: Dictionary = pessoas[id]
		var rota: PackedVector2Array = p["rota"]
		if rota.is_empty():
			continue
		var no: Node3D = p["no"]
		var resta := velocidade * delta
		while resta > 0.0 and p["passo"] < rota.size():
			var aqui := Vector2(no.position.x, no.position.z)
			var alvo: Vector2 = rota[p["passo"]]
			var falta := aqui.distance_to(alvo)
			if falta <= resta:
				no.position = Vector3(alvo.x, 0.0, alvo.y)
				resta -= falta
				p["passo"] += 1
			else:
				var passo := aqui + (alvo - aqui) / falta * resta
				no.position = Vector3(passo.x, 0.0, passo.y)
				no.rotation.y = atan2(-(alvo - aqui).x, -(alvo - aqui).y)
				resta = 0.0
		if p["passo"] >= rota.size():
			p["rota"] = PackedVector2Array()
			no.visible = p["atividade"] in VISIVEIS


## Quantas pessoas estão à vista agora.
func visiveis() -> int:
	var n := 0
	for id in pessoas:
		if pessoas[id]["no"].visible:
			n += 1
	return n
