#version 330 core

out vec4 FragColor;
uniform vec2 u_resolution;
uniform vec3 u_camera_pos;
uniform mat3 u_camera;
uniform float u_time,u_zslice;
uniform int partial;

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b-a) / k, 0.0, 1.0);
    return mix(b,a,h) - k * h * (1.0 - h);
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

float map(vec3 p) {
    float box = sdBox(p - vec3(0.0, 0.0, 0.0), vec3(0.5));
    float sphere = sdSphere(p-vec3(u_zslice, 0.0, 0.0), 0.6);
    return smin(box, sphere, 0.2);
//    return sdSphere(p, 0.6);
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

void main() {
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / u_resolution.y;
    vec3 ro = u_camera_pos;
    float zoom = 1.5;
    vec3 rd_raw = normalize(vec3(uv, zoom));
    vec3 rd = u_camera * rd_raw;

    float t = 0.0;
    float precision_limit = 0.0002;
    float max_steps = 150;

    for (int i = 0; i < max_steps; i++) {
        vec3 p = ro + rd * t;
        float d = map(p);
        if (d < precision_limit * t || t > 40) break;
        t += d;
    }

    vec3 color = vec3(0.1, 0.1, 0.2);
    if (t < 40.0) {
        vec3 p = ro + rd * t;
        vec3 normal = getNormalOpt(p);
        vec3 lightDir = normalize(vec3(1, 1, -1));
        float diff = max(dot(normal, lightDir), 0.1);
        color = vec3(0.2, 0.6, 1.0) * diff;
    }
    FragColor = vec4(color, 1.0);
}