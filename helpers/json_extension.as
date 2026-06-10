// many overloads for a ToJson function that can translate more values
float[] Cerealise(vec4 value) {
    return {value.x, value.y, value.z, value.w};
}

float[] Cerealise(vec3 value) {
    return {value.x, value.y, value.z};
}

float[] Cerealise(vec2 value) {
    return {value.x, value.y};
}

dictionary Cerealise(Render::NormalSectionSettings@ settings) {
    return {
        {"width", settings.width},
        {"padding", settings.padding},
        {"textAlignment", Cerealise(settings.textAlignment)},
        {"backgroundColour", Cerealise(settings.backgroundColour)},
        {"textColour", Cerealise(settings.textColour)}
    };
}

uint Cerealise(Render::TextAlignment value) {
    uint res = 0;

    switch (value) {
        case Render::TextAlignment::LEFT:
            res = 0;
            break;
        case Render::TextAlignment::CENTRE:
            res = 1;
            break;
        case Render::TextAlignment::RIGHT:
            res = 2;
            break;
    }

    return res;
}

// -----------------------------------------------------------------------------------

vec4 UncerealiseVec4(const Json::Value@ value) {
    vec4 res = vec4(0, 0, 0, 0);

    if (value.Length != 4) { return res; }

    res = vec4(
        value[0],
        value[1],
        value[2],
        value[3]
    );

    return res;
}

vec3 UncerealiseVec3(const Json::Value@ value) {
    vec3 res = vec3(0, 0, 0);

    if (value.Length != 3) { return res; }

    res = vec3(
        value[0],
        value[1],
        value[2]
    );

    return res;
}

vec2 UncerealiseVec2(const Json::Value@ value) {
    vec2 res = vec2(0, 0);

    if (value.Length != 2) { return res; }

    res = vec2(
        value[0],
        value[1]
    );

    return res;
}

Render::TextAlignment UncerealiseTextAlignment(const Json::Value@ value) {
    Render::TextAlignment res = Render::TextAlignment::LEFT;

    uint fromJson = value;

    switch ( fromJson ) {
        case 0:
            res = Render::TextAlignment::LEFT;
            break;
        case 1:
            res = Render::TextAlignment::CENTRE;
            break;
        case 2:
            res = Render::TextAlignment::RIGHT;
            break;
    }

    return res;
}

Render::NormalSectionSettings UncerealiseNormalSectionSettings(const Json::Value@ value) {
    Render::NormalSectionSettings settings;

    settings.width = value.Get("width");
    settings.padding = value.Get("padding");
    settings.textAlignment = UncerealiseTextAlignment(value.Get("textAlignment"));
    settings.backgroundColour = UncerealiseVec4(value.Get("backgroundColour"));
    settings.textColour = UncerealiseVec4(value.Get("textColour"));

    return settings;
}