#include "ShaderConstants.fxh"
#include "util.fxh"
#include "snoise.fxh"
#define USE_NORMAL

struct PS_Input{
	float4 position : SV_Position;
	float3 cPos : chunkedPos;
	float3 wPos : worldPos;
	float block : BlockFlag;

#ifndef BYPASS_PIXEL_SHADER
	lpfloat4 color : COLOR;
	snorm float2 uv0 : TEXCOORD_0_FB_MSAA;
	snorm float2 uv1 : TEXCOORD_1_FB_MSAA;
#endif

#ifdef FOG
	float4 fogColor : FOG_COLOR;
#endif
};

struct PS_Output{float4 color : SV_Target;};

float aces(float x){
	//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
	return saturate((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14));
}
float3 aces3(float3 x){return float3(aces(x.x),aces(x.y),aces(x.z));}
float3 tone(float3 col,float4 gs){
	float lum = dot(col,float3(.299,.587,.114));//http://poynton.ca/notes/colour_and_gamma/ColorFAQ.html#RTFToC11
	col = aces3((col-lum)*gs.a+lum)*1.2;// /aces(1.1);
	return pow(col,1./gs.rgb);
}
float satur(float3 col){//https://qiita.com/akebi_mh/items/3377666c26071a4284ee
	float v=max(max(col.r,col.g),col.b);
	return v>0.?(v-min(min(col.r,col.g),col.b))/v:0.;
}
float pow5(float x){return x*x*x*x*x;}

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput){
#ifdef BYPASS_PIXEL_SHADER
	PSOutput.color = float4(0.0f, 0.0f, 0.0f, 0.0f);
	return;
#else

#if USE_TEXEL_AA
	float4 diffuse = texture2D_AA(TEXTURE_0, TextureSampler0, PSInput.uv0 );
#else
	float4 diffuse = TEXTURE_0.Sample(TextureSampler0, PSInput.uv0);
#endif

#ifdef SEASONS_FAR
	diffuse.a = 1.0f;
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

#if defined(BLEND)
	diffuse.a *= PSInput.color.a;
#endif

float2 sun = smoothstep(float2(.855,.4),float2(.875,1.),PSInput.uv1.yy);
float weather = smoothstep(.7,.96,FOG_CONTROL.y);
float br = TEXTURE_1.Sample(TextureSampler1,float2(.5,0.)).r;
float2 daylight = TEXTURE_1.Sample(TextureSampler1,float2(0.,1.)).rr;daylight=smoothstep(br-.2,br+.2,daylight);daylight.x*=weather;
float2 fuv1 = float2(PSInput.uv1.x-smoothstep(.2,1.,daylight.y)*(weather*.9+.1)*lerp(sun.y,sun.x,smoothstep(.8,1.,daylight.y)*.8),PSInput.uv1.y);
float4 tex1 = TEXTURE_1.Sample(TextureSampler1, fuv1);
#if !defined(ALWAYS_LIT)
	diffuse = diffuse * tex1;
#endif

#ifndef SEASONS
	#if !USE_ALPHA_TEST && !defined(BLEND)
		diffuse.a = PSInput.color.a;
	#endif

	diffuse.rgb *= PSInput.color.rgb;
#else
	float2 uv = PSInput.color.xy;
	diffuse.rgb *= lerp(1.0f, TEXTURE_2.Sample(TextureSampler2, uv).rgb*2.0f, PSInput.color.b);
	diffuse.rgb *= PSInput.color.aaa;
	diffuse.a = 1.0f;
#endif

//=*=*= ESBE_3G start =*=*=//

//datas
float time = TOTAL_REAL_WORLD_TIME;
float nv = step(TEXTURE_1.Sample(TextureSampler1,float2(0,0)).r,.5);
float dusk = min(smoothstep(.2,.4,daylight.y),smoothstep(1.,.8,daylight.y));
float uw = step(FOG_CONTROL.x,0.);
float nether = FOG_CONTROL.x/FOG_CONTROL.y;nether=step(.1,nether)-step(.12,nether);
float sat = satur(diffuse.rgb);
float4 ambient = lerp(//float4(gamma.rgb,saturation)
		float4(1.,.97,.9,1.15),//indoor
	lerp(
		float4(.67,.81,.85,.9),//rain
	lerp(lerp(
		float4(.9,.93,1.,1.),//night
		float4(1.15,1.17,1.1,1.2),//day
	daylight.y),
		float4(1.4,1.,.7,.8),//dusk
	dusk),weather),sun.y*nv);
	if(uw+nether>.5)ambient = float4(FOG_COLOR.rgb*.6+.4,.8);
#ifdef USE_NORMAL
	float3 N = normalize(cross(ddx(-PSInput.cPos),ddy(PSInput.cPos)));
	float dotN = dot(normalize(-PSInput.wPos),N);
#endif

//tonemap
diffuse.rgb = tone(diffuse.rgb,ambient);

//light_sorce
float lum = dot(diffuse.rgb,float3(.299,.587,.114));
diffuse.rgb += max(fuv1.x-.5,0.)*(1.-lum*lum)*lerp(1.,.3,daylight.x*sun.y)*float3(1.0,0.65,0.3);

//shadow
float ao = 1.;
if(PSInput.color.r==PSInput.color.g && PSInput.color.g==PSInput.color.b)ao = smoothstep(.48*daylight.y,.52*daylight.y,PSInput.color.g);
float Nl =
	#ifdef USE_NORMAL
		lerp(1.,smoothstep(-.7+dusk,1.,dot(normalize(float3(dusk*6.,4,3)),float3(abs(N.x),N.yz))),sun.y);
	#else
		1.;
	#endif
diffuse.rgb *= 1.-lerp(.5,0.,min(min(sun.x,ao),Nl))*(1.-max(0.,fuv1.x-sun.y*.7))*daylight.x;

//water
if(.5<PSInput.block && PSInput.block<1.5){
	float2 grid = mul((PSInput.cPos.xz+smoothstep(0.,8.,abs(PSInput.cPos.y-8.))*.5-time),float2x2(1,-.5,.5,.5));
	float2 wav = sin(grid.yx*float2(3.14,1.57)+time*4.)*.1; grid+=wav;
	float3 T = normalize(abs(PSInput.wPos));float omsin = 1.-T.y;
	float4 water = lerp(diffuse,float4(lerp(tex1.rgb,FOG_COLOR.rgb,sun.y),1),.02+.98*pow5(
			#ifdef USE_NORMAL
				1.-dotN
			#else
				omsin
			#endif
			));//fresnel
	float2 skp = (PSInput.wPos.xz*.4-(frac(grid*.625)-.5)*T.xz*omsin*omsin);
	#ifdef FANCY
		water = lerp(water,float4(lerp(tex1.rgb,FOG_COLOR.rgb,length(T.xz)*.7),1),smoothstep(-.5,1.,snoise(skp/abs(PSInput.wPos.y)-float2(time*.02,0)+wav*.07))*T.y*sun.y);//c_ref
	#endif
	water.rgb = lerp(water.rgb,tex1.rgb,saturate(snoise(normalize(skp)*3.+time*.02)*.5+.5)*omsin);//t_ref
	float3 Ts = normalize(float3(abs(skp.x),PSInput.wPos.y,skp.y));
	float sunT = lerp(-.1,.4,saturate(daylight.y*1.5-.5));
	water = lerp(water,float4(FOG_COLOR.rgb*.5+.8,.9),smoothstep(.97,1.,dot(float2(cos(sunT),-sin(sunT)),Ts.xy))*smoothstep(.5,1.,normalize(FOG_COLOR.rgb).r)*sun.y);//sun
	diffuse = lerp(diffuse,water,(length(T.xz)*.5+.5)*smoothstep(0.,1.,length(PSInput.wPos)));
#if !defined(ALPHA_TEST) && defined(USE_NORMAL)
}else if(uw<.5)diffuse.rgb=lerp(diffuse.rgb,ambient.rgb,(1.-weather)*smoothstep(-.7,1.,N.y)*pow5(1.-dotN)*sun.y*tex1.g*(snoise(PSInput.cPos.xz)*.2+.8));
#else
}
#endif

//gate
#if defined(BLEND) && defined(USE_NORMAL)
	float2 gate = float2(PSInput.cPos.x+PSInput.cPos.z,PSInput.cPos.y);
	if(1.5<PSInput.block && PSInput.block<2.5)diffuse=lerp(diffuse,lerp(float4(.2,0,1,.5),float4(1,.5,1,1),(snoise(gate+snoise(gate+time*.1)-time*.1)*.5+.5)*(dotN*-.5+1.)),.7);
	else if(2.5<PSInput.block && diffuse.a>.5 && sat<.2)diffuse.rgb=lerp((FOG_COLOR.rgb+tex1.rgb)*.5,diffuse.rgb,dotN*.9+.1);
#endif

//=*=*=  ESBE_3G end  =*=*=//

#ifdef FOG
	diffuse.rgb = lerp( diffuse.rgb, PSInput.fogColor.rgb, PSInput.fogColor.a );
#endif

	PSOutput.color = diffuse;

#ifdef VR_MODE
	// On Rift, the transition from 0 brightness to the lowest 8 bit value is abrupt, so clamp to
	// the lowest 8 bit value.
	PSOutput.color = max(PSOutput.color, 1 / 255.0f);
#endif

#endif // BYPASS_PIXEL_SHADER
}
