// Crop code values that are out of the SDR range

//!PARAM CONTRAST_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000000
1000.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (clip)

const float DISPGAMMA = 2.4;
const float L_W = 1.0;
const float L_B = 0.0;

float bt1886_r(float L, float gamma, float Lw, float Lb) {
    float a = pow(pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma), gamma);
    float b = pow(Lb, 1.0 / gamma) / (pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma));
    float V = pow(max(L / a, 0.0), 1.0 / gamma) - b;
    return V;
}

float bt1886_f(float V, float gamma, float Lw, float Lb) {
    float a = pow(pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma), gamma);
    float b = pow(Lb, 1.0 / gamma) / (pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma));
    float L = a * pow(max(V + b, 0.0), gamma);
    return L;
}

float curve(float x) {
    x = bt1886_r(x, DISPGAMMA, L_W, L_W / CONTRAST_sdr);
    x = bt1886_f(x, DISPGAMMA, L_W, L_B);
    return x;
}

vec3 tone_mapping_rgb(vec3 RGB) {
    return vec3(curve(RGB.r), curve(RGB.g), curve(RGB.b));
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = tone_mapping_rgb(color.rgb);

    return color;
}
