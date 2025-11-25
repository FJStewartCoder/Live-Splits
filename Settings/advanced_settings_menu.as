// list of algorithm names as strings
array<string> algorithmChoices = {
    "Full",
    "Estimation"
};

// ------------------------------------------------------------------------------------------------

int IntInput(const string&in name, int value, int min, int max, int step = 1) {
    // arbitrary value
    int newValue;

    // make the input int
    newValue = UI::InputInt(name, value, step);

    // if changed, set performance choice to custom
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
    // if (value != newValue) { performanceChoice = performanceOptions.Length - 1; }

    // set numCars to the value
    value = newValue;

    // basic validation (1, 20)
    if (value < min) { value = min; }
    else if (value > max) { value = max; }

    return value;
}

// -----------------------------------------------------------------------------------------------

void AllSettings() {
    // --------------------------------------------------------------------
    // gapAlg

    if (algorithmChoice >= algorithmChoices.Length) { algorithmChoice = 0; } 

    // toggle for use linear gap
    useLinearGap = UI::Checkbox("Use Linear", useLinearGap);

    // create the combo box for the gap algorithm
    if (UI::BeginCombo("Gap Algorithm", algorithmChoices[algorithmChoice])) {
        // iterate choices
        for (int i = 0; i < algorithmChoices.Length; i++) {
            // check for if selected
            bool isSelected = algorithmChoice == i;

            // selectable to get the choice
            if (UI::Selectable(algorithmChoices[i], isSelected)) {
                // sets the new gap alg to the one defined by index
                // need to use this function to prevent unusual desync
                SetGapAlg(intToEnum(i));
            }
        }

        UI::EndCombo();
    }
}