shader_type canvas_item;

render_mode blend_add;
uniform vec4 topleft : source_color;
uniform vec4 topright : source_color;
uniform vec4 bottomleft : source_color;
uniform vec4 bottomright : source_color;
uniform vec4 color : source_color;
uniform bool flipx;
uniform bool flipy;
// Define the range for the shader
uniform vec2 range_min;
uniform vec2 range_max;

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    // Compute the gradient coordinates based on the range_min and range_max, and the flipx and flipy variables
    vec2 gradient_uv = (UV - range_min) / (range_max - range_min);
    if (flipx) {
        gradient_uv.x = 1.0 - gradient_uv.x;
    }
    if (flipy) {
        gradient_uv.y = 1.0 - gradient_uv.y;
    }

    vec4 top = mix(topleft, topright, gradient_uv.x);
    vec4 bottom = mix(bottomleft, bottomright, gradient_uv.x);
    vec4 gradient = mix(top, bottom, gradient_uv.y);
    vec4 mixed = gradient * color;

    // Calculate the luminance of the pixel and use it as the alpha value
    float luminance = dot(texture_color.rgb, vec3(0.299, 0.587, 0.114));
    mixed.a *= luminance;  // Use luminance as alpha
		

    // Set the final color with the modified alpha value
    vec4 final_color = vec4(texture_color.rgb, texture_color.a);
    COLOR = final_color * mixed;
}
