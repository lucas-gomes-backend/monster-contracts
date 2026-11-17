extends "res://tests/framework/test_case.gd"
## Janela da investigação (ui/jogo.gd), sem abrir janela: monta a interface e simula cliques.

const Jogo := preload("res://ui/jogo.gd")

var _jogo: Control


func before_each() -> void:
	_jogo = Jogo.new()
	_jogo.montar()
	_jogo.novo_caso(12)


func after_each() -> void:
	_jogo.free()


func _botoes(caixa: Node) -> Array:
	var lista: Array = []
	for filho in caixa.get_children():
		if filho is Button:
			lista.append(filho)
		lista.append_array(_botoes(filho))
	return lista


func _primeiro(caixa: Node, tipo: String) -> Node:
	for filho in caixa.get_children():
		if filho.is_class(tipo):
			return filho
		var achado := _primeiro(filho, tipo)
		if achado:
			return achado
	return null


func test_janela_mostra_lugares_e_casas() -> void:
	var esperado: int = _jogo.sessao.locais().size() + _jogo.sessao.casas().size()
	assert_eq(_botoes(_jogo._lugares).size(), esperado)


func test_janela_clicar_num_lugar_vai_ate_la_e_gasta_tempo() -> void:
	var antes: int = _jogo.sessao.minuto
	var botao: Button = _botoes(_jogo._lugares)[3]
	botao.pressed.emit()
	assert_false(_jogo.sessao.local_atual().is_empty(), "foi a algum lugar")
	assert_true(_jogo.sessao.minuto > antes, "o tempo passou")
	assert_has(_jogo._diario.get_parsed_text(), "examinou o lugar")


func test_janela_cada_pista_vira_um_cartao_e_da_para_ligar() -> void:
	# Pega os botões de novo a cada clique: a tela é redesenhada depois de cada ação,
	# e um jogador só consegue clicar no que está na tela.
	for i in 5:
		_botoes(_jogo._lugares)[i].pressed.emit()
	var pistas: Array = _jogo.sessao.caderno.pistas()
	assert_gte(pistas.size(), 1, "achou alguma pista")
	assert_eq(_jogo._pistas.get_child_count(), pistas.size(), "um cartão por pista")
	var seletor: OptionButton = _primeiro(_jogo._pistas.get_child(0), "OptionButton")
	seletor.item_selected.emit(1)
	assert_eq(_jogo.sessao.caderno.ligacoes().size(), 1, "a ligação entrou no caderno")


func test_janela_agir_encerra_e_trava_as_acoes() -> void:
	_jogo._resolucao_opcao.select(RESOLUCOES_ABANDONAR())
	_jogo._agir()
	assert_true(_jogo.sessao.encerrado())
	var antes: int = _jogo.sessao.minuto
	_botoes(_jogo._lugares)[0].pressed.emit()
	assert_eq(_jogo.sessao.minuto, antes, "depois de encerrar, não investiga mais")


func RESOLUCOES_ABANDONAR() -> int:
	return Jogo.RESOLUCOES.find("abandonar")


func test_janela_novo_caso_recomeca_do_zero() -> void:
	_botoes(_jogo._lugares)[0].pressed.emit()
	_jogo.novo_caso(13)
	assert_eq(_jogo.semente, 13)
	assert_eq(_jogo.sessao.caderno.pistas().size(), 0)
	assert_true(_jogo.sessao.local_atual().is_empty())
