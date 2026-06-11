namespace UIX {
    funcdef void Callback();

    int InputInt(
        const string&in name,
        int value, 
        int min, int max,
        int step = 1,
        Callback@ onUpdate = UIX::OnSettingsUpdate
    ) {
        // used to check for a change
        int newValue = UI::InputInt(name, value, step);

        // if the setting has been updated, call an update
        if ((value != newValue) && (onUpdate !is null)) { onUpdate(); }

        // set numCars to the value
        value = newValue;

        // basic validation (1, 20)
        if (value < min) { value = min; }
        else if (value > max) { value = max; }

        return value;
    }

    float InputFloat(
        const string&in name,
        float value,
        float min, float max, 
        float step = 1, float step_fast = 2, 
        string fmt = "%.3f",
        Callback@ onUpdate = UIX::OnSettingsUpdate
    ) {
        // arbitrary value
        float newValue = UI::InputFloat(name, value, step, step_fast, fmt);

        if ((value != newValue) && (onUpdate !is null)) { onUpdate(); }

        // set numCars to the value
        value = newValue;

        // basic validation (1, 20)
        if (value < min) { value = min; }
        else if (value > max) { value = max; }

        return value;
    }

    float RelativeHeight(
        const string&in label,
        float value,
        Callback@ onUpdate = UIX::OnSettingsUpdate
    ) {
        const float screenHeight = Display::GetHeight();

        float newValue = UI::SliderInt(
            label, 
            value * screenHeight, 
            0, screenHeight
        );

        // set the new value to the normalised data
        newValue /= screenHeight;

        // if the data changes, send an update
        if ((value != newValue) && (onUpdate !is null)) { onUpdate(); }

        return newValue;
    }

    float RelativeWidth(
        const string&in label,
        float value,
        Callback@ onUpdate = UIX::OnSettingsUpdate
    ) {
        const float screenWidth = Display::GetHeight();

        float newValue = UI::SliderInt(
            label, 
            value * screenWidth, 
            0, screenWidth
        );

        // normalise the data
        newValue /= screenWidth; 

        // check for updates
        if ((value != newValue) && (onUpdate !is null)) { onUpdate(); }

        return newValue;
    }

    bool Checkbox(
        const string&in label,
        const bool value,
        Callback@ onUpdate = UIX::OnSettingsUpdate
    ) {
        bool newValue = UI::Checkbox(label, value);

        if ((value != newValue) && (onUpdate !is null)) { onUpdate(); }

        return newValue;
    }

    vec3 InputColor3(
        const string&in label,
        const vec3 value,
        Callback@ onUpdate = UIX::OnSettingsUpdate
    ) {
        vec3 newValue = UI::InputColor3(label, value);

        if ((value != newValue) && (onUpdate !is null)) { onUpdate(); }

        return newValue;
    }

    vec4 InputColor4(
        const string&in label,
        const vec4 value,
        Callback@ onUpdate = UIX::OnSettingsUpdate
    ) {
        vec4 newValue = UI::InputColor4(label, value);

        if ((value != newValue) && (onUpdate !is null)) { onUpdate(); }

        return newValue;
    }

    // CALLBACKS -----------------------------------------------------------------------------------

    void OnSettingsUpdate() {
        print("A setting has been updated");
        AssignSettings();
    }
}