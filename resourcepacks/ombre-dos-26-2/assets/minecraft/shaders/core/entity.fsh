#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

#ifdef DISSOLVE
uniform sampler2D DissolveMaskSampler;
#endif

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
#ifdef PER_FACE_LIGHTING
in vec4 vertexPerFaceColorBack;
in vec4 vertexPerFaceColorFront;
#else
in vec4 vertexColor;
#endif

#ifndef EMISSIVE
in vec4 lightMapColor;
#endif

#ifndef NO_OVERLAY
in vec4 overlayColor;
#endif

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

#ifdef PER_FACE_LIGHTING
    vec4 faceVertexColor = gl_FrontFacing ? vertexPerFaceColorFront : vertexPerFaceColorBack;
#else
    vec4 faceVertexColor = vertexColor;
#endif

    if (anthropiaDosDeMaVue(faceVertexColor, sphericalVertexDistance)) {
        discard;
    }

#ifdef DISSOLVE
    if (faceVertexColor.a < texture(DissolveMaskSampler, texCoord0).a) {
        discard;
    }
    // The dissolve effect entirely replaces translucency
    faceVertexColor.a = 1.0;
#endif

    color *= faceVertexColor * ColorModulator;
#ifndef NO_OVERLAY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
#endif
#ifndef EMISSIVE
    color *= lightMapColor;
#endif

    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}
