// Material PS1 para objetos (docs/09, "Estética").
// - Vértices presos a uma grade de tela baixa: os polígonos "tremem" quando a câmera anda.
// - Textura sem correção de perspectiva (mapeamento afim): ela entorta perto da câmera.
// - Textura sem suavização (filter_nearest).
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 cor : source_color = vec4(0.55, 0.55, 0.55, 1.0);
uniform sampler2D textura : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform float escala_uv = 1.0;
// Resolução da grade em que os vértices são presos (menor = treme mais).
uniform vec2 grade = vec2(320.0, 240.0);
// 0 = textura correta; 1 = afim como no PS1.
uniform float afim : hint_range(0.0, 1.0) = 1.0;

varying vec3 uv_afim;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	if (clip.w > 0.0) {
		vec2 meia = grade * 0.5;
		vec2 ndc = clip.xy / clip.w;
		ndc = floor(ndc * meia + 0.5) / meia;
		clip.xy = ndc * clip.w;
	}
	POSITION = clip;
	float w = mix(1.0, clip.w, afim);
	uv_afim = vec3(UV * escala_uv * w, w);
}

void fragment() {
	vec2 uv = uv_afim.xy / uv_afim.z;
	ALBEDO = texture(textura, uv).rgb * cor.rgb;
}
