// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.

#include "fragmentVersionCentroid.h"

#if __VERSION__ >= 300

#if defined(TEXEL_AA) && defined(TEXEL_AA_FEATURE)
_centroid in highp vec2 uv;
#else
_centroid in vec2 uv;
#endif

#else

varying vec2 uv;

#endif

#include "uniformShaderConstants.h"
#include "util.h"

varying vec2 pos;

LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;

void main()
{
#if !defined(TEXEL_AA) || !defined(TEXEL_AA_FEATURE)
	vec4 diffuse = texture2D( TEXTURE_0, uv);
#else
	vec4 diffuse = texture2D_AA(TEXTURE_0, uv );
#endif

	gl_FragColor = CURRENT_COLOR * diffuse;
}
