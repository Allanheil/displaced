shader_type canvas_item;

uniform float outline_width = 2.0;
uniform vec4 outline_color : hint_color;
uniform float opacity = 1.0;
uniform float highlight = 0.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 ps = TEXTURE_PIXEL_SIZE;
	float a;
	float maxa = col.a;
	float mina = col.a;

	a = texture(TEXTURE, UV + vec2(0.0, -outline_width) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);

	a = texture(TEXTURE, UV + vec2(0.0, outline_width) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);

	a = texture(TEXTURE, UV + vec2(-outline_width, 0.0) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);

	a = texture(TEXTURE, UV + vec2(outline_width, 0.0) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);
	
	a = texture(TEXTURE, UV + vec2(outline_width, -outline_width) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);

	a = texture(TEXTURE, UV + vec2(outline_width, outline_width) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);
	
	a = texture(TEXTURE, UV + vec2(-outline_width, outline_width) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);
	
	a = texture(TEXTURE, UV + vec2(-outline_width, -outline_width) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);
	
	col.rgb = mix(col.rgb, vec3(1.0), highlight);
	COLOR = mix(col, outline_color, (maxa - mina)*opacity);
}