extends RefCounted
## Peças cinza básicas: blocos com material PS1 (com ou sem colisão) e módulos montados
## a partir de game/data/modulos/*.json (casa, trechos de esgoto).

const Materiais := preload("res://presentation/ps1/materiais.gd")


## Um bloco cinza. Com colisão vira StaticBody3D; sem colisão, só a malha (água, detalhes).
static func bloco(pai: Node, tamanho: Vector3, posicao: Vector3, cor: Color, escala_uv: float, colide: bool = true) -> Node3D:
	var malha := BoxMesh.new()
	malha.size = tamanho
	var visual := MeshInstance3D.new()
	visual.mesh = malha
	visual.material_override = Materiais.objeto(cor, escala_uv)
	if not colide:
		visual.position = posicao
		pai.add_child(visual)
		return visual
	var corpo := StaticBody3D.new()
	corpo.position = posicao
	var forma := BoxShape3D.new()
	forma.size = tamanho
	var colisao := CollisionShape3D.new()
	colisao.shape = forma
	corpo.add_child(colisao)
	corpo.add_child(visual)
	pai.add_child(corpo)
	return corpo


static func vetor(lista: Array) -> Vector3:
	return Vector3(lista[0], lista[1], lista[2])


## Monta um módulo (dados de game/data/modulos/<id>.json) num Node3D novo.
## Os pontos de pista e as passagens viram Marker3D com o id no nome, para quem
## monta a cena encontrar (Pista_<id>, Passagem_<id>).
static func montar_modulo(dados: Dictionary) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Modulo_" + str(dados["id"])
	for b in dados["blocos"]:
		bloco(raiz, vetor(b["tamanho"]), vetor(b["posicao"]), Color.html(b["cor"]),
			float(b.get("escala_uv", 2.0)), bool(b.get("colide", true)))
	for l in dados.get("luzes", []):
		var luz := OmniLight3D.new()
		luz.position = vetor(l["posicao"])
		luz.light_color = Color.html(l["cor"])
		luz.light_energy = l["energia"]
		luz.omni_range = l["alcance"]
		raiz.add_child(luz)
	for p in dados.get("pontos_de_pista", []):
		var marcador := Marker3D.new()
		marcador.name = "Pista_" + str(p["id"])
		marcador.position = vetor(p["posicao"])
		raiz.add_child(marcador)
	for p in dados.get("passagens", []):
		var marcador := Marker3D.new()
		marcador.name = "Passagem_" + str(p["id"])
		marcador.position = vetor(p["posicao"])
		raiz.add_child(marcador)
	return raiz


## Marcadores de um tipo ("Pista_" ou "Passagem_") dentro de um módulo montado.
static func marcadores(modulo: Node3D, prefixo: String) -> Array[Marker3D]:
	var lista: Array[Marker3D] = []
	for filho in modulo.get_children():
		if filho is Marker3D and str(filho.name).begins_with(prefixo):
			lista.append(filho)
	return lista
