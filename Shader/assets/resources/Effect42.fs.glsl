#ifdef GL_ES
precision mediump float;
#endif


// Shader Inputs
// uniform vec3      iResolution;           // viewport resolution (in pixels)
// uniform float     iGlobalTime;           // shader playback time (in seconds)
// uniform float     iTimeDelta;            // render time (in seconds)
// uniform int       iFrame;                // shader playback frame
// uniform float     iChannelTime[4];       // channel playback time (in seconds)
// uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
// uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
// uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube
// uniform vec4      iDate;                 // (year, month, day, time in seconds)
// uniform float     iSampleRate;           // sound sample rate (i.e., 44100)


uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iGlobalTime;           // shader playback time (in seconds)
//uniform float     iTimeDelta;            // render time (in seconds)
//uniform int       iFrame;                // shader playback frame
//uniform float     iChannelTime[4];       // channel playback time (in seconds)
//uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
//uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube
//uniform vec4      iDate;                 // (year, month, day, time in seconds)
//uniform float     iSampleRate;           // sound sample rate (i.e., 44100)






//_______________________________________________________________________________________________________

#define BOUNDING_RADIUS 1.1

#define COLOR1 vec3(1.0, 0.3, 0.0)
#define COLOR2 vec3(0.0, 0.7, 1.0)
#define BACKGROUND vec3(0.2, 0.8, 0.2)

#define ir3 0.57735

float mandelbulb(vec3 pos){
    vec3 w = pos;
    float dr = 1.0,r;
    vec3 p,p2,p4;
    float k1,k2,k3,k4,k5;

    for (int i = 0; i < 10; i++){
        r = dot(w, w);
        if (r > 4.0) break;
        dr =  pow(r, 3.5)*8.0*dr + 1.0;

        p = w;
        p2 = w * w;
        p4 = p2 * p2;

        k3 = p2.x + p2.z;
        k2 = inversesqrt( k3*k3*k3*k3*k3*k3*k3 );
        k1 = dot(p4, vec3(1)) - 6.0 * dot(p2, vec3(p2.y, p2.z, -p2.x / 3.0));
        k4 = dot(p2, vec3(1, -1, 1));
        k5 = 8.0*p.y*k4*k1*k2;

        w = pos + vec3(8.0*k5*p.x*p.z*(p2.x-p2.z)*(p4.x-6.0*p2.x*p2.z+p4.z),
                       -16.0*p2.y*k3*k4*k4 + k1*k1,
                       -k5*(p4.x*p4.x - 28.0*p4.x*p2.x*p2.z + 
                            70.0*p4.x*p4.z - 28.0*p2.x*p2.z*p4.z + p4.z*p4.z));
    }
    return log(r)*sqrt(r)/dr;
}

float dist(vec3 p) {
    return 0.385*mandelbulb(p);
}

bool bounding(in vec3 ro, in vec3 rd){
    float b = dot(rd,ro);
    return dot(ro,ro) - b*b < BOUNDING_RADIUS * BOUNDING_RADIUS;
}

vec2 march(vec3 ro, vec3 rd){
    if (bounding(ro, rd)){
        float t = 0.72, d;
        for (int i = 0; i < 96; i++){
            d = dist(ro + rd * t);
            t += d;

            if (d < 0.002) return vec2(t, d);
            if (d > 0.4) return vec2(-1.0);
        }
    }

    return vec2(-1.0);
}

vec3 normal(vec3 p){
    const float eps = 0.005;
    return normalize(vec3(dist(p+vec3(eps,0,0))-dist(p-vec3(eps,0,0)),
                          dist(p+vec3(0,eps,0))-dist(p-vec3(0,eps,0)),
                          dist(p+vec3(0,0,eps))-dist(p-vec3(0,0,eps))));
}

float theta = iGlobalTime * 0.2;
mat2 rot = mat2(+cos(theta), -sin(theta),
                +sin(theta), +cos(theta));
mat2 rrot = mat2(+cos(theta), +sin(theta),
                 -sin(theta), +cos(theta));
vec2 rxz = vec2(0.0, -1.8) * rot;
vec3 ro = vec3(rxz.x, sin(theta*1.61)*0.1, rxz.y);

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    //coordinates of pixel
    vec2 uv = (iResolution.xy - 2.0 * fragCoord.xy) / iResolution.y;


    vec3 rd = normalize(vec3(uv, 1.1));
    rd.xz *= rot;

    vec2 res = march(ro, rd);

    if (res.x > 0.0){
        vec3 end = ro + rd * res.x;

        vec3 norm = normal(end-rd*0.001);

        float ao = clamp((dist(end + norm * 0.02) - res.y) / 0.02, 0.0, 1.0);
        norm.xz *= rrot;

        float m = clamp(dot(end, end), 0.0, BOUNDING_RADIUS) / BOUNDING_RADIUS;
        vec3 col = mix(COLOR1, COLOR2, m*m*m);

        float d = max(dot(norm, vec3(-ir3)), 0.0);
        vec3 light = col * ao + 0.2 * d + 0.4 * d*d*d*d*d*d*d*d;

        fragColor = vec4(light, 1.0);
    } else {
        fragColor = vec4(BACKGROUND - length(uv) / 4.0, 1.0);
    }
}
//_______________________________________________________________________________________________________



void main( void)
{
	mainImage(gl_FragColor, gl_FragCoord.xy);
}