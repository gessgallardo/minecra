// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.

// To use centroid sampling we need to have version 300 es shaders, which requires changing:
// attribute to in
// varying to out when in vertex shaders or in when in fragment shaders
// defining an out vec4 FragColor and replacing uses of gl_FragColor with FragColor
// texture2D to texture
#if __VERSION__ >= 300

// version 300 code

#define varying in
#define texture2D texture
out vec4 FragColor;
#define gl_FragColor FragColor

#else

// version 100 code

#endif

varying vec4 color;

uniform vec4 CURRENT_COLOR;

void main()
{
	gl_FragColor = vec4(color.rgb * CURRENT_COLOR.rgb * color.a, color.a)*60.0;
}