extends RefCounted
## Sons sintetizados por código (docs/09, "Áudio"): amostras de baixa taxa, no estilo da época,
## sem arquivos de fora. Cada som é feito uma vez e guardado. O ruído usa um stream do
## core/rng.gd com semente fixa: o som é sempre o mesmo.
##   ambiente_dia: vento baixo e o zumbido distante da cidade (em laço)
##   ambiente_noite: vento mais frio e grilos (em laço)
##   passo, tiro_espingarda, tiro_revolver, sussurro, motor (em laço; o tom acompanha a velocidade)

const Rng := preload("res://core/rng.gd")

static var _cache: Dictionary = {}
static var taxa := 11025


## PCM 16 bits mono a partir de amostras de -1 a 1.
static func _wav(amostras: PackedFloat32Array, laco: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(amostras.size() * 2)
	for i in amostras.size():
		bytes.encode_s16(i * 2, int(clampf(amostras[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = taxa
	w.stereo = false
	w.data = bytes
	if laco:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = amostras.size()
	return w


## Ruído "marrom" (grave, como vento), com o gerador dado.
static func _marrom(n: int, g: RandomNumberGenerator, forca: float) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(n)
	var v := 0.0
	for i in n:
		v = clampf(v + (g.randf() * 2.0 - 1.0) * forca, -1.0, 1.0) * 0.998
		a[i] = v
	return a


static func ambiente_dia() -> AudioStreamWAV:
	if not _cache.has("dia"):
		var n := taxa * 4
		var g: RandomNumberGenerator = Rng.new(7).stream("som:dia")
		var a := _marrom(n, g, 0.03)
		for i in n:
			var t := float(i) / taxa
			a[i] = a[i] * 0.5 + sin(TAU * 58.0 * t) * 0.05 + sin(TAU * 117.0 * t) * 0.02
		_suavizar_laco(a)
		_cache["dia"] = _wav(a, true)
	return _cache["dia"]


static func ambiente_noite() -> AudioStreamWAV:
	if not _cache.has("noite"):
		var n := taxa * 4
		var g: RandomNumberGenerator = Rng.new(7).stream("som:noite")
		var a := _marrom(n, g, 0.02)
		for i in n:
			var t := float(i) / taxa
			# Grilos: trinados curtos de 3,5 kHz, em grupos.
			var trinado := 1.0 if fmod(t, 0.9) < 0.18 and fmod(t * 30.0, 1.0) < 0.5 else 0.0
			a[i] = a[i] * 0.45 + sin(TAU * 3500.0 * t) * 0.06 * trinado
		_suavizar_laco(a)
		_cache["noite"] = _wav(a, true)
	return _cache["noite"]


static func passo() -> AudioStreamWAV:
	if not _cache.has("passo"):
		var n := int(taxa * 0.09)
		var g: RandomNumberGenerator = Rng.new(7).stream("som:passo")
		var a := PackedFloat32Array()
		a.resize(n)
		var v := 0.0
		for i in n:
			var env := exp(-float(i) / (taxa * 0.018))
			v = v * 0.6 + (g.randf() * 2.0 - 1.0) * 0.4  # passa-baixa: batida surda
			a[i] = v * env * 0.9
		_cache["passo"] = _wav(a, false)
	return _cache["passo"]


static func _tiro(chave: String, duracao: float, grave: float, decaimento: float) -> AudioStreamWAV:
	if not _cache.has(chave):
		var n := int(taxa * duracao)
		var g: RandomNumberGenerator = Rng.new(7).stream("som:" + chave)
		var a := PackedFloat32Array()
		a.resize(n)
		var v := 0.0
		for i in n:
			var t := float(i) / taxa
			var env := exp(-t / decaimento)
			v = v * grave + (g.randf() * 2.0 - 1.0) * (1.0 - grave)
			a[i] = (v * 1.6 + sin(TAU * 70.0 * t) * 0.6 * exp(-t / 0.06)) * env
		_cache[chave] = _wav(a, false)
	return _cache[chave]


static func tiro_espingarda() -> AudioStreamWAV:
	return _tiro("espingarda", 0.7, 0.55, 0.16)


static func tiro_revolver() -> AudioStreamWAV:
	return _tiro("revolver", 0.4, 0.3, 0.07)


static func sussurro() -> AudioStreamWAV:
	if not _cache.has("sussurro"):
		var n := int(taxa * 1.4)
		var g: RandomNumberGenerator = Rng.new(7).stream("som:sussurro")
		var a := PackedFloat32Array()
		a.resize(n)
		var v := 0.0
		for i in n:
			var t := float(i) / taxa
			v = v * 0.2 + (g.randf() * 2.0 - 1.0) * 0.8  # chiado agudo, como "sss"
			var silabas := maxf(0.0, sin(TAU * 3.2 * t)) * sin(PI * t / 1.4)
			a[i] = v * silabas * 0.5
		_cache["sussurro"] = _wav(a, false)
	return _cache["sussurro"]


static func motor() -> AudioStreamWAV:
	if not _cache.has("motor"):
		var n := taxa
		var a := PackedFloat32Array()
		a.resize(n)
		for i in n:
			var t := float(i) / taxa
			# Dente de serra grave a 55 Hz (o laço fecha em ciclos inteiros: 1 s = 55 ciclos).
			var serra := fmod(t * 55.0, 1.0) * 2.0 - 1.0
			a[i] = serra * 0.35 + sin(TAU * 110.0 * t) * 0.15
		_cache["motor"] = _wav(a, true)
	return _cache["motor"]


## Encaixa o fim no começo do laço (sem estalo): 0,1 s de cruzamento.
static func _suavizar_laco(a: PackedFloat32Array) -> void:
	var m := int(taxa * 0.1)
	var n := a.size()
	for i in m:
		var k := float(i) / m
		a[n - m + i] = lerpf(a[n - m + i], a[i], k)
