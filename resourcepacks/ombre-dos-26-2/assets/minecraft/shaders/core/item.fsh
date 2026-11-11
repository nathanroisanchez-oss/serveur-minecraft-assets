#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec4 vertexColor;
in vec4 lightMapColor;
in vec4 overlayColor;
in vec2 texCoord0;

out vec4 fragColor;

// ANTHROPIA (11/11/2026) : les objets de DOS (sac a dos, ailes) sont masques DANS LA VUE DE LEUR PORTEUR a la premiere personne : leur orientation vient du serveur et retarde sur
// la camera, ils passaient devant les yeux quand on tournait vite. Marqueurs : teintes 255/252/249 (sac) et 255/249/243 (ailes) posees par les modeles « _porte » (contexte
// d'affichage « none » seulement) ; leurs rapports vert/rouge et bleu/rouge survivent a l'eclairage. A moins de 1,15 bloc (sac) ou 1,6 bloc (ailes) de la camera = on est le porteur.
bool anthropiaDosDeMaVue(vec4 c, float dist) {
    if (c.r < 0.2) return false;
    float g = c.g / c.r;
    float b = c.b / c.r;
    if (abs(g - 0.98824) < 0.0025 && abs(b - 0.97647) < 0.0025) return dist < 1.15;
    if (abs(g - 0.97647) < 0.0025 && abs(b - 0.95294) < 0.0025) return dist < 1.6;
    return false;
}

void main() {
    vec4 color = texture(Sampler0, texCoord0);
#ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
#endif

    if (anthropiaDosDeMaVue(vertexColor, sphericalVertexDistance)) {
        discard;
    }

    color *= vertexColor * ColorModulator;
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color *= lightMapColor;

    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}
