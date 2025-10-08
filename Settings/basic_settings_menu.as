array<string> performanceOptions = {
    "Very Fast",
    "Fast",
    "Default",
    "High",
    "Very High"
};

uint performanceChoice;


// sets the current settings config
void SetConfig() {
    switch (performanceChoice) {
        // very fast
        // SUITABLE FOR 1 HOUR AT 60 FPS
        // UPDATES 4 TIMES PER SECONDS AT 60 FPS
        // RANGE OF SEARCH OF 2000
        // JUST OVER 100 CHECKS PER GAP
        case 0:
            currentSettings.searchRadius = 1000;
            currentSettings.checkIntervalsEst = {20, 3, 1};

            currentSettings.arrayMaxSize = 50000;  // 50_000
            currentSettings.numCars = 3;

            // sets new counts
            currentSettings.framesBetweenLog.SetCount(4);
            currentSettings.framesBetweenGap.SetCount(15);

            currentSettings.gapAlg = GapAlgorithm::Estimation;

            break;

        // fast
        // SUITABLE FOR 1 HOUR AT 120 FPS
        // UPDATES 6 TIMES PER SECONDS AT 120 FPS
        // JUST OVER 100 CHECKS PER GAP
        case 1:
            currentSettings.checkIntervals = {30, 6, 1};

            currentSettings.arrayMaxSize = 200000;  // 200_000
            currentSettings.numCars = 4;

            // sets new counts
            currentSettings.framesBetweenLog.SetCount(2);
            currentSettings.framesBetweenGap.SetCount(20);

            currentSettings.gapAlg = GapAlgorithm::ModifiedLinear;

            break;

        // default
        // SUITABLE FOR 1 HOUR AT 120 FPS
        // UPDATES 10 TIMES PER SECONDS AT 120 FPS
        case 2:
            currentSettings.checkIntervals = {40, 8, 1};

            currentSettings.arrayMaxSize = 400000;  // 400_000
            currentSettings.numCars = 5;

            // sets new counts
            currentSettings.framesBetweenLog.SetCount(1);
            currentSettings.framesBetweenGap.SetCount(12);

            currentSettings.gapAlg = GapAlgorithm::ModifiedLinear;

            break;

        // high
        // SUITABLE FOR 1 HOUR AT 240 FPS
        // UPDATES 20 TIMES PER SECONDS AT 240 FPS
        case 3:
            currentSettings.checkIntervals = {40, 8, 1};

            currentSettings.arrayMaxSize = 800000;  // 800_000
            currentSettings.numCars = 7;

            // sets new counts
            currentSettings.framesBetweenLog.SetCount(1);
            currentSettings.framesBetweenGap.SetCount(12);

            currentSettings.gapAlg = GapAlgorithm::ModifiedLinear;

            break;

        // very high
        // SUITABLE FOR 2 HOUR AT 240 FPS
        // UPDATES 30 TIMES PER SECONDS AT 240 FPS
        case 4:
            currentSettings.arrayMaxSize = 1600000;  // 1_600_000
            currentSettings.numCars = 10;

            // sets new counts
            currentSettings.framesBetweenLog.SetCount(1);
            currentSettings.framesBetweenGap.SetCount(8);

            currentSettings.gapAlg = GapAlgorithm::Linear;

            break;
        
        // none
        default:
            // invalid so do nothing
            break;
    }
}


// ON OR OFF
// PERFORMANCE MODE
// SHOW GAP WHILE LOGGING

[SettingsTab name="Basic"]
void BasicSettings() {
    // create a checkbox to say if the plugin is enabled
    UI::Checkbox("Enable Plugin", false);
    
    // creates a combo box
    if (UI::BeginCombo("Performance Option", performanceOptions[performanceChoice])) {
        // iterate all options and include them as selectables
        for (uint i = 0; i < performanceOptions.Length; i++) {
            // get the current value
            bool value = (performanceChoice == i);

            // if clicked, set the new selected option
            if (UI::Selectable(performanceOptions[i], value)) {
                // if it was not already selected, update all settings to the proper configuration
                if (performanceChoice != i) {
                    SetConfig();
                    print("changed.");
                }

                performanceChoice = i;
            }
        }

        UI::EndCombo();
    }

    // checkbox for currentSettings.getGapOverride;
    UI::Checkbox("Show Gap While Logging", false);
}