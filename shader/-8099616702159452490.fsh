#version 330 core

out vec4 color;

in vec2 v_TexCoord;
in vec2 v_OneTexel;

uniform sampler2D u_Texture;
uniform bool u_Image;
uniform sampler2D u_Overlay;
uniform float u_OverlayAlpha;
uniform vec4 u_Fill;
uniform float u_Fill_Offset;
uniform float u_Fill_Strength;
uniform vec4 u_Outline;
uniform float u_Outline_Offset;
uniform float u_Outline_Strength;
uniform int u_Radius;
uniform float u_GlowMultiplier;
uniform bool u_FastLines;
uniform int u_Dots;
uniform int u_DotsRadius;
uniform float u_DotsAlpha;

bool decorator() {
    if (u_Dots == 0) return false;
    if (u_Fill.a == 0) return false;
    if (u_Dots == 1)
    return int(gl_FragCoord.x) - (u_DotsRadius * int(gl_FragCoord.x / u_DotsRadius)) == 0
        && int(gl_FragCoord.y) - (u_DotsRadius * int(gl_FragCoord.y / u_DotsRadius)) == 0;
    return int(gl_FragCoord.x) % u_DotsRadius == 0 || int(gl_FragCoord.y) % u_DotsRadius == 0;
}

vec3 calculate(vec3 c, float hue){
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    vec4 L = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 f = vec3(hue, d / (q.x + e), q.x);
    vec3 r = abs(fract(f.xxx + L.xyz) * 6.0 - L.www);
    return f.z * mix(L.xxx, clamp(r - L.xxx, 0.0, 1.0), f.y);
}

void main() {
    vec4 s = texture(u_Texture, v_TexCoord);
    vec4 overlay = texture(u_Overlay, v_TexCoord * vec2(1.0, -1.0));

    if (s.a == 1.0) {
        if (u_Fill.a == 0.0 || overlay.a == 0.0) discard;
        vec4 fillColor = u_Fill;
        if (u_Fill_Offset != 0.0) {
            vec2 strength = (v_TexCoord * 3.0 * vec2(-u_Fill_Strength, u_Fill_Strength));
            float hue = float(mod (((strength.x + strength.y) + u_Fill_Offset), 1.0));
            fillColor = vec4(calculate(u_Fill.rgb, hue), u_Fill.w);
        }
        color = fillColor;

        if (decorator()) {
            color = vec4(fillColor.rgb, u_DotsAlpha);
        } else if (u_Image) {
            color.rgb = mix(overlay.rgb, fillColor.rgb, fillColor.a);
            color.a = u_OverlayAlpha;
        } else {
            color = fillColor;
        }
    } else if (u_Radius > 0) {
        float dist = u_Radius * u_Radius + 1.0;

        if (u_FastLines && u_Radius > 2) {
            bool present = false;

            for (int x = -u_Radius; x <= u_Radius; x += u_Radius) {
                for (int y = -u_Radius; y <= u_Radius; y += u_Radius) {
                    vec4 offset = texture(u_Texture, v_TexCoord + v_OneTexel * vec2(x, y));
                    if (offset.a != 0.0) {
                        present = true;
                        break;
                    }
                }
            }

            if (!present) discard;
        }

        for (int x = -u_Radius; x <= u_Radius; x++) {
            for (int y = -u_Radius; y <= u_Radius; y++) {
                vec4 offset = texture(u_Texture, v_TexCoord + v_OneTexel * vec2(x, y));

                if (offset.a == 1.0) {
                    dist = min(x * x + y * y - 1.0, dist);
                }
            }
        }

        float limit = u_Radius * u_Radius;

        if (dist <= limit) {
            vec4 outlineColor = u_Outline;
            if (u_Outline_Offset != 0.0) {
                vec2 strength = (v_TexCoord * 3.0 * vec2(-u_Outline_Strength, u_Outline_Strength));
                float hue = float(mod (((strength.x + strength.y) + u_Outline_Offset), 1.0));
                outlineColor = vec4(calculate(u_Outline.rgb, hue), u_Outline.w);
            }

            color.rgb = outlineColor.rgb;
            color.a = min((1.0 - (dist / limit)) * u_GlowMultiplier, 1.0);
            if (dist <= 1.5 && u_GlowMultiplier > 0)
                color.a = 0.8;
        } else {
            discard;
        }
    }
}
