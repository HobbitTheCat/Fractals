#version 330 core
out vec4 FragColor;
uniform vec2 u_resolution;
uniform vec3 u_camera_pos;
uniform mat3 u_camera;
uniform float u_time;

const int Iterations = 8;
const float Bailout = 2.0;
float trapRes = 1e20;

float sdMandelbulb(vec3 pos) {
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;

//    float Power = 8;
    float Power = 5.0 + 4.0 * sin(u_time * 0.5);
    trapRes = 1e20;

    for (int i = 0; i < Iterations; i++) {
        r = length(z);
        if (r > Bailout) break;

        trapRes = min(trapRes, length(z.xz) - 0.2);

        float theta = acos(z.y / r) * Power;
        float phi = atan(z.z, z.x) * Power;
        float zr = pow(r, Power);

        dr = pow(r, Power - 1.0) * Power * dr + 1.0;
        z = zr * vec3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi));
        z += pos;
    }
    return 0.5 * log(r) * r / dr;
}

float map(vec3 p) {
    return sdMandelbulb(p);
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

void main() {
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / u_resolution.y;
    vec3 ro = u_camera_pos;
    float zoom = 1.5;
    vec3 rd_raw = normalize(vec3(uv, zoom));
    vec3 rd = u_camera * rd_raw;

    float t = 0.0;
    float precision_limit = 0.0002;
    float max_steps = 150;

    for(int i = 0; i < max_steps; i++) {
        vec3 p = ro + rd * t;
        float d = map(p);
        if (d < precision_limit * t || t > 20) break;
        t += d * 0.95;
    }

    vec3 color = vec3(0.1, 0.1, 0.2);
    if (t < 20) {
        vec3 p = ro + rd * t;
        vec3 normal = getNormalOpt(p);
        float orbitColor = clamp(trapRes, 0.0, 1.0);
        vec3 col = vec3(0.5 + 0.5 * sin(orbitColor * 10.0 + vec3(0, 2, 4)));
        vec3 lightDir = normalize(vec3(1, 1, -1));
        float diff = max(dot(normal, lightDir), 0.1);

        color = col * diff;
    }
    FragColor = vec4(color, 1.0);
}