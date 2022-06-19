#include "ShaderConstants.fxh"

struct VS_Input{
	float3 position : POSITION;
	float4 color : COLOR;
	float2 uv0 : TEXCOORD_0;
	float2 uv1 : TEXCOORD_1;
#ifdef INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
};


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
#ifdef GEOMETRY_INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
#ifdef VERTEXSHADER_INSTANCEDSTEREO
	uint renTarget_id : SV_RenderTargetArrayIndex;
#endif
};

static const float rA = 1.0;
static const float rB = 1.0;
static const float3 UNIT_Y = float3(0, 1, 0);
static const float DIST_DESATURATION = 56.0 / 255.0; //WARNING this value is also hardcoded in the water color, don'tchange

#ifdef FANCY
float gwav(float x,float r,float l){//http://marupeke296.com/Shader_No5_PeakWave.html
	static const float pi=3.1415926535;
	float a = l/pi/2.;float b = r*l/pi/4.;
	float T = x/a;
	for(int i=0;i<3;i++)T=T-(a*T-b*sin(T)-x)/(a-b*cos(T));
	return r*l*cos(T)/pi/4.;
}
float hash11(float p){p=frac(p*.1031);p*=p+33.33;return frac((p+p)*p);}//https://www.shadertoy.com/view/4djSRW
float random(float3 p){
	p.x = dot(float3(p.x==16.?0.:p.x,abs(p.y-8.),p.z==16.?0.:p.z),.33)+TOTAL_REAL_WORLD_TIME;
	return lerp(hash11(floor(p.x)),hash11(ceil(p.x)),smoothstep(0.,1.,frac(p.x)))*2.;
}
#endif

ROOT_SIGNATURE
void main(in VS_Input VSInput, out PS_Input PSInput){
PSInput.block=0.;
float wav = sin((VSInput.position.x+VSInput.position.z+VSInput.position.y-TOTAL_REAL_WORLD_TIME*2.)*1.57);
float rand =
#ifdef FANCY
	random(VSInput.position.xyz);
#else
	1.;
#endif
#ifndef BYPASS_PIXEL_SHADER
	PSInput.uv0 = VSInput.uv0;
	PSInput.uv1 = VSInput.uv1;
	PSInput.color = VSInput.color;
#endif
#ifdef AS_ENTITY_RENDERER
	#ifdef INSTANCEDSTEREO
		int i = VSInput.instanceID;
		PSInput.position = mul(WORLDVIEWPROJ_STEREO[i], float4(VSInput.position, 1));
	#else
		PSInput.position = mul(WORLDVIEWPROJ, float4(VSInput.position, 1));
	#endif
		float3 worldPos = PSInput.position;
#else
		float3 worldPos = (VSInput.position.xyz * CHUNK_ORIGIN_AND_SCALE.w) + CHUNK_ORIGIN_AND_SCALE.xyz;
		//water
		#ifndef SEASONS
			if(.05<VSInput.color.a&&VSInput.color.a<.95){
				#ifdef FANCY
					worldPos.y+=gwav(VSInput.position.x+VSInput.position.z-TOTAL_REAL_WORLD_TIME*2.,lerp(.3,.8,VSInput.uv1.y)*rand,4.)*frac(VSInput.position.y)*saturate(1.-length(worldPos)/FAR_CHUNKS_DISTANCE)*.2;
				#else
					float wwav = sin((VSInput.position.x+VSInput.position.z-TOTAL_REAL_WORLD_TIME*2.)*1.57)*.5+.5;
					worldPos.y+=(wwav*wwav-.5)*frac(VSInput.position.y)*saturate(1.-length(worldPos)/FAR_CHUNKS_DISTANCE)*lerp(.02,.07,VSInput.uv1.y);
				#endif
			}
		#endif
		// Transform to view space before projection instead of all at once to avoid floating point errors
		// Not required for entities because they are already offset by camera translation before rendering
		// World position here is calculated above and can get huge
	#ifdef INSTANCEDSTEREO
		int i = VSInput.instanceID;
		PSInput.position = mul(WORLDVIEW_STEREO[i], float4(worldPos, 1 ));
		PSInput.position = mul(PROJ_STEREO[i], PSInput.position);
	#else
		PSInput.position = mul(WORLDVIEW, float4( worldPos, 1 ));
		PSInput.position = mul(PROJ, PSInput.position);
	#endif
#endif
PSInput.cPos=VSInput.position;
PSInput.wPos=worldPos;
//leaf
float3 frp = frac(VSInput.position);
#ifdef ALPHA_TEST
	if((VSInput.color.r!=VSInput.color.g&&VSInput.color.g!=VSInput.color.b && frp.y!=.015625)||(frp.y==.9375&&(frp.x==0.||frp.z==0.)))
		PSInput.position.x += wav*rand*lerp(.007,.015,VSInput.uv1.y);
#endif

#ifdef GEOMETRY_INSTANCEDSTEREO
	PSInput.instanceID = VSInput.instanceID;
#endif
#ifdef VERTEXSHADER_INSTANCEDSTEREO
	PSInput.renTarget_id = VSInput.instanceID;
#endif

///// find distance from the camera
float cameraDepth = length(-worldPos);

///// apply fog
#ifdef FOG
	float len = cameraDepth / RENDER_DISTANCE;
	#ifdef ALLOW_FADE
		len += RENDER_CHUNK_FOG_ALPHA.r;
	#endif
	PSInput.fogColor.rgb = FOG_COLOR.rgb;
	PSInput.fogColor.a = saturate((len - FOG_CONTROL.x) / (FOG_CONTROL.y - FOG_CONTROL.x));
	float fcxdy = FOG_CONTROL.x/FOG_CONTROL.y;
	if(.1<fcxdy&&fcxdy<.12)PSInput.position.xy += wav*PSInput.fogColor.a*.15*(rand*.5+.5);//nether
	else if(FOG_CONTROL.x<.01)PSInput.position.x += wav*PSInput.fogColor.a*.1*rand;//uw
#endif

///// blended layer (mostly water) magic
#ifndef SEASONS
	if(.05<VSInput.color.a && VSInput.color.a<.95){
		PSInput.block=1.;
		PSInput.color.a = lerp(VSInput.color.a,1.,saturate(cameraDepth/FAR_CHUNKS_DISTANCE));
	}
#endif
#ifdef BLEND
	if(frp.x==.375||frp.x==.625||frp.z==.375||frp.z==.625)PSInput.block=2.;
	else if(frp.y==.0625)PSInput.block=3.;
#endif
}
