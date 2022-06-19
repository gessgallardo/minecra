highp float hash(highp float p) { p = fract(p * 0.011); p *= p + 7.5; p *= p + p; return fract(p); }
highp float hash(highp vec2 p) {highp vec3 p3 = fract(vec3(p.xyx) * 0.13); p3 += dot(p3, p3.yzx + 3.333); return fract((p3.x + p3.y) * p3.z); }

highp float noise(highp float x) {
    highp float i = floor(x);
    highp float f = fract(x);
    highp float u = f * f * (3.0 - 2.0 * f);
    return mix(hash(i), hash(i + 1.0), u);
}

highp float noise(highp vec2 x) {
    highp vec2 i = floor(x);
    highp vec2 f = fract(x);

	highp float a = hash(i);
    highp float b = hash(i + vec2(1.0, 0.0));
    highp float c = hash(i + vec2(0.0, 1.0));
    highp float d = hash(i + vec2(1.0, 1.0));
    
    highp vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

highp float noise(highp vec3 x) {
    const highp vec3 step = vec3(110, 241, 171);

    highp vec3 i = floor(x);
    highp vec3 f = fract(x);
 
    highp float n = dot(i, step);

    highp vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}