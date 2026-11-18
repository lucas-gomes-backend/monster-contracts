// Fachada PS1 (docs/09): o mesmo tremor e textura afim do ps1.gdshader, mais as janelas
// acesas à noite (uma máscara de emissão que liga com "noite").
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 cor : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform sampler2D textura : source_color, filter_nearest, repeat_enable, hint_default_white;
uniform sampler2D janelas : source_color, filter_nearest, repeat_enable, hint_default_black;
uniform vec4 cor_janela : source_color = vec4(1.0, 0.8, 0.45, 1.0);
uniform float noite : hint_range(0.0, 1.0) = 0.0;
uniform float brilho = 1.5;
uniform vec2 grade = vec2(320.0, 240.0);
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
	uv_afim = vec3(UV * w, w);
}

void fragment() {
	vec2 uv = uv_afim.xy / uv_afim.z;
	ALBEDO = texture(textura, uv).rgb * cor.rgb;
	EMISSION = texture(janelas, uv).r * cor_janela.rgb * noite * brilho;
}
