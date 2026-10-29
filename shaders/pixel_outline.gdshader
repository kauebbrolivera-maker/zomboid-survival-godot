shader_type canvas_item;
// Contorno nítido de 1 pixel (na resolução do SubViewport) em volta do modelo 3D.
// Lê o alfa dos 4 vizinhos: pixel transparente encostado no boneco vira contorno.
// Também "endurece" o alfa (0 ou 1) para não sobrar borda borrada.

uniform vec4 outline_color : source_color = vec4(0.07, 0.06, 0.06, 1.0);
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE;
	if (c.a >= alpha_cut) {
		COLOR = vec4(c.rgb, 1.0);
	} else {
		float n = max(max(texture(TEXTURE, UV + vec2(px.x, 0.0)).a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a),
				max(texture(TEXTURE, UV + vec2(0.0, px.y)).a, texture(TEXTURE, UV - vec2(0.0, px.y)).a));
		COLOR = n >= alpha_cut ? outline_color : vec4(0.0);
	}
}
