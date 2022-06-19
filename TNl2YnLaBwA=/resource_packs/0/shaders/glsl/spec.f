// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.

// __Please ask for permission, if you want to use some code from this shader__

// __Discord: The Alexander # 3744__

#include "fragmentVersionCentroid.h"

#if __VERSION__ >= 300
	#ifndef BYPASS_PIXEL_SHADER
		#if defined(TEXEL_AA) && defined(TEXEL_AA_FEATURE)
			_centroid in highp vec2 uv0;
			_centroid in highp vec2 uv1;
		#else
			_centroid in vec2 uv0;
			_centroid in vec2 uv1;
		#endif
	#endif
#else
	#ifndef BYPASS_PIXEL_SHADER
		varying vec2 uv0;
		varying vec2 uv1;
	#endif
#endif


varying vec4 color;
varying highp vec3 wpos;
varying highp vec3 position;
varying highp vec3 p;
uniform highp float TIME;
varying highp vec3 wp;



#ifdef FOG
varying vec4 fogColor;
#endif


#include "uniformShaderConstants.h"
#include "util.h"


uniform float RENDER_DISTANCE;
uniform vec2 FOG_CONTROL;
uniform vec4 FOG_COLOR;





LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;
LAYOUT_BINDING(1) uniform sampler2D TEXTURE_1;
LAYOUT_BINDING(2) uniform sampler2D TEXTURE_2;

#include "set/noise.h"
#define enableMaps

float filmc(float x) {
float A = 0.42;
float B = 0.5;
float C = 0.15;
float D = 0.55;
float E = 0.0;
float F = 0.35;

return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

vec3 Hyra(vec3 clr) {
float W = 1.3 / 1.0;
#ifdef enableMaps
float Luma = dot(clr, vec3(0.0, 0.6, 0.4));
vec3 Chroma = clr - Luma;
clr = (Chroma * 1.5) + Luma;
clr = vec3(filmc(clr.r), filmc(clr.g), filmc(clr.b)) / filmc(W);
#endif
return clr;
}

void main()
{
#ifdef BYPASS_PIXEL_SHADER
	gl_FragColor = vec4(0, 0, 0, 0);
	return;
#else 



#if USE_TEXEL_AA
	vec4 diffuse = texture2D_AA(TEXTURE_0, uv0);
#else
	vec4 diffuse = texture2D(TEXTURE_0, uv0);
#endif
	
#ifdef SEASONS_FAR
	diffuse.a = 1.0;
#endif

#if USE_ALPHA_TEST
	#ifdef ALPHA_TO_COVERAGE
	#define ALPHA_THRESHOLD 0.05
	#else
	#define ALPHA_THRESHOLD 0.5
	#endif
	if(diffuse.a < ALPHA_THRESHOLD)
		discard;
#endif
	
vec4 inColor = color;

float uY = uv1.y;
   vec3 shadowColor = vec3(0.94);
   vec3 Torch = vec3(1.3,0.4,0.0);

#if defined(BLEND)
	diffuse.a *= inColor.a;
#endif

vec4 diff2 = texture2D( TEXTURE_1, uv1 );
vec3 night = vec3(0.4,0.4,0.4);

diff2.rgb *= pow(diff2.rgb, 1.0 - night);

#if !defined(ALWAYS_LIT)
	diffuse *= diff2;
#endif

#ifndef SEASONS
	#if !USE_ALPHA_TEST && !defined(BLEND)
		diffuse.a = inColor.a;
	#endif
	
	diffuse.rgb *= inColor.rgb;
#else
	vec2 uv = inColor.xy;
	diffuse.rgb *= mix(vec3(1.0,1.0,1.0), texture2D( TEXTURE_2, uv).rgb*2.0, inColor.b);
	diffuse.rgb *= inColor.aaa;
	diffuse.a = 1.0;
#endif

//Dectetors

float cave = 1.0-uv1.y;

highp float rain_detect = 1.0-pow(FOG_CONTROL.y, 11.0);

bool Water = (color.r * 1.1 < color.b) && (color.b > color.g * 1.05) 
&& (color.g > color.r) && (color.a > 0.0);
  
bool Underwater =
FOG_CONTROL.x == 0.0 && FOG_COLOR.b > FOG_COLOR.r;

//Shadow

if(color.a != 0.0){
if(color.g<0.64 || uv1.y<0.874){diffuse.rgb *= vec3(0.98)+uv1.x*vec3(0.02);}
if(color.g<0.63 || uv1.y<0.873){diffuse.rgb *= vec3(0.94)+uv1.x*vec3(0.06);}
if(color.g<0.62 || uv1.y<0.872){diffuse.rgb *= vec3(0.88)+uv1.x*vec3(0.12);}
if(color.g<0.61 || uv1.y<0.871){diffuse.rgb *= vec3(0.8)+uv1.x*vec3(0.2);}
}	

if(color.a==0.0){
diffuse.rgb *= 1.55;
diffuse.rgb *= color.g*1.3;
}

float c = color.r;
if(color.a<=0.1){ c = color.g*1.999; }
if(c<0.638){ diffuse.rgb *= 0.9; }

//Torch 

diffuse.rgb += diffuse.rgb*Torch*uv1.x*0.95;

//Water  

if(Water==true){
highp float wave = sin(noise(vec2(TIME*1.5+p.x+p.z+p.x+p.z*3.0,TIME*1.2+p.z+p.x+p.z*1.0+p.x*2.0)))+sin(noise(vec2(TIME*1.5+p.x+p.z+p.x+p.z*3.0,TIME*1.2+p.z+p.x+p.z*1.0+p.x*2.0)));

diffuse.rgb +=wave*0.098833;
diffuse.rgb +=noise(wpos*0.5*abs(wave))
*0.42;
diffuse.rgb *=mix(vec3(0.8),vec3(0.7),abs(wave));
}

//Caustic 

if(Underwater==true){
highp float wave = sin(noise(vec2(TIME*0.7+p.x+p.x*1.2,TIME*1.2+p.z+p.z*1.4+p.x*2.0)))
+sin(noise(vec2(TIME*1.7+p.z+p.z*1.2,TIME*1.2+p.x+p.x*1.4+p.z*2.0)));
diffuse.rgb += diffuse.rgb*(vec3(1.0,1.0,1.0)*0.55)*pow(uv1.x*1.6,1.0);
diffuse.rgb *= mix(vec3(0.1,0.2,0.5)*1.5, vec3(0.1,0.5,1.0)*1.9, wave*uv1.y);
}

#ifdef BLEND
highp vec4 specular_albedo = vec4(0.8, 0.8, 0.8, 2.0);
highp float specular_power = 130.0;
highp vec3 light_pos = vec3(1000., 600., 0.);
highp vec3 P = wpos;
highp vec3 N = normalize(wpos);
highp vec3 V = normalize(-wpos);
highp vec3 L = normalize(light_pos - P);
highp vec3 R = reflect(-L, N);
highp vec4 specular =
        pow( max(0.0, dot(R, V)),
            specular_power ) *
        specular_albedo;
diffuse += specular;
diffuse -= specular*rain_detect;
diffuse -= specular*cave;

if((uv1.y <= 0.890)){
	diffuse -= specular*0.5;}

if((uv1.y <= 0.890)){
diffuse += specular*0.5*rain_detect;}

if((uv1.y <= 0.890)){
	diffuse -= specular*0.5;}

if((uv1.y <= 0.890)){
diffuse += specular*0.5*cave ;}

#endif

//Fog

vec3 fog = mix(diffuse.rgb, FOG_COLOR.rgb*vec3(0.65,0.65,0.85), clamp(length(-wpos)/RENDER_DISTANCE*1.0,0.0,0.6));

diffuse.rgb = fog;

//The end

bool end = (FOG_COLOR.r > FOG_COLOR.g && FOG_COLOR.b > FOG_COLOR.g && FOG_COLOR.r < 0.05 && FOG_COLOR.b < 0.05 && FOG_COLOR.g < 0.05);

if(end==true){
	diffuse.rgb += vec3(0.18,0.0,0.75)*pow(uv1.x*1.5,2.0);

vec3 fog_end = mix(diffuse.rgb, FOG_COLOR.rgb,clamp(length(-wpos)/RENDER_DISTANCE*1.0,0.7,0.6));
 
diffuse.rgb = fog_end;
	
}

diffuse.rgb = Hyra(diffuse.rgb)*vec3(1.22);

#ifdef FOG
	diffuse.rgb = mix( diffuse.rgb, fogColor.rgb, fogColor.a );
#endif

	gl_FragColor = diffuse;
	
#endif // BYPASS_PIXEL_SHADER
}