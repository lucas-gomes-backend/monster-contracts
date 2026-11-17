// Filtro de tela PS1 (docs/09, "Estética"): poucas cores por canal com pontilhado (dithering)
// Bayer 4x4, como a saída de 15 bits do console. Vai num ColorRect que cobre a tela.
shader_type canvas_item;

uniform sampler2D tela : hint_screen_texture, filter_nearest;
// Níveis por canal: 32 = 15 bits de cor (5 por canal).
uniform float niveis = 32.0;
uniform float forca_pontilhado : hint_range(0.0, 2.0) = 1.0;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

void fragment() {
	vec3 c = texture(tela, SCREEN_UV).rgb;
	ivec2 p = ivec2(FRAGCOORD.xy) % 4;
	float limiar = BAYER[p.y * 4 + p.x] / 16.0 - 0.5;
	c += limiar * forca_pontilhado / niveis;
	c = floor(clamp(c, 0.0, 1.0) * (niveis - 1.0) + 0.5) / (niveis - 1.0);
	COLOR = vec4(c, 1.0);
}
