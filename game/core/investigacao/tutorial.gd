extends RefCounted
## Caso tutorial com mentor (docs/02, "Primeira hora"). O mentor é um caçador veterano gerado
## pela semente (nome, idade, jeito). Os passos ensinam o processo (lugar, pista, testemunha,
## caderno, teste de campo, agir) e terminam quando a investigação mostra que o jogador fez:
## o tutorial só LÊ a sessão, não muda nada nela. O mentor nunca diz qual é a criatura.
## Textos em data/config/tutorial.json.

const Rng := preload("res://core/rng.gd")
const Gerador := preload("res://core/casos/gerador_casos.gd")
const Pistas := preload("res://core/casos/pistas.gd")


## Um mentor aleatório: {nome, idade, jeito, apresentacao}.
static func gerar_mentor(semente: int, cfg_tutorial: Dictionary, cfg_populacao: Dictionary) -> Dictionary:
	var g: RandomNumberGenerator = Rng.new(semente).stream("mentor")
	var m: Dictionary = cfg_tutorial["mentor"]
	var comunidades: Array = m["comunidades"]
	var nomes: Dictionary = cfg_populacao["nomes"][comunidades[g.randi_range(0, comunidades.size() - 1)]]
	var genero := "masculinos" if g.randf() < 0.5 else "femininos"
	var primeiros: Array = nomes[genero]
	var sobrenomes: Array = nomes.get("sobrenomes", [""])
	var nome := "%s %s" % [primeiros[g.randi_range(0, primeiros.size() - 1)], sobrenomes[g.randi_range(0, sobrenomes.size() - 1)]]
	var jeitos: Array = m["jeitos"]
	var jeito: String = jeitos[g.randi_range(0, jeitos.size() - 1)]
	return {
		"nome": nome.strip_edges(),
		"idade": g.randi_range(int(m["idade"][0]), int(m["idade"][1])),
		"jeito": jeito,
		"apresentacao": str(m["apresentacao"].get(jeito, "{mentor}.")).replace("{mentor}", nome.strip_edges()),
	}


## A semente do caso tutorial: a primeira (a partir de "inicio") que gera um caso justo de caça
## simples com a espécie do tutorial (para o teste ensinado funcionar) e com pista da criatura
## ainda no lugar do último ataque quando o contrato começa (para a coleta ter o que achar).
static func semente_do_caso(cfg_tutorial: Dictionary, inicio: int = 1) -> int:
	for s in range(inicio, inicio + 300):
		var caso := Gerador.gerar(s)
		if not caso.get("valido", false) or caso["estrutura"] != "caca_simples" or caso["verdade"]["especie"] != cfg_tutorial["especie"]:
			continue
		var local := ultimo_ataque(caso)
		for p in caso["pistas"]:
			if p["tipo"] == "marca" and p["origem"] == "criatura" and p["local"] == local and Pistas.disponivel(p, int(caso["contrato"]["minuto"])):
				return s
	return inicio


## O lugar do último ataque da criatura ("" se não houve).
static func ultimo_ataque(caso: Dictionary) -> String:
	var ataques: Array = caso["registro"].buscar("criatura.ataque", caso["verdade"]["instancia"])
	return str(ataques[-1]["local"]) if not ataques.is_empty() else ""


## O passo feito? (lê a sessão de investigação)
static func feito(passo: String, sessao: RefCounted) -> bool:
	match passo:
		"ir_ao_local":
			return sessao.visitas.has(ultimo_ataque(sessao.caso))
		"anotar_pista":
			return not sessao.caderno.pistas().is_empty()
		"ouvir_testemunha":
			return not sessao.caderno.depoimentos().is_empty()
		"ligar":
			return not sessao.caderno.ligacoes().is_empty()
		"teste_de_campo":
			return sessao._testes_feitos > 0
		"agir":
			return sessao.encerrado()
	return false


## O passo da vez: o primeiro que ainda não foi feito (o último, "fim", nunca termina).
## Os passos podem ser feitos fora de ordem: o mentor só fala do que falta.
static func passo_atual(cfg_tutorial: Dictionary, sessao: RefCounted) -> Dictionary:
	for p in cfg_tutorial["passos"]:
		if p["id"] == "fim" or not feito(p["id"], sessao):
			return p
	return cfg_tutorial["passos"][-1]


## A fala do mentor para o passo, com o caso preenchido.
static func fala(passo: Dictionary, sessao: RefCounted, cfg_tutorial: Dictionary, nome_teste: String) -> String:
	var local := ultimo_ataque(sessao.caso)
	var cliente: Dictionary = sessao.npc(sessao.caso["contrato"]["cliente"])
	var texto := str(passo["fala"])
	texto = texto.replace("{local}", str(sessao.bairro.local(local).get("nome", "lugar do ataque")))
	texto = texto.replace("{cliente}", "%s %s" % [cliente.get("nome", "cliente"), cliente.get("sobrenome", "")])
	return texto.replace("{teste}", nome_teste)


static func objetivo(passo: Dictionary, nome_teste: String) -> String:
	return str(passo["objetivo"]).replace("{teste}", nome_teste)
