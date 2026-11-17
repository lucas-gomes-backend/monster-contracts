extends "res://tests/framework/test_case.gd"
## Caderno do caçador (core/caderno/caderno.gd).

const Caderno := preload("res://core/caderno/caderno.gd")

## Bestiário mínimo: duas espécies com uma marca em comum.
const FICHAS := {
	"lobo": {"marcas": [{"tag": "pegada_grande"}, {"tag": "uivo"}]},
	"mula": {"marcas": [{"tag": "pegada_grande"}, {"tag": "casco"}]},
}


func _caderno() -> RefCounted:
	var c := Caderno.new(FICHAS)
	c.anotar_pista({"id": "pista_001", "tag": "uivo"})
	c.anotar_pista({"id": "pista_002", "tag": "pegada_grande"})
	return c


func test_caderno_pista_repetida_nao_entra_duas_vezes() -> void:
	var c := _caderno()
	assert_false(c.anotar_pista({"id": "pista_001", "tag": "uivo"}))
	assert_eq(c.pistas().size(), 2)


func test_caderno_so_liga_evidencia_anotada() -> void:
	assert_eq(_caderno().ligar("pista_999", "uivo"), "essa evidência não está no caderno")


func test_caderno_so_liga_caracteristica_do_bestiario() -> void:
	assert_eq(_caderno().ligar("pista_001", "lixo_revirado"), "essa característica não está no bestiário")


func test_caderno_ligacao_filtra_as_compativeis() -> void:
	var c := _caderno()
	assert_eq(c.compativeis(), ["lobo", "mula"], "sem ligações")
	c.ligar("pista_002", "pegada_grande")
	assert_eq(c.compativeis(), ["lobo", "mula"], "marca em comum não separa")
	c.ligar("pista_001", "uivo")
	assert_eq(c.compativeis(), ["lobo"], "uivo só o lobo explica")


func test_caderno_nao_julga_se_a_ligacao_esta_certa() -> void:
	var c := _caderno()
	assert_eq(c.ligar("pista_001", "casco"), "", "ligar o uivo a 'casco' é erro do jogador, não do caderno")
	assert_eq(c.compativeis(), ["mula"], "e a eliminação sai errada, como deve")


func test_caderno_desligar_desfaz() -> void:
	var c := _caderno()
	c.ligar("pista_001", "uivo")
	c.desligar("pista_001", "uivo")
	assert_eq(c.tags_ligadas(), [])
	assert_eq(c.compativeis(), ["lobo", "mula"])


func test_caderno_modo_puro_nao_filtra() -> void:
	var c := _caderno()
	c.ligar("pista_001", "uivo")
	c.definir_modo("puro")
	assert_eq(c.compativeis(), ["lobo", "mula"])


func test_caderno_sugestoes_so_no_modo_assistido() -> void:
	var c := _caderno()
	assert_eq(c.sugestoes(), [], "padrão não sugere")
	c.definir_modo("assistido")
	assert_eq(c.sugestoes().size(), 2, "sugere as duas ligações óbvias")
	c.ligar("pista_001", "uivo")
	assert_eq(c.sugestoes().size(), 1, "não sugere o que já foi ligado")


func test_caderno_circular_tira_da_lista_de_riscadas() -> void:
	var c := _caderno()
	c.riscar("lobo")
	c.circular("lobo")
	assert_eq(c.riscadas(), [])
	assert_eq(c.circulada(), "lobo")
	assert_false(c.riscar("saci"), "espécie fora do bestiário")


func test_caderno_respostas_so_para_as_tres_perguntas() -> void:
	var c := _caderno()
	assert_true(c.responder("quem", "o filho da vizinha"))
	assert_false(c.responder("onde", "aqui"))
	assert_eq(c.respostas()["quem"], "o filho da vizinha")


func test_caderno_estado_e_estavel() -> void:
	var a := _caderno()
	var b := _caderno()
	for c in [a, b]:
		c.ligar("pista_001", "uivo")
		c.riscar("mula")
	assert_eq(JSON.stringify(a.para_dicionario(), "", true), JSON.stringify(b.para_dicionario(), "", true))
