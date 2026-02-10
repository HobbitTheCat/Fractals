#version 330 core
out vec4 FragColor;
uniform vec2 u_resolution;
uniform vec3 u_camera_pos;
uniform mat3 u_camera;
uniform float u_time;

const int Iterations = 8;
const float SCALE = 2.8;
const float MR2 = 0.25; // Minimum Radius Squared
const float FR2 = 1.0;  // Fixed Radius Squared
float trapRes = 1e20;

float sdMandelbox(vec3 pos) {
    vec4 v = vec4(pos, 1.0);
    vec4 origin = v;
    float trap = 1e20;

    for (int i = 0; i < Iterations; i++) {
        v.xyz = clamp(v.xyz, -1.0, 1.0) * 2.0 - v.xyz;

        float r2 = dot(v.xyz, v.xyz);
        if (r2 < MR2) v *= FR2 / MR2;
        else if (r2 < FR2) v *= FR2 / r2;

        v = v * SCALE + origin;

        trap = min(trap, r2);
    }
    trapRes = trap;
    return length(v.xyz) / abs(v.w);
}

float map(vec3 p) {
    return sdMandelbox(p);
}

vec3 getNormal(vec3 p) {
    float d = map(p);
    vec2 e = vec2(0.001, 0.0);
    vec3 n = d - vec3(
    map(p - e.xyy),
    map(p - e.yxy),
    map(p - e.yyx)
    );
    return normalize(n);
}

vec3 getNormalOpt(vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.0005;
    return normalize(
        e.xyy * map(p + e.xyy) +
        e.yyx * map(p + e.yyx) +
        e.yxy * map(p + e.yxy) +
        e.xxx * map(p + e.xxx)
    );
}

float getAO(vec3 p, vec3 n) {
    float occ = 0.0;
    float weight = 1.0;
    for(int i = 1; i <= 5; i++) {
        float dStep = 0.01 * float(i);
        float d = map(p + n * dStep);
        occ += (dStep - d) * weight;
        weight *= 0.5;
    }
    return clamp(1.0 - 5.0 * occ, 0.0, 1.0);
}

void main() {
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / u_resolution.y;
    vec3 ro = u_camera_pos;
    float zoom = 1.5;
    vec3 rd_raw = normalize(vec3(uv, zoom));
    vec3 rd = u_camera * rd_raw;

    float t = 0.0;
    float precision_limit = 0.001;
    float max_steps = 150;

    for(int i = 0; i < max_steps; i++) {
        vec3 p = ro + rd * t;
        float d = map(p);
        if (d < precision_limit * t || t > 20) break;
        t += d * 0.95;
    }


    // Chat GPT
    vec3 color = vec3(0.02, 0.02, 0.05);

    if (t < 40.0) {
        vec3 p = ro + rd * t;
        vec3 n = getNormalOpt(p);

        float ao = getAO(p, n);
        vec3 baseCol = 0.5 + 0.5 * cos(log(trapRes) * 0.5 + vec3(0.0, 0.6, 1.2));
        vec3 lightDir = normalize(vec3(0.5, 0.8, -0.5));
        float diff = max(dot(n, lightDir), 0.0);
        float sky = clamp(0.5 + 0.5 * n.y, 0.0, 1.0);
        color = baseCol * (diff + sky * 0.3);
        color *= ao;

        color = mix(color, vec3(0.02, 0.02, 0.05), 1.0 - exp(-0.02 * t));
    }

    FragColor = vec4(color, 1.0);
}