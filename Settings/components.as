int IntInput(const string&in name, int value, int min, int max, int step = 1) {
    // arbitrary value
    int newValue;

    // make the input int
    newValue = UI::InputInt(name, value, step);

    // if changed, set performance choice to custom
    // TODO: re-implement similar
    // if (value != newValue) { performanceChoice = performanceOptions.Length - 1; }

    // set numCars to the value
    value = newValue;

    // basic validation (1, 20)
    if (value < min) { value = min; }
    else if (value > max) { value = max; }

    return value;
}

float FloatInput(const string&in name, float value, float min, float max, float step = 1, float step_fast = 2, string fmt = "%.3f") {
    // arbitrary value
    float newValue;

    // make the input int
    newValue = UI::InputFloat(name, value, step, step_fast, fmt);

    // if changed, set performance choice to custom
    // TODO: re-implement similar
    // if (value != newValue) { performanceChoice = performanceOptions.Length - 1; }

    // set numCars to the value
    value = newValue;

    // basic validation (1, 20)
    if (value < min) { value = min; }
    else if (value > max) { value = max; }

    return value;
}

float RelativeHeight(const string&in label, float currentValue) {
    const float screenHeight = Display::GetHeight();

    int value = UI::SliderInt(
        label, 
        currentValue * screenHeight, 
        0, screenHeight
    );

    return float(value) / screenHeight;
}

float RelativeWidth(const string&in label, float currentValue) {
    const float screenWidth = Display::GetHeight();

    int value = UI::SliderInt(
        label, 
        currentValue * screenWidth, 
        0, screenWidth
    );

    return float(value) / screenWidth;
}