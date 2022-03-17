shader_type canvas_item;

render_mode blend_mix;

uniform vec4 flash_color : hint_color;
uniform float flash_amount : hint_range(0.0, 1.0);

uniform vec4 outline_color : hint_color = vec4(1.0);
uniform float outline_width : hint_range(0, 10) = 1.0;
uniform int outline_pattern : hint_range(0, 2) = 0; // diamond, circle, square
uniform bool outline_inside = false;
uniform bool outline_add_margins = true; // only useful when outline_inside is false

void vertex() {
	if (outline_add_margins) {
		VERTEX += (UV * 2.0 - 1.0) * outline_width;
	}
}

bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
	for (float i = -ceil(outline_width); i <= ceil(outline_width); i++) {
		float x = abs(i) > outline_width ? outline_width * sign(i) : i;
		float offset;
		if (outline_pattern == 0) {
			offset = outline_width - abs(x);
		} else if (outline_pattern == 1) {
			offset = floor(sqrt(pow(outline_width + 0.5, 2) - x * x));
		} else if (outline_pattern == 2) {
			offset = outline_width;
		}
		for (float j = -ceil(offset); j <= ceil(offset); j++) {
			float y = abs(j) > offset ? offset * sign(j) : j;
			vec2 xy = uv + texture_pixel_size * vec2(x, y);
			if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(texture, xy).a == 0.0) == outline_inside) {
				return true;
			}
		}
	}
	return false;
}

void fragment() {
//	vec4 color = texture(TEXTURE, UV);
//	color.rgb = mix(color.rgb, flash_color.rgb, flash_amount);
//	COLOR = color;
	
	vec2 uv = UV;
	
	if (outline_add_margins) {
		vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(outline_width * 2.0));
		
		uv = (uv - texture_pixel_size * outline_width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
		
		if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
			COLOR.a = 0.0;
		} else {
			COLOR = texture(TEXTURE, uv);
		}
	} else {
		COLOR = texture(TEXTURE, uv);
	}
	
	if ((COLOR.a > 0.0) == outline_inside && hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
		COLOR.rgb = outline_inside ? mix(COLOR.rgb, outline_color.rgb, outline_color.a) : outline_color.rgb;
		COLOR.a += (1.0 - COLOR.a) * outline_color.a;
	}
	
	vec4 color = vec4(COLOR );
	color.rgb = mix(color.rgb, flash_color.rgb, flash_amount);
	COLOR = color;
	
}