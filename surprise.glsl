#version 330 core

out vec4 FragColor;
uniform vec2 u_resolution;
uniform vec3 u_camera_pos;
uniform mat3 u_camera;
uniform float u_time,u_zslice;
uniform int partial;


float sdSphere(vec4 p, float s) {
    return length(p) - s;
}

vec4 qMul(vec4 a, vec4 b) {
    return vec4(
    a.x*b.x - a.y*b.y - a.z*b.z - a.w*b.w,
    a.x*b.y + a.y*b.x + a.z*b.w - a.w*b.z,
    a.x*b.z - a.y*b.w + a.z*b.x + a.w*b.y,
    a.x*b.w + a.y*b.z - a.z*b.y + a.w*b.x
    );
}

float map(vec3 p) {
    vec4 z = vec4(p, u_zslice);

        vec4 c = vec4(-0.4, 0.6, 0.1, 0.0);

    float dr = 1.0;
    float r = 0.0;

    for (int i = 0; i < 16; i++) {
        r = length(z);
        if (r > 4.0) break;

        dr = 2.0 * r * dr;
        z = qMul(z, z) + c;
    }

    return 0.5 * log(r) * r / dr;
//    return sdSphere(z, 0.6);
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
        t += d * 0.8;
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