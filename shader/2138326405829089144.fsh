#version 330 core

in vec2 v_TexCoord;
in vec2 v_OneTexel;

uniform sampler2D u_Texture;
uniform bool u_Image;
uniform sampler2D u_Overlay;
uniform float u_OverlayAlpha;
uniform int u_Width;
uniform bool u_FastLines;
uniform int u_ShapeMode;
uniform float u_GlowMultiplier;
uniform int u_GlowQuality;
uniform vec4 u_FillColor;
uniform vec4 u_OutlineColor;
uniform int u_Dots;
uniform int u_DotsRadius;
uniform float u_DotsAlpha;

out vec4 color;

bool decorator() {
    if (u_Dots == 0) return false;
    if (u_FillColor.a == 0) return false;
    if (u_Dots == 1)
    return int(gl_FragCoord.x) - (u_DotsRadius * int(gl_FragCoord.x / u_DotsRadius)) == 0
        && int(gl_FragCoord.y) - (u_DotsRadius * int(gl_FragCoord.y / u_DotsRadius)) == 0;
    return int(gl_FragCoord.x) % u_DotsRadius == 0 || int(gl_FragCoord.y) % u_DotsRadius == 0;
}

float blur(vec4 center, bool outline) {
    if (u_Width == 0.0) return 0.0;

    int w = u_GlowQuality * u_Width;
    float blurred = 0.0;

    blurred += sign(texture(u_Texture, v_TexCoord + v_OneTexel * vec2(w, 0)).a);
    blurred += sign(texture(u_Texture, v_TexCoord + v_OneTexel * vec2(-w, 0)).a);
    blurred += sign(texture(u_Texture, v_TexCoord + v_OneTexel * vec2(0, w)).a);
    blurred += sign(texture(u_Texture, v_TexCoord + v_OneTexel * vec2(0, -w)).a);

    blurred += sign(texture(u_Texture, v_TexCoord + v_OneTexel * vec2(w, w)).a);
    blurred += sign(texture(u_Texture, v_TexCoord + v_OneTexel * vec2(w, -w)).a);
    blurred += sign(texture(u_Texture, v_TexCoord + v_OneTexel * vec2(-w, w)).a);
    blurred += sign(texture(u_Texture, v_TexCoord + v_OneTexel * vec2(-w, -w)).a);

    if (u_FastLines && u_Width > 2 && blurred == 0.0) {
        return 0.0;
    }

    for (int x = -w; x <= w; x += u_GlowQuality) {
        for (int y = -w; y <= w; y += u_GlowQuality) {
            if (x == 0 && y == 0) {
                continue;
            }
            if (sign(x) == w && sign(y) == w
                || sign(x) == w && y == 0
                || sign(y) == 0 && x == 0) {
                continue;
            }

            blurred += sign(texture(u_Texture, v_TexCoord + v_OneTexel * vec2(x, y)).a);
        }
    }

    return clamp(blurred / (((u_Width * u_Width) + u_Width) * 4), 0.0, 1.0) * u_GlowMultiplier;
}

void main() {
    vec4 center = texture(u_Texture, v_TexCoord);
    vec4 overlay = texture(u_Overlay, v_TexCoord * vec2(1.0, -1.0));

    if (center.a != 0.0) {
        if (u_ShapeMode == 0.0 || overlay.a == 0.0) discard;
        if (decorator()) {
            center = vec4(u_FillColor.rgb, u_DotsAlpha);
        } else if (u_Image) {
            center.rgb = mix(overlay.rgb, u_FillColor.rgb, u_FillColor.a);
            center.a = u_OverlayAlpha;
        } else {
            center = u_FillColor;
        }
        if (u_Width != 0) {
            center = mix(center, u_OutlineColor, u_GlowMultiplier - blur(center, false));
        }
    } else {
        if (u_ShapeMode == 1 || u_Width == 0.0) discard;

        float blurFactor = blur(center, true);

        if (blurFactor == 0.0) discard;

        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                if (x == 0 && y == 0)
                    continue;

                if (texture(u_Texture, v_TexCoord + v_OneTexel * vec2(x, y)).a > 0.0) {
                    center = u_OutlineColor;
                    center.a = 1.0;
                }
            }
        }

        if (center.a == 0.0) {
            center = u_OutlineColor;
            center.a = blurFactor;
        }
    }

    color = center;
}
