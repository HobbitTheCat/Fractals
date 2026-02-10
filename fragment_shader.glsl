#version 330 core
out vec4 FragColor;
uniform vec2 u_resolution;
uniform vec3 u_camera_pos;
uniform mat3 u_camera;
uniform float u_time,u_zslice;
uniform int partial;

float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

float sdThicknessPlane( vec3 p, vec3 n, float h, float thickness ) {
    return abs(dot(p,n) + h) - thickness;
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdGyroid(vec3 p, float scale, float thickness, float bias) {
    p *= scale;
    float g = dot(sin(p), cos(p.yzx));
    return (abs(g + bias) - thickness) / scale;
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec3 twist(vec3 p, float k) {
    float s = sin(k*p.y);
    float c = cos(k*p.y);
    mat2 mat = mat2(c,-s,s,c);
    return vec3(mat*p.xz, p.y);
}

vec3 bend(vec3 p, float k) {
    float c = cos(k * p.x);
    float s = sin(k * p.x);
    mat2 m = mat2(c, -s, s, c);
    return vec3(m * p.xz, p.y);
}

vec3 cheapBend(vec3 p, float k) {
    float c = cos(k * p.y);
    float s = sin(k * p.y);
    mat2 m = mat2(c, -s, s, c);
    return vec3(m * p.xy, p.z);
}

float opSmoothUnion( float d1, float d2, float k ) {
    k *= 4.0;
    float h = max(k-abs(d1-d2),0.0);
    return min(d1, d2) - h*h*0.25/k;
}

float map(vec3 p) {
    float sphereD = sdSphere(p, 10);
    float gyroidD = sdGyroid(p, 2, 0.4, 0.0);
    float planeD = sdThicknessPlane(p, vec3(0,1,0), u_zslice, 0.1);
    float gyr_sphere = max(sphereD,gyroidD);
//    return gyr_sphere;
    return max(gyr_sphere, planeD*partial);
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
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / u_resolution.y; // Координаты точки на стекле через которое смотрит камера (XY)
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
        t += d*.5;
    }

    vec3 color = vec3(0.1, 0.1, 0.2);
    if (t < 40.0) {
        vec3 p = ro + rd * t;                           // Вычисляем координаты точки
        vec3 normal = getNormalOpt(p);                  // Находим нормаль
        vec3 lightDir = normalize(vec3(1, 1, -1));      // Выставляем направление света
        float diff = max(dot(normal, lightDir), 0.1);   //
        color = vec3(0.2, 0.6, 1.0) * diff;
    }
    FragColor = vec4(color, 1.0);
}