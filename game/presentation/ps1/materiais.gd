extends RefCounted
## Materiais dos módulos cinza (greybox), da cidade e do caçador. O efeito PS1 (tremor dos
## vértices, textura afim e pontilhado da tela) liga e desliga em game/data/config/visual.json.

const Catalogo := preload("res://core/dados/catalogo.gd")
const SHADER_OBJETO := preload("res://presentation/ps1/ps1.gdshader")
const SHADER_TELA := preload("res://presentation/ps1/tela_ps1.gdshader")
const SHADER_FACHADA := preload("res://presentation/ps1/fachada.gdshader")
const Texturas := preload("res://presentation/arte/texturas.gd")
## Grade tão fina que nenhum vértice treme (efeito PS1 desligado).
const GRADE_SEM_TREMOR := Vector2(100000.0, 100000.0)

static var _grade: Texture2D
## Materiais de fachada, um por cor (compartilhados): a noite liga as janelas de todos de uma vez.
static var _fachadas: Dictionary = {}
static var _noite := 0.0
static var _efeito: Variant = null


## O efeito PS1 está ligado? (lido uma vez do config de visual)
static func efeito_ps1() -> bool:
	if _efeito == null:
		var dados: Variant = Catalogo.carregar_config_visual()["dados"]
		_efeito = dados is Dictionary and bool(dados.get("efeito_ps1", true))
	return _efeito


## Material de objeto com uma cor e a textura de grade.
## afim: 1 = textura entorta como no PS1; menos que 1 suaviza. Com o efeito PS1 desligado,
## a textura não entorta e os vértices não tremem.
static func objeto(cor: Color, escala_uv: float = 1.0, afim: float = 1.0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER_OBJETO
	material.set_shader_parameter("cor", cor)
	material.set_shader_parameter("escala_uv", escala_uv)
	material.set_shader_parameter("afim", afim if efeito_ps1() else 0.0)
	if not efeito_ps1():
		material.set_shader_parameter("grade", GRADE_SEM_TREMOR)
	material.set_shader_parameter("textura", grade())
	return material


## Objeto com uma textura gerada (asfalto, calçada portuguesa) em vez da grade.
static func com_textura(cor: Color, textura: Texture2D, escala_uv: float = 1.0, afim: float = 1.0) -> ShaderMaterial:
	var material := objeto(cor, escala_uv, afim)
	material.set_shader_parameter("textura", textura)
	return material


## Fachada de prédio: parede com janelas (UV em módulos de 1 andar x 3 m) que acendem à
## noite. Um material por cor, guardado.
static func fachada(cor: Color, fracao_acesas: float = 0.35, cor_janela: Color = Color(1.0, 0.81, 0.48), brilho: float = 1.6) -> ShaderMaterial:
	var chave := cor.to_html(false)
	if not _fachadas.has(chave):
		var material := ShaderMaterial.new()
		material.shader = SHADER_FACHADA
		material.set_shader_parameter("cor", cor)
		material.set_shader_parameter("textura", Texturas.fachada())
		material.set_shader_parameter("janelas", Texturas.janelas(fracao_acesas))
		material.set_shader_parameter("cor_janela", cor_janela)
		material.set_shader_parameter("brilho", brilho)
		material.set_shader_parameter("noite", _noite)
		material.set_shader_parameter("afim", 1.0 if efeito_ps1() else 0.0)
		if not efeito_ps1():
			material.set_shader_parameter("grade", GRADE_SEM_TREMOR)
		_fachadas[chave] = material
	return _fachadas[chave]


## Liga (1) ou desliga (0) as janelas acesas de todas as fachadas.
static func definir_noite(valor: float) -> void:
	_noite = valor
	for chave in _fachadas:
		_fachadas[chave].set_shader_parameter("noite", valor)


static func noite() -> float:
	return _noite


## Material do filtro de tela (cores reduzidas com pontilhado).
static func tela() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER_TELA
	return material


## O filtro de tela pronto para pôr numa CanvasLayer: só aparece com o efeito PS1 ligado.
static func filtro_de_tela() -> ColorRect:
	var filtro := ColorRect.new()
	filtro.name = "FiltroPS1"
	filtro.set_anchors_preset(Control.PRESET_FULL_RECT)
	filtro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filtro.material = tela()
	filtro.visible = efeito_ps1()
	return filtro


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
