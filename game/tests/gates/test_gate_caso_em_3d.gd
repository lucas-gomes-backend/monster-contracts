extends "res://tests/framework/test_case.gd"
## Portão da Fase 2 (docs/11): "um caso gerado jogado do contrato ao relatório, em 3D cinza".
## Um jogador automático usa só o que a cena oferece: o mapa para ir a todos os lugares,
## o exame das pistas que aparecem, a conversa com quem está lá, a pesquisa e, no fim,
## agir pelo mapa com a resposta certa. O caso precisa terminar com sucesso e relatório.
## (O playtest humano continua sendo o portão de verdade; este é o mínimo automático.)

const Catalogo := preload("res://core/dados/catalogo.gd")
const Rua := preload("res://presentation/greybox/rua.gd")

const SEMENTES := [3, 7, 12]


func _jogar(semente: int) -> Dictionary:
	var rua := Rua.new()
	rua.montar(semente)
	var examinadas := 0
	var conversas := 0
	rua.abrir_mapa()
	rua.mapa.pesquisar()
	rua.mapa.fechar()
	for local in rua.sessao.locais():
		rua.ir_para(local)
		for i in rua.pistas.size():
			rua.examinar(i)
			rua.fechar_exame()
			examinadas += 1
		for morador in rua.moradores.duplicate():
			rua.conversar(morador)
			rua.dialogo.escolher_numero(rua.dialogo.ids_das_opcoes().find("perguntar"))
			rua.dialogo.fechar()
			conversas += 1
	var verdade: Dictionary = rua.sessao.caso["verdade"]
	var ficha: Dictionary = Catalogo.carregar_criaturas()["criaturas"][verdade["especie"]]
	rua.abrir_mapa()
	rua.mapa.agir(ficha["resolucoes"][0], verdade["especie"], verdade["hospedeiro"])
	var resultado := {
		"examinadas": examinadas,
		"anotadas": rua.sessao.caderno.pistas().size(),
		"conversas": conversas,
		"sucesso": rua.sessao.desfecho.get("sucesso", false),
		"motivo": rua.sessao.desfecho.get("motivo", ""),
		"registro": rua.mapa.registro.get_parsed_text(),
	}
	rua.free()
	return resultado


func test_gate_caso_jogado_em_3d_do_contrato_ao_relatorio() -> void:
	for semente in SEMENTES:
		var r := _jogar(semente)
		assert_gte(r["examinadas"], 1, "semente %d: achou pistas no 3D" % semente)
		assert_gte(r["anotadas"], r["examinadas"], "semente %d: tudo o que examinou foi anotado" % semente)
		assert_true(r["sucesso"], "semente %d: %s" % [semente, r["motivo"]])
		assert_has(r["registro"], "CASO ENCERRADO", "semente %d: relatório na tela" % semente)
