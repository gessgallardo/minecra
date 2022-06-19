// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.

#include "vertexVersionCentroidUV.h"

#include "uniformWorldConstants.h"

attribute POS4 POSITION;
attribute vec2 TEXCOORD_0;
varying vec2 pos;


void main()
{
    vec2 pio = vec2(.5);
    vec4 pio_s = vec4(pio, pio);
    gl_Position = WORLDVIEWPROJ * (POSITION * pio_s);

    uv = TEXCOORD_0;
    pos = POSITION.xy;
}