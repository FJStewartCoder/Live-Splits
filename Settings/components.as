namespace UIX {
    int InputInt(
        const string&in name,
        int value, 
        int min, int max,
        int step = 1,
        bool callUpdate = true
    ) {
        // used to check for a change
        int newValue = UI::InputInt(name, value, step);

        // if the setting has been updated, call an update
        if ((value != newValue) && callUpdate) { UIX::OnSettingsUpdate(); }

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
        bool callUpdate = true
    ) {
        // arbitrary value
        float newValue = UI::InputFloat(name, value, step, step_fast, fmt);

        if ((value != newValue) && callUpdate) { UIX::OnSettingsUpdate(); }

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
        bool callUpdate = true
    ) {
        const float screenHeight = Display::GetHeight();

        float newValue = UI::SliderInt(
            label, 
            currentValue * screenHeight, 
            0, screenHeight
        );

        // set the new value to the normalised data
        newValue /= screenHeight;

        // if the data changes, send an update
        if ((value != newValue) && callUpdate) { UIX::OnSettingsUpdate(); }

        return newValue;
    }

    float RelativeWidth(
        const string&in label,
        float value,
        bool callUpdate = true
    ) {
        const float screenWidth = Display::GetHeight();

        float newValue = UI::SliderInt(
            label, 
            currentValue * screenWidth, 
            0, screenWidth
        );

        // normalise the data
        newValue /= screenWidth; 

        // check for updates
        if ((value != newValue) && callUpdate) { UIX::OnSettingsUpdate(); }

        return newValue;
    }

    // CALLBACKS -----------------------------------------------------------------------------------

    void OnSettingsUpdate() {
        print("A setting has been updated");
        AssignSettings();
    }
}