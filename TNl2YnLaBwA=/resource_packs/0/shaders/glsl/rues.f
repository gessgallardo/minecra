// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.

///////////////////////////////////////
/////////// STOP! ///////////
// Sky code: R.D.B.T Official
//Please, if you want to use the sky code, ask him
//to @RDBTOfficial1, it costs nothing
// Att: @The_AlexanderG
////////////////////////////////////////
////////////////////////////////////////

#include "fragmentVersionSimple.h"
#include "uniformPerFrameConstants.h"

varying vec4 color;
varying highp vec3 pos;

highp float clouds_rand(highp vec2 p){ 
	return fract(cos(p.x + p.y * 31.0) * 625.855);
} 
highp float clouds_ns( highp vec2 p) { 
highp vec2 i = floor(p); 
highp vec2 f = fract(p); 
highp vec2 u = pow(f,vec2(1.5))*(2.-1.*f); 

highp float a = clouds_rand(i+vec2(0.,0.));
highp float b = clouds_rand(i+vec2(1.,0.));
highp float c = clouds_rand(i+vec2(0.,1.));
highp float d = clouds_rand(i+vec2(1.,1.));

highp float zenxy = mix(a, b, u.x);
highp float dangson = mix(c, d, u.x);
highp float respe = mix(zenxy, dangson, u.y);
	return respe;
}

highp float detailcloud(highp vec2 pos, int h){
highp float time = TIME*0.75;
pos.x+= sin(time*0.0000);
	highp float d = 1.22;
	highp float nz = 0.0;
	pos *= 0.12;
	pos += vec2(3.0, -9.0) *time* 0.000;
	for(int i = 0; i < h; i++){
		nz += clouds_ns(pos) / (d);
		d *= 1.55;
		pos *= 2.25;
		pos -= time * 0.02 * pow(d, 0.5);
	}
	return pow(abs(nz),2.);
}

vec4 atccore(vec2 p){
float a = detailcloud(p,9)*1.3;

vec4 ac = vec4(1.)-a;
vec4 bc = vec4(1.0);
vec4 start = vec4(0.);
start = mix(bc*a,ac,max(min(a,0.75),0.));
return start; }

vec4 letup(vec2 p, vec4 l, vec3 cw){
vec4 a = atccore(p);
vec4 c = vec4(cw,1.0);
vec4 e = (2.-a)*a;

vec4 start;
start = mix(l,vec4(c),0.9*max(0.,e.x)); 

return start; }

vec4 sky_day(float p, vec4 f, vec4 c){ 
vec4 cascolor = mix(vec4(0.01,0.2,0.55,1.0), vec4(0.6,0.8,0.8,1.0), pow(clamp(p*1.4,0.,1.),1.0));
cascolor = mix(cascolor, f, pow(clamp(p,0.,1.),1.));
return cascolor; }

vec4 sky_sun(float p, vec4 f, vec4 c){
vec4 cascolor = mix(vec4(0.2,0.45,0.9,1.0), vec4(0.8,1.6,1.2,1.0), pow(clamp(p*1.4,0.,1.),0.9));
cascolor = mix(cascolor, vec4(0.7,0.6,0.5,1.0), pow(clamp(p*1.3,0.,1.),0.8));
cascolor = mix(cascolor, f, pow(clamp(p,0.,1.),0.6));
return cascolor; }

vec4 sky_night(float p, vec4 f, vec4 c){
vec4 cascolor = mix(vec4(0.02,0.,0.05,1.)+c*0.7, f, pow(clamp(p*1.5,0.,1.),1.));
cascolor = mix(cascolor, f, pow(clamp(p*1.3,0.,1.),1.));
cascolor = mix(cascolor , f, pow(clamp(p,0.,1.),1.));
return cascolor; }

vec4 sky_rain(float p, vec4 f, vec4 c){
vec4 cascolor = mix(c, f, pow(clamp(p*1.4,0.,1.),1.));
cascolor = mix(cascolor, f, pow(clamp(p*1.2,0.,1.),1.));
return cascolor; }

void main()
{
vec4 sfc = FOG_COLOR;
vec4 ruesNaCl = color;
float lp = length(pos);
float ruesHCL =pow(max(min(1.0-sfc.b*1.2,1.0),0.0),0.5);
float lolita =pow(max(min(1.0-sfc.r*1.5,1.0),0.0),0.3);
float respeshader = (1.0-pow(FOG_CONTROL.y,5.0));;

vec4 rues_csky = mix(sky_day(lp,sfc,ruesNaCl), sky_sun(lp,sfc,ruesNaCl), ruesHCL);
rues_csky = mix(rues_csky, sky_night(lp,sfc,ruesNaCl), lolita);
rues_csky = mix(rues_csky, sky_rain(lp,sfc,ruesNaCl),respeshader);

vec3 vi_vn = vec3( max(0.,FOG_COLOR.b-0.31)/0.79 );

gl_FragColor = rues_csky;

vec4 rcas = letup(pos.xz*120., rues_csky, vec3(1.2,1.2,1.2)*vi_vn*0.45+vec3(0.1)*lolita+FOG_COLOR.rgb*0.5 );

	gl_FragColor = rcas;
}