extends "res://tests/framework/test_case.gd"
## Fase 2: caderno com arrastar e soltar. Arrastar um cartão de evidência e soltar numa
## característica liga as duas no caderno do núcleo; o "x" desliga; as espécies mostram
## quais ainda explicam as ligações.

const Rua := preload("res://presentation/greybox/rua.gd")
const CartaoEvidencia := preload("res://presentation/caderno/cartao_evidencia.gd")
const AlvoCaracteristica := preload("res://presentation/caderno/alvo_caracteristica.gd")

var _rua: Node3D
## Uma pista do caso já anotada (a primeira do bar, na semente 12).
var _fonte: String = ""


func before_each() -> void:
	_rua = Rua.new()
	_rua.montar(12)
	_rua.ir_para("paqueta/bar")
	for pista in _rua.pistas:
		_rua.sessao.examinar_pista(pista.pista_id)
	_fonte = _rua.pistas[0].pista_id
	_rua.abrir_caderno()


func after_each() -> void:
	_rua.free()


func _cartao(fonte: String) -> Node:
	for filho in _rua.caderno.evidencias.get_children():
		if filho is CartaoEvidencia and filho.fonte == fonte:
			return filho
	return null


func _alvo(tag: String) -> Node:
	for filho in _rua.caderno.caracteristicas.get_children():
		if filho is AlvoCaracteristica and filho.tag == tag:
			return filho
	return null


func _botoes(no: Node) -> Array:
	var lista: Array = []
	for filho in no.get_children():
		if filho is Button:
			lista.append(filho)
		lista.append_array(_botoes(filho))
	return lista


func test_caderno_mostra_um_cartao_por_evidencia_e_todo_o_bestiario() -> void:
	var c: RefCounted = _rua.sessao.caderno
	assert_true(_rua.caderno.aberto)
	assert_true(_rua.cacador.bloqueado, "o caçador para enquanto lê")
	assert_false(_rua.camada_interface.visible, "a interface da rua sai da frente")
	assert_eq(_rua.caderno.evidencias.get_child_count(), c.pistas().size() + c.depoimentos().size())
	assert_eq(_rua.caderno.caracteristicas.get_child_count(), c.vocabulario().size())
	assert_eq(_rua.caderno.especies.get_child_count(), c.especies().size())


func test_caderno_soltar_cartao_numa_caracteristica_liga_as_duas() -> void:
	var cartao: Node = _cartao(_fonte)
	assert_true(cartao != null, "o cartão da pista existe")
	var dados: Dictionary = cartao.dados_do_arraste()
	var alvo: Node = _alvo("pegadas_cao_grande")
	assert_true(alvo.aceita(dados), "a característica aceita o cartão")
	assert_false(alvo.aceita({"tipo": "outra_coisa"}), "não aceita qualquer coisa")
	alvo.receber(dados)
	assert_has(_rua.sessao.caderno.ligacoes().get(_fonte, []), "pegadas_cao_grande")
	assert_has(_cartao(_fonte).get_child(0).get_child(2).text, "1 ligação", "o cartão mostra a ligação")


func test_caderno_ligacao_errada_tambem_e_aceita_e_elimina_errado() -> void:
	# O caderno não julga: ligar a pegada a uma característica de outra espécie é permitido.
	var tags_do_corpo_seco: Array = _rua.sessao.caderno.caracteristicas_de("corpo_seco")
	_alvo(tags_do_corpo_seco[0]).receber(_cartao(_fonte).dados_do_arraste())
	assert_has(_rua.sessao.caderno.ligacoes()[_fonte], tags_do_corpo_seco[0])
	assert_eq(_rua.sessao.caderno.compativeis().has("corpo_seco"), true, "o corpo-seco continua compatível")


func test_caderno_x_desliga() -> void:
	_alvo("pegadas_cao_grande").receber({"tipo": "evidencia", "fonte": _fonte})
	var tirar: Array = _botoes(_alvo("pegadas_cao_grande"))
	assert_eq(tirar.size(), 1, "um x por evidência ligada")
	tirar[0].pressed.emit()
	assert_false(_rua.sessao.caderno.ligacoes().has(_fonte), "desligou")


func test_caderno_especie_que_nao_explica_a_ligacao_aparece_apagada() -> void:
	_alvo("pegadas_cao_grande").receber({"tipo": "evidencia", "fonte": _fonte})
	var ficha: Node = _rua.caderno.especies.get_node("Especie_corpo_seco")
	assert_eq(ficha.get_child(1).text, "não explica")
	var lobisomem: Node = _rua.caderno.especies.get_node("Especie_lobisomem_br")
	assert_eq(lobisomem.get_child(1).text, "compatível")


func test_caderno_riscar_e_circular_pelos_botoes() -> void:
	var ficha: Node = _rua.caderno.especies.get_node("Especie_corpo_seco")
	_botoes(ficha)[0].pressed.emit()
	assert_has(_rua.sessao.caderno.riscadas(), "corpo_seco")
	ficha = _rua.caderno.especies.get_node("Especie_lobisomem_br")
	_botoes(ficha)[1].pressed.emit()
	assert_eq(_rua.sessao.caderno.circulada(), "lobisomem_br")


func test_caderno_fechar_solta_o_cacador() -> void:
	_rua.caderno.fechar()
	assert_false(_rua.caderno.aberto)
	assert_false(_rua.cacador.bloqueado)
	assert_true(_rua.camada_interface.visible, "a interface da rua volta")


func test_rua_examinar_e_fotografar_anotam_no_caderno() -> void:
	var rua := Rua.new()
	rua.montar(12)
	rua.ir_para("paqueta/bar")
	assert_eq(rua.sessao.caderno.pistas().size(), 0, "chegar não anota nada")
	rua.examinar(0)
	rua.fechar_exame()
	assert_eq(rua.sessao.caderno.pistas().size(), 1, "examinar anota a pista")
	var pista: Node3D = rua.pistas[1]
	var olho: Vector3 = pista.position + Vector3(0, 1.5, 3.0)
	rua.fotografar(olho, (pista.position - olho).normalized(), 30.0)
	var ids: Array = []
	for p in rua.sessao.caderno.pistas():
		ids.append(p["id"])
	assert_has(ids, pista.pista_id, "a foto anota a pista")
	rua.free()
