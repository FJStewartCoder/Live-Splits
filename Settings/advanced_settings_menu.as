// list of algorithm names as strings
array<string> algorithmChoices = {
    "Linear",
    "Modified Linear",
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

// ACCESS TO EVERY SETTING IN DETAIL

[SettingsTab name="Advanced" order="1"]
void AdvancedSettings() {
    // --------------------------------------------------------------------
    // numCars

    // get number of cars using custom wrapper thing
    numCars = IntInput("Number of Cars", numCars, 1, 20);

    // --------------------------------------------------------------------
    // arrayMaxSize

    // get array max size using custom wrapper thing
    arrayMaxSize = IntInput("Array Max Size", arrayMaxSize, 500, 10000000, 100);  // 500 - 10_000_000

    // --------------------------------------------------------------------
    // framesBetweenLog


    int value = IntInput("Frames Between Logging Point", framesBetweenLog.GetCount(), 1, 500, 1);
    // set both the stored value and the actual value to the same number to preserve sync
    SetLogValue(value);

    // --------------------------------------------------------------------
    // framesBetweenGap

    // reuses value
    value = IntInput("Frames Between Getting Gap", framesBetweenGap.GetCount(), 1, 500, 1);
    // set both the stored value and the actual value to the same number to preserve sync
    SetGapValue(value);

    // --------------------------------------------------------------------
    // gapAlg

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
}