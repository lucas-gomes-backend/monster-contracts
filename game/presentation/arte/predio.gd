extends RefCounted
## Malha de prédio para a fachada (docs/09): uma caixa sem fundo, com as paredes em UV de
## módulos (1 andar de altura x 3 m de largura, 8 módulos por textura) para as janelas ficarem
## do tamanho certo em qualquer prédio. Superfície 0: paredes; 1: telhado.

const LARGURA_DO_MODULO := 3.0
const MODULOS := 8.0


static func malha(tamanho: Vector3, altura_do_andar: float) -> ArrayMesh:
	var m := tamanho / 2.0
	var paredes := SurfaceTool.new()
	paredes.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Cada parede: (canto esquerdo embaixo, canto direito embaixo, normal), olhando de fora.
	var faces := [
		[Vector3(-m.x, -m.y, -m.z), Vector3(m.x, -m.y, -m.z), Vector3(0, 0, -1)],
		[Vector3(m.x, -m.y, m.z), Vector3(-m.x, -m.y, m.z), Vector3(0, 0, 1)],
		[Vector3(-m.x, -m.y, m.z), Vector3(-m.x, -m.y, -m.z), Vector3(-1, 0, 0)],
		[Vector3(m.x, -m.y, -m.z), Vector3(m.x, -m.y, m.z), Vector3(1, 0, 0)],
	]
	for f in faces:
		var a: Vector3 = f[0]
		var b: Vector3 = f[1]
		var largura := a.distance_to(b)
		var cima := Vector3(0, tamanho.y, 0)
		var u := largura / LARGURA_DO_MODULO / MODULOS
		var v := tamanho.y / altura_do_andar / MODULOS
		var cantos := [a, b, b + cima, a + cima]
		var uvs := [Vector2(0, v), Vector2(u, v), Vector2(u, 0), Vector2(0, 0)]
		for i in [0, 2, 1, 0, 3, 2]:
			paredes.set_normal(f[2])
			paredes.set_uv(uvs[i])
			paredes.add_vertex(cantos[i])
	var malha_final := paredes.commit()
	var telhado := SurfaceTool.new()
	telhado.begin(Mesh.PRIMITIVE_TRIANGLES)
	var t := [Vector3(-m.x, m.y, -m.z), Vector3(m.x, m.y, -m.z), Vector3(m.x, m.y, m.z), Vector3(-m.x, m.y, m.z)]
	for i in [0, 1, 2, 0, 2, 3]:
		telhado.set_normal(Vector3.UP)
		telhado.set_uv(Vector2(t[i].x, t[i].z) / 4.0)
		telhado.add_vertex(t[i])
	telhado.commit(malha_final)
	return malha_final
