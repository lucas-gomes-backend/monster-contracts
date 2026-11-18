extends RefCounted
## Texturas geradas por código para a primeira passada de arte (docs/09): pequenas, sem
## suavização, no espírito PS1. Feitas uma vez e guardadas. O sorteio dos detalhes usa um
## stream do core/rng.gd com semente fixa: as texturas são sempre as mesmas.
##   fachada: 8 x 8 módulos (cada um = 1 andar x 3 m), parede com janelas escuras
##   janelas: a máscara das janelas acesas à noite (as mesmas casas da fachada)
##   asfalto e calçada portuguesa (as ondas pretas e brancas da orla de Santos)

const Rng := preload("res://core/rng.gd")

const MODULOS := 8  # módulos por lado da textura de fachada
const PX := 16  # pixels por módulo

static var _cache: Dictionary = {}


static func fachada() -> Texture2D:
	if not _cache.has("fachada"):
		var tam := MODULOS * PX
		var img := Image.create(tam, tam, false, Image.FORMAT_RGB8)
		var g: RandomNumberGenerator = Rng.new(17).stream("textura:fachada")
		for y in tam:
			for x in tam:
				var mx := x % PX
				var my := y % PX
				var tom := 0.86 + g.randf() * 0.1
				if my == PX - 1:
					tom *= 0.72  # linha entre andares
				var janela := mx >= 4 and mx <= 11 and my >= 4 and my <= 11
				if janela:
					tom = 0.22 + (0.06 if mx == 7 or my == 7 else 0.0)  # vidro escuro com a cruz do caixilho
				elif (mx == 3 or mx == 12) and my >= 3 and my <= 12 or (my == 12 and mx >= 3 and mx <= 12):
					tom = 0.95  # moldura e peitoril
				img.set_pixel(x, y, Color(tom, tom, tom))
		_cache["fachada"] = ImageTexture.create_from_image(img)
	return _cache["fachada"]


## Máscara das janelas acesas (branco = acesa). "fracao" das janelas acendem à noite.
static func janelas(fracao: float) -> Texture2D:
	var chave := "janelas:%.2f" % fracao
	if not _cache.has(chave):
		var tam := MODULOS * PX
		var img := Image.create(tam, tam, false, Image.FORMAT_RGB8)
		img.fill(Color.BLACK)
		var g: RandomNumberGenerator = Rng.new(17).stream("textura:janelas")
		for my in MODULOS:
			for mx in MODULOS:
				if g.randf() >= fracao:
					continue
				for y in range(my * PX + 4, my * PX + 12):
					for x in range(mx * PX + 4, mx * PX + 12):
						if (x - mx * PX) != 7 and (y - my * PX) != 7:
							img.set_pixel(x, y, Color.WHITE)
		_cache[chave] = ImageTexture.create_from_image(img)
	return _cache[chave]


static func asfalto() -> Texture2D:
	if not _cache.has("asfalto"):
		var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
		var g: RandomNumberGenerator = Rng.new(17).stream("textura:asfalto")
		for y in 32:
			for x in 32:
				var tom := 0.8 + g.randf() * 0.25
				if g.randf() < 0.02:
					tom = 1.3  # pedrinha clara
				img.set_pixel(x, y, Color(tom, tom, tom).clamp())
		_cache["asfalto"] = ImageTexture.create_from_image(img)
	return _cache["asfalto"]


## Calçada portuguesa: ondas de pedra preta e branca (a da orla de Santos).
static func calcada_portuguesa() -> Texture2D:
	if not _cache.has("calcada"):
		var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
		for y in 64:
			for x in 64:
				var onda := sin((float(y) / 64.0 * TAU * 2.0) + sin(float(x) / 64.0 * TAU) * 1.6)
				var pedra := (x % 4 == 0) or (y % 4 == 0)
				var tom := 0.95 if onda > 0.0 else 0.28
				if pedra:
					tom *= 0.85
				img.set_pixel(x, y, Color(tom, tom, tom * 0.97))
		_cache["calcada"] = ImageTexture.create_from_image(img)
	return _cache["calcada"]
