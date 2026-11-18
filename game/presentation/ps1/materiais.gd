extends RefCounted
## Materiais PS1 prontos para os módulos cinza (greybox) e o caçador.

const SHADER_OBJETO := preload("res://presentation/ps1/ps1.gdshader")
const SHADER_TELA := preload("res://presentation/ps1/tela_ps1.gdshader")

static var _grade: Texture2D


## Material de objeto PS1 com uma cor e a textura de grade (mostra o entortar afim).
## afim: 1 = textura entorta como no PS1; menos que 1 suaviza (chão grande e inclinado).
static func objeto(cor: Color, escala_uv: float = 1.0, afim: float = 1.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER_OBJETO
	material.set_shader_parameter("cor", cor)
	material.set_shader_parameter("escala_uv", escala_uv)
	material.set_shader_parameter("afim", afim)
	material.set_shader_parameter("textura", grade())
	return material


## Material do filtro de tela (cores reduzidas com pontilhado).
static func tela() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER_TELA
	return material


## Textura 16x16 de módulo cinza: bordas mais escuras, para ver escala e o entortar da textura.
static func grade() -> Texture2D:
	if _grade == null:
		var imagem := Image.create(16, 16, false, Image.FORMAT_RGB8)
		for y in 16:
			for x in 16:
				var borda := x == 0 or y == 0
				var meio := x == 8 or y == 8
				var tom := 0.62 if borda else (0.85 if meio else 1.0)
				imagem.set_pixel(x, y, Color(tom, tom, tom))
		_grade = ImageTexture.create_from_image(imagem)
	return _grade
