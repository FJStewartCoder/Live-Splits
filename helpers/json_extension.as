// many overloads for a ToJson function that can translate more values
float[] Serialise(vec4 value) {
    return {value.x, value.y, value.z, value.w};
}

float[] Serialise(vec3 value) {
    return {value.x, value.y, value.z};
}

// -----------------------------------------------------------------------------------

vec4 Vec4FromArray(float[] value) {
    vec4 res = {0, 0, 0, 0};

    if (value.Length != 4) { return res; }

    res = {
        value[0],
        value[1],
        value[2],
        value[3]
    };

    return res;
}

vec3 Vec3FromArray(float[] value) {
    vec3 res = {0, 0, 0};

    if (value.Length != 3) { return res; }

    res = {
        value[0],
        value[1],
        value[2]
    };

    return res;
}