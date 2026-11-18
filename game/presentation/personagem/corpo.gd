extends RefCounted
## Monta o boneco do caçador em peças low-poly a partir da aparência (core/personagem/aparencia.gd):
## sliders mexem em altura, compleição, pernas, ombros e rosto; pele, cabelo, barba e roupas
## trocam cor e peças. A frente é -Z. Feito de caixas, no espírito PS1, sem arte externa.

const Materiais := preload("res://presentation/ps1/materiais.gd")

const ALTURA_BASE := 1.75


## Apaga o que havia em "no" e monta o boneco. Devolve a altura final.
static func montar(no: Node3D, a: RefCounted) -> float:
	for filho in no.get_children():
		no.remove_child(filho)
		filho.free()
	var s: Dictionary = a.sliders
	var pele: Color = a.cor("peles", a.pele)
	var cor_cabelo: Color = a.cor("cores_de_cabelo", a.cor_do_cabelo)
	var tronco_cor: Color = a.cor("tronco", a.roupas["tronco"])
	var pernas_cor: Color = a.cor("pernas", a.roupas["pernas"])
	var pes_cor: Color = a.cor("pes", a.roupas["pes"])

	var altura := ALTURA_BASE * lerpf(0.9, 1.1, s["altura"])
	var largura := lerpf(0.85, 1.25, s["compleicao"])
	var perna := altura * lerpf(0.44, 0.52, s["pernas"])
	var cabeca_h := altura * lerpf(0.12, 0.14, s["cabeca"])
	var pescoco := altura * 0.04
	var tronco_h := altura - perna - cabeca_h - pescoco
	var ombros := lerpf(0.36, 0.5, s["ombros"]) * largura
	var quadril := 0.3 * largura

	# Pés e pernas.
	for lado in [-1, 1]:
		_caixa(no, Vector3(0.11, 0.08, 0.26), Vector3(lado * quadril * 0.3, 0.04, -0.04), pes_cor)
		_caixa(no, Vector3(0.13 * largura, perna - 0.08, 0.15 * largura), Vector3(lado * quadril * 0.3, 0.08 + (perna - 0.08) / 2.0, 0), pernas_cor)
	# Tronco (roupa) e detalhes da roupa.
	var meio_tronco := perna + tronco_h / 2.0
	_caixa(no, Vector3(ombros, tronco_h, 0.24 * largura), Vector3(0, meio_tronco, 0), tronco_cor)
	match a.roupas["tronco"]:
		"terno":
			_caixa(no, Vector3(0.08, tronco_h * 0.55, 0.02), Vector3(0, perna + tronco_h * 0.7, -0.125 * largura), Color(0.92, 0.92, 0.9))
			_caixa(no, Vector3(0.035, tronco_h * 0.45, 0.025), Vector3(0, perna + tronco_h * 0.66, -0.13 * largura), Color(0.12, 0.14, 0.3))
		"jaqueta_de_couro":
			_caixa(no, Vector3(ombros * 0.7, 0.06, 0.26 * largura), Vector3(0, perna + tronco_h - 0.03, 0), tronco_cor.lightened(0.15))
	# Braços (manga) e mãos.
	for lado in [-1, 1]:
		var x: float = lado * (ombros / 2.0 + 0.06)
		_caixa(no, Vector3(0.11, tronco_h * 0.85, 0.12), Vector3(x, perna + tronco_h * 0.55, 0), tronco_cor)
		_caixa(no, Vector3(0.09, 0.1, 0.1), Vector3(x, perna + tronco_h * 0.08, 0), pele)
	# Pescoço e cabeça.
	var base_cabeca := perna + tronco_h + pescoco
	_caixa(no, Vector3(0.1, pescoco + 0.02, 0.1), Vector3(0, perna + tronco_h + pescoco / 2.0, 0), pele)
	var cabeca_l := 0.2 * lerpf(0.9, 1.1, s["cabeca"])
	var testa := lerpf(0.9, 1.15, s["testa"])
	_caixa(no, Vector3(cabeca_l, cabeca_h * testa, 0.22), Vector3(0, base_cabeca + cabeca_h * testa / 2.0, 0), pele)
	var mandibula := lerpf(0.75, 1.05, s["mandibula"])
	_caixa(no, Vector3(cabeca_l * mandibula, cabeca_h * 0.3, 0.2), Vector3(0, base_cabeca + cabeca_h * 0.12, -0.01), pele.darkened(0.04))
	var nariz := lerpf(0.6, 1.4, s["nariz"])
	_caixa(no, Vector3(0.035 * nariz, 0.05 * nariz, 0.05 * nariz), Vector3(0, base_cabeca + cabeca_h * 0.45, -0.115 - 0.02 * nariz), pele.darkened(0.08))
	var olhos := lerpf(0.035, 0.06, s["olhos"])
	for lado in [-1, 1]:
		_caixa(no, Vector3(0.03, 0.02, 0.01), Vector3(lado * olhos, base_cabeca + cabeca_h * 0.62, -0.111), Color(0.08, 0.06, 0.05))
	var topo := base_cabeca + cabeca_h * testa
	_cabelo(no, a.cabelo, cor_cabelo, cabeca_l, topo, base_cabeca, cabeca_h)
	_barba(no, a.barba, cor_cabelo, cabeca_l * mandibula, base_cabeca, cabeca_h)
	_chapeu(no, a.roupas.get("cabeca", "nada"), a.cor("cabeca", a.roupas.get("cabeca", "nada")), cabeca_l, topo)
	return altura


