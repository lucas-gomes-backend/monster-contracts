extends "res://tests/framework/test_case.gd"
## Fase 4: suspeita, polícia e maré na cidade 3D (presentation/cidade/bairro_cena.gd).

const Cena := preload("res://presentation/cidade/bairro_cena.gd")
const Suspeita := preload("res://core/mundo/suspeita.gd")

var _cena: Node3D


func before_each() -> void:
	_cena = Cena.new()
	_cena.montar("valongo", 1)


func after_each() -> void:
	_cena.free()


func _mare_baixa() -> void:
	_cena.minuto = _cena.mare.proxima_preamar(_cena.minuto) + _cena.mare.periodo / 2


func test_sair_do_esgoto_sujo_e_ser_visto_faz_a_suspeita_subir() -> void:
	_mare_baixa()
	_cena.usar_bueiro(0)
	assert_eq(_cena.zona, "esgoto")
	_cena.usar_bueiro(0)
	assert_eq(_cena.zona, "rua")
	assert_true(_cena.suspeita.sujo(_cena.minuto), "sai sujo do esgoto")
	# Um transeunte bem do lado.
	var a: Dictionary = _cena.transeuntes["valongo"].andantes[0]
	a["no"].visible = true
	a["no"].position = _cena.cacador.position
	var antes: int = _cena.suspeita.pontos("valongo")
	_cena.passar_tempo(1.0 / _cena.minutos_por_segundo)
	assert_true(_cena.suspeita.pontos("valongo") > antes, "quem viu desconfia")


func test_limpo_ninguem_desconfia() -> void:
	var a: Dictionary = _cena.transeuntes["valongo"].andantes[0]
	a["no"].visible = true
	a["no"].position = _cena.cacador.position
	_cena.passar_tempo(5.0 / _cena.minutos_por_segundo)
	assert_eq(_cena.suspeita.pontos("valongo"), 0)


func test_mare_alta_alaga_a_galeria_e_nao_deixa_descer() -> void:
	_cena.minuto = _cena.mare.proxima_preamar(_cena.minuto)
	_cena.usar_bueiro(0)
	assert_eq(_cena.zona, "rua", "na maré alta, a galeria está alagada")
	_mare_baixa()
	_cena.usar_bueiro(0)
	assert_eq(_cena.zona, "esgoto", "na baixa, desce")


func test_agua_das_galerias_acompanha_a_mare() -> void:
	_cena.minuto = _cena.mare.proxima_preamar(_cena.minuto) - 1
	_cena.passar_tempo(1.0 / _cena.minutos_por_segundo)
	var alta: float = _cena.subterraneo.agua.position.y
	_mare_baixa()
	_cena.passar_tempo(1.0 / _cena.minutos_por_segundo)
	var baixa: float = _cena.subterraneo.agua.position.y
	assert_true(alta > baixa + 0.3, "a água sobe com a maré (alta %.2f, baixa %.2f)" % [alta, baixa])


func test_policia_aparece_conforme_a_suspeita() -> void:
	assert_eq(_cena.policia.visiveis(), 0, "normal: nenhum policial")
	_cena.suspeita.somar("valongo", 30, "teste", _cena.minuto)
	_cena.passar_tempo(1.0 / _cena.minutos_por_segundo)
	assert_eq(_cena.suspeita.nivel("valongo"), Suspeita.OBSERVADO)
	assert_gte(_cena.policia.visiveis(), 1, "observado: patrulha na rua")


func test_procurado_a_policia_alcanca_e_detem() -> void:
	_cena.suspeita.somar("valongo", 80, "teste", _cena.minuto)
	_cena.passar_tempo(1.0 / _cena.minutos_por_segundo)
	assert_eq(_cena.policia.nivel, Suspeita.PROCURADO)
	var quem: Dictionary = _cena.policia.policiais[0]
	assert_true(quem["perseguindo"], "um policial vem atrás")
	# O policial chega perto do caçador.
	quem["no"].position = _cena.cacador.position + Vector3(0.5, 0, 0)
	var antes: int = _cena.minuto
	_cena.passar_tempo(0.1)
	assert_eq(_cena.detencoes, 1, "detido")
	assert_gte(_cena.minuto - antes, 240, "perdeu horas: o mundo seguiu")
	assert_true(_cena.suspeita.pontos("valongo") < 50, "a suspeita cai depois da detenção")
	var na_delegacia := false
	for b in _cena.populacoes:
		for ponto in _cena.populacoes[b].pontos_chave:
			if ponto["tipo"] == "delegacia":
				var p: Vector2 = ponto["porta"]
				na_delegacia = Vector2(_cena.cacador.position.x, _cena.cacador.position.z).distance_to(p) < 0.5
	assert_true(na_delegacia, "sai na porta da delegacia")


func test_painel_mostra_mare_e_suspeita() -> void:
	var texto: String = _cena.texto_do_painel()
	assert_has(texto, "Maré")
	assert_has(texto, "Suspeita: normal")
