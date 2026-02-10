#version 330 core

out vec4 FragColor;
uniform vec2 u_resolution;
uniform vec3 u_camera_pos;
uniform mat3 u_camera;
uniform float u_time, u_zslice;

float orbitTrap = 1.0;

vec2 map(vec3 p) {
    vec4 scale = vec4(2.5);
    vec4 z = vec4(p, u_zslice);
    vec4 offset = z;
    float dr = 1.0;

    float trap = 1e20;

    for (int i = 0; i < 12; i++) {
        z = clamp(z, -1.0, 1.0) * 2.0 - z;

        float r2 = dot(z, z);
        if (r2 < 0.5) {
            z *= 4.0;
            dr *= 4.0;
        } else if (r2 < 1.0) {
            z /= r2;
            dr /= r2;
        }

        z = z * scale + offset;
        dr = dr * abs(scale.x) + 1.0;

        trap = min(trap, dot(z.xyz, z.xyz));
    }

    float dist = length(z) / abs(dr);
    return vec2(dist, trap);
}

vec3 getNormalOpt(vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.0005;
    return normalize(
        e.xyy * map(p + e.xyy).x +
        e.yyx * map(p + e.yyx).x +
        e.yxy * map(p + e.yxy).x +
        e.xxx * map(p + e.xxx).x
    );
}

float getAO(vec3 p, vec3 n) {
    float occ = 0.0;
    float weight = 1.0;
    for(int i = 1; i <= 5; i++) {
        float dStep = 0.01 * float(i);
        float d = map(p + n * dStep).x;
        occ += (dStep - d) * weight;
        weight *= 0.5;
    }
    return clamp(1.0 - 5.0 * occ, 0.0, 1.0);
}

void main() {
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / u_resolution.y;
    vec3 ro = u_camera_pos;
    vec3 rd = u_camera * normalize(vec3(uv, 1.5));

    float t = 0.0;
    float d;
    float resTrap = 0.0;

    for(int i = 0; i < 150; i++) {
        vec2 m = map(ro + rd * t);
        d = m.x;
        resTrap = m.y;
        if (d < 0.001 * t || t > 20.0) break;
        t += d * 0.5;
    }

    vec3 color = vec3(0.01, 0.01, 0.02);

    if (t < 20.0) {
        vec3 p = ro + rd * t;
        vec3 n = getNormalOpt(p);
        float ao = getAO(p, n);

        vec3 baseCol = 0.5 + 0.5 * cos(log(resTrap) * 0.4 + vec3(0.0, 0.6, 1.2));

        vec3 lightDir = normalize(vec3(0.5, 0.8, -0.5));
        float diff = max(dot(n, lightDir), 0.0);
        float sky = clamp(0.5 + 0.5 * n.y, 0.0, 1.0);

        color = baseCol * (diff + sky * 0.3);
        color *= ao;

        color = mix(color, vec3(0.01, 0.01, 0.02), 1.0 - exp(-0.1 * t));
    }

    color = pow(color, vec3(0.4545));
    FragColor = vec4(color, 1.0);
}