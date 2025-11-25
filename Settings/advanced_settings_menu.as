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
    if (value != newValue) { performanceChoice = performanceOptions.Length - 1; }

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
    if (value != newValue) { performanceChoice = performanceOptions.Length - 1; }

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
    // arrayMaxSize

    // get array max size using custom wrapper thing
    arrayMaxSize = IntInput("Array Max Size", arrayMaxSize, 500, 10000000, 100);  // 500 - 10_000_000

    // --------------------------------------------------------------------
    // framesBetweenGap

    // reuses value
    int value = IntInput("Frames Between Getting Gap", framesBetweenGap.GetCount(), 1, 500, 1);
    // set both the stored value and the actual value to the same number to preserve sync
    SetGapValue(value);
}

void GapSettings() {
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

                // if selected, set setting to custom
                performanceChoice = performanceOptions.Length - 1;
            }
        }

        UI::EndCombo();
    }

    // --------------------------------------------------------------------
    // searchRangeSeconds

    // only allow for changing this if using estimation algorithm
    if (gapAlg == GapAlgorithm::Estimation) {
        // get array max size using custom wrapper thing
        searchRangeSeconds = IntInput("Search Radius (Seconds)", searchRangeSeconds, 1, 60, 1);
    }
    // only allow for changing this if using mod lin
    else if (gapAlg == GapAlgorithm::Full) {
        // get array max size using custom wrapper thing
        modLinResolution = IntInput("Search Resolution", modLinResolution, 2, 30, 1);
    }
}

// ACCESS TO EVERY SETTING IN DETAIL

[SettingsTab name="Advanced" order="1"]
void AdvancedSettings() {
    UI::BeginTabBar("AdvancedTabBar");

    if (UI::BeginTabItem("All")) {
        AllSettings();

        UI::EndTabItem();
    }

    if (UI::BeginTabItem("Gap")) {
        GapSettings();

        UI::EndTabItem();
    }

    UI::EndTabBar();
}