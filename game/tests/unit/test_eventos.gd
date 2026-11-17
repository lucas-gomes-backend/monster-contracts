extends "res://tests/framework/test_case.gd"
## Registro e barramento de eventos (core/eventos). Obrigatório: é a fonte da verdade.

const OBRIGATORIO := true
const Registro := preload("res://core/eventos/registro.gd")
const Barramento := preload("res://core/eventos/barramento.gd")


func _registro_exemplo() -> RefCounted:
	var r := Registro.new()
	r.registrar(10, "criatura.ataque", "lobisomem_br#07", "paqueta/galinheiro", {"vitimas": 6})
	r.registrar(12, "npc.viu", "npc#231", "paqueta/galinheiro", {"o_que": "vulto grande"})
	r.registrar(30, "criatura.ataque", "lobisomem_br#07", "morro_sao_bento/rua_2", {"vitimas": 1})
	return r


func test_registro_ids_sao_sequenciais() -> void:
	var r := _registro_exemplo()
	assert_eq([r.obter(0)["id"], r.obter(1)["id"], r.obter(2)["id"]], [0, 1, 2])


func test_registro_evento_fora_de_ordem_e_recusado_e_nao_muda_nada() -> void:
	var r := _registro_exemplo()
	var antes: String = r.hash_canonico()
	assert_eq(r.registrar(5, "atrasado"), {}, "evento no passado recusado")
	assert_eq(r.hash_canonico(), antes, "registro intacto")


func test_registro_busca_por_tipo_ator_local_e_intervalo() -> void:
	var r := _registro_exemplo()
	assert_eq(r.buscar("criatura.ataque").size(), 2, "por tipo")
	assert_eq(r.buscar("", "npc#231").size(), 1, "por ator")
	assert_eq(r.buscar("", "", "paqueta/galinheiro").size(), 2, "por local")
	assert_eq(r.buscar("", "", "", 11, 30).size(), 2, "por intervalo")


func test_registro_quem_le_nao_consegue_alterar() -> void:
	var r := _registro_exemplo()
	var copia: Dictionary = r.obter(0)
	copia["dados"]["vitimas"] = 999
	assert_eq(r.obter(0)["dados"]["vitimas"], 6)


func test_registro_mesmo_historico_gera_mesmo_hash() -> void:
	assert_eq(_registro_exemplo().hash_canonico(), _registro_exemplo().hash_canonico())


func test_registro_historico_diferente_gera_hash_diferente() -> void:
	var outro := _registro_exemplo()
	outro.registrar(40, "npc.viu", "npc#9", "paqueta/cemiterio")
	assert_ne(outro.hash_canonico(), _registro_exemplo().hash_canonico())


func test_barramento_entrega_na_ordem_e_registra_antes() -> void:
	var b := Barramento.new()
	var recebidos := []
	b.assinar("criatura.ataque", func(e): recebidos.append(["a", e["id"], b.registro.tamanho()]))
	b.assinar("*", func(e): recebidos.append(["todos", e["id"]]))
	b.publicar(1, "criatura.ataque", "lobo")
	b.publicar(2, "npc.viu", "npc#1")
	assert_eq(recebidos, [["a", 0, 1], ["todos", 0], ["todos", 1]])
	b.encerrar()


func test_barramento_evento_publicado_por_assinante_vai_para_a_fila() -> void:
	var b := Barramento.new()
	var ordem := []
	b.assinar("criatura.ataque", func(e):
		ordem.append("ataque")
		b.publicar(e["minuto"], "marca.depositada", e["ator"]))
	b.assinar("criatura.ataque", func(_e): ordem.append("ataque-2"))
	b.assinar("marca.depositada", func(_e): ordem.append("marca"))
	b.publicar(5, "criatura.ataque", "lobo")
	assert_eq(ordem, ["ataque", "ataque-2", "marca"], "a marca só é entregue depois do ataque terminar")
	assert_eq(b.registro.tamanho(), 2)
	b.encerrar()


func test_barramento_evento_recusado_nao_chega_a_ninguem() -> void:
	var b := Barramento.new()
	var recebidos := []
	b.assinar("*", func(e): recebidos.append(e["id"]))
	b.publicar(10, "x")
	assert_eq(b.publicar(3, "atrasado"), {})
	assert_eq(recebidos, [0])
