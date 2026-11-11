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

// ANTHROPIA (11/11/2026) : le sac a dos du joueur (ItemDisplay) est masque DANS SA VUE a la premiere personne.
// Marqueur : teinte 255/252/249 (modele « _porte »), dont les rapports vert/rouge et bleu/rouge survivent a l'eclairage ; a moins de 1.15 bloc de la camera = on est le porteur.
bool anthropiaSacDeMaVue(vec4 c, float dist) {
    return dist < 1.15 && c.r > 0.2 && abs(c.g / c.r - 0.98824) < 0.0025 && abs(c.b / c.r - 0.97647) < 0.0025;
}

void main() {
    vec4 color = texture(Sampler0, texCoord0);
#ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
#endif

    if (anthropiaSacDeMaVue(vertexColor, sphericalVertexDistance)) {
        discard;
    }

    color *= vertexColor * ColorModulator;
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color *= lightMapColor;

    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}
