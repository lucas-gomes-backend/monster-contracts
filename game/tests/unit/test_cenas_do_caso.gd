extends "res://tests/framework/test_case.gd"
## Fase 2: o núcleo ligado às cenas. Cada lugar do caso vira um cenário cinza (casa ou rua),
## com as pistas do caso daquele lugar e daquela hora e as pessoas que estão lá; o mapa
## leva de um lugar a outro, pesquisa, faz testes e encerra o caso.

const Catalogo := preload("res://core/dados/catalogo.gd")
const Rua := preload("res://presentation/greybox/rua.gd")
const Blocos := preload("res://presentation/greybox/blocos.gd")

var _rua: Node3D


func before_each() -> void:
	_rua = Rua.new()
	_rua.montar(12)


func after_each() -> void:
	_rua.free()


func _botoes(no: Node) -> Array:
	var lista: Array = []
	for filho in no.get_children():
		if filho is Button:
			lista.append(filho)
		lista.append_array(_botoes(filho))
	return lista


func _uma_casa_com_gente() -> String:
	for c in _rua.sessao.casas():
		var s: RefCounted = _rua.sessao
		var antes: int = s.minuto
		var antes_local: String = s.local_atual()
		s._local_atual = c["local"]
		var gente: int = s.pessoas_aqui().size()
		s._local_atual = antes_local
		s.minuto = antes
		if gente > 0:
			return c["local"]
	return ""


func test_antes_de_ir_a_algum_lugar_so_o_cliente_esta_na_rua() -> void:
	assert_eq(_rua.pistas.size(), 0, "nenhum lugar escolhido, nenhuma pista")
	assert_eq(_rua.moradores.size(), 1)
	assert_eq(_rua.moradores[0].npc_id, _rua.sessao.caso["contrato"]["cliente"])


func test_ir_ao_bar_gasta_tempo_e_poe_as_pistas_nos_pontos_da_rua() -> void:
	var antes: int = _rua.sessao.minuto
	_rua.ir_para("paqueta/bar")
	assert_true(_rua.sessao.minuto > antes, "o tempo passou")
	assert_eq(_rua.cenario, "rua", "o bar usa a rua")
	assert_eq(_rua.pistas.size(), _rua.sessao.pistas_no_local().size())
	var pontos: Array = []
	for p in Catalogo.carregar_greybox("rua")["dados"]["pontos_de_pista"]:
		pontos.append(Blocos.vetor(p["posicao"]))
	for pista in _rua.pistas:
		assert_has(pontos, pista.position, "a pista está num ponto de pista da rua")
	assert_eq(_rua.cacador.position, Blocos.vetor(Catalogo.carregar_greybox("rua")["dados"]["chegada"]))


func test_quem_esta_no_lugar_aparece_para_conversar() -> void:
	_rua.ir_para("paqueta/bar")
	var ids: Array = []
	for m in _rua.moradores:
		ids.append(m.npc_id)
	assert_eq(ids, Array(_rua.sessao.pessoas_aqui()), "as mesmas pessoas que o núcleo diz estarem lá")


func test_casa_usa_o_interior_e_poe_as_pessoas_la_dentro() -> void:
	var casa := _uma_casa_com_gente()
	assert_false(casa.is_empty(), "achou uma casa com gente acordada")
	_rua.ir_para(casa)
	assert_eq(_rua.cenario, "casa")
	assert_true(_rua.cacador.position.x < -6.0, "o caçador entrou pela porta")
	assert_gte(_rua.moradores.size(), 1)
	for m in _rua.moradores:
		assert_true(m.position.x < -6.0 and absf(m.position.z - 12.0) < 4.0, "%s está dentro da casa" % m.nome)


func test_trocar_de_lugar_tira_as_pistas_e_pessoas_do_lugar_anterior() -> void:
	_rua.ir_para("paqueta/bar")
	var do_bar: Array = []
	for p in _rua.pistas:
		do_bar.append(p.pista_id)
	_rua.ir_para("paqueta/galinheiro_1")
	for p in _rua.pistas:
		assert_false(p.pista_id in do_bar, "pista do bar não aparece no galinheiro")
	for p in _rua.sessao.pistas_no_local():
		assert_eq(p["local"], "paqueta/galinheiro_1")


func test_pista_que_sumiu_com_o_tempo_nao_aparece() -> void:
	_rua.sessao.minuto += 30 * 24 * 60
	_rua.ir_para("paqueta/bar")
	for pista in _rua.sessao.pistas_no_local():
		assert_ne(pista["onde"], "cena", "pista de cena não dura um mês")
	assert_eq(_rua.pistas.size(), _rua.sessao.pistas_no_local().size())


func test_mapa_tem_todos_os_lugares_e_casas_e_clicar_leva_ate_la() -> void:
	_rua.abrir_mapa()
	assert_true(_rua.mapa.aberto)
	assert_true(_rua.cacador.bloqueado)
	var lugares: Array = _botoes(_rua.mapa.lugares)
	assert_eq(lugares.size(), _rua.sessao.locais().size() + _rua.sessao.casas().size())
	_rua.mapa.lugares.get_node("Lugar_paqueta_bar").pressed.emit()
	assert_eq(_rua.sessao.local_atual(), "paqueta/bar")
	assert_false(_rua.mapa.aberto, "o mapa fecha ao viajar")
	assert_false(_rua.cacador.bloqueado)


func test_mapa_pesquisar_e_testar_usam_a_sessao() -> void:
	_rua.abrir_mapa()
	_rua.mapa.pesquisar()
	assert_true(_rua.sessao.pesquisou)
	var antes: int = _rua.sessao.minuto
	var teste: Dictionary = _rua.sessao.testes_disponiveis()[0]
	var alvo: String = _rua.sessao.caso["npcs"][0]["id"] if teste["alvo"] == "pessoa" else _rua.sessao.locais()[0]
	_rua.mapa.testar(teste["id"], alvo)
	assert_true(_rua.sessao.minuto > antes, "o teste leva tempo")
	assert_has(_rua.mapa.registro.get_parsed_text(), teste["nome"])


func test_mapa_ligar_para_o_cliente_abre_a_conversa() -> void:
	_rua.ir_para("paqueta/bar")
	_rua.abrir_mapa()
	_rua.mapa.ligou_cliente.emit()
	assert_false(_rua.mapa.aberto)
	assert_true(_rua.dialogo.aberta, "conversa com o cliente, de onde estiver")


func test_mapa_agir_encerra_o_caso_e_mostra_o_relatorio() -> void:
	_rua.abrir_mapa()
	_rua.mapa.agir("abandonar", "", "")
	assert_true(_rua.sessao.encerrado())
	assert_has(_rua.mapa.registro.get_parsed_text(), "CASO ENCERRADO")
	for botao in _botoes(_rua.mapa.lugares):
		assert_true(botao.disabled, "depois de encerrar não se viaja mais")