static func _cabelo(no: Node3D, estilo: String, cor: Color, l: float, topo: float, base: float, h: float) -> void:
	match estilo:
		"curto":
			_caixa(no, Vector3(l + 0.02, 0.04, 0.24), Vector3(0, topo + 0.01, 0.005), cor)
			_caixa(no, Vector3(l + 0.02, h * 0.5, 0.03), Vector3(0, topo - h * 0.25, 0.11), cor)
		"comprido":
			_caixa(no, Vector3(l + 0.03, 0.05, 0.25), Vector3(0, topo + 0.015, 0.005), cor)
			_caixa(no, Vector3(l + 0.04, h * 1.2, 0.05), Vector3(0, topo - h * 0.55, 0.11), cor)
		"black_power":
			_caixa(no, Vector3(l + 0.12, h * 0.75, 0.32), Vector3(0, topo - h * 0.05, 0.02), cor)
		"rabo_de_cavalo":
			_caixa(no, Vector3(l + 0.02, 0.04, 0.24), Vector3(0, topo + 0.01, 0.005), cor)
			_caixa(no, Vector3(0.06, h * 0.9, 0.06), Vector3(0, topo - h * 0.5, 0.15), cor)


static func _barba(no: Node3D, estilo: String, cor: Color, l: float, base: float, h: float) -> void:
	match estilo:
		"bigode":
			_caixa(no, Vector3(0.08, 0.018, 0.02), Vector3(0, base + h * 0.36, -0.12), cor)
		"cavanhaque":
			_caixa(no, Vector3(0.06, h * 0.22, 0.03), Vector3(0, base + h * 0.12, -0.115), cor)
		"cheia":
			_caixa(no, Vector3(l + 0.01, h * 0.38, 0.21), Vector3(0, base + h * 0.16, -0.012), cor)


static func _chapeu(no: Node3D, tipo: String, cor: Color, l: float, topo: float) -> void:
	match tipo:
		"bone":
			_caixa(no, Vector3(l + 0.03, 0.07, 0.25), Vector3(0, topo + 0.03, 0.005), cor)
			_caixa(no, Vector3(l * 0.9, 0.015, 0.1), Vector3(0, topo + 0.005, -0.16), cor)
		"chapeu":
			_caixa(no, Vector3(0.38, 0.015, 0.38), Vector3(0, topo + 0.005, 0), cor)
			_caixa(no, Vector3(l + 0.02, 0.1, 0.23), Vector3(0, topo + 0.06, 0), cor)


static func _caixa(no: Node3D, tamanho: Vector3, posicao: Vector3, cor: Color) -> MeshInstance3D:
	var malha := BoxMesh.new()
	malha.size = tamanho
	var m := MeshInstance3D.new()
	m.mesh = malha
	m.position = posicao
	m.material_override = Materiais.objeto(cor, 1.0)
	no.add_child(m)
	return m
