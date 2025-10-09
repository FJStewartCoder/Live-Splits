array<string> performanceOptions = {
    "Very Fast",
    "Fast",
    "Default",
    "High",
    "Very High",
    "Custom"  // does nothing
};

// having as a setting will save when reload
[Setting hidden]
uint performanceChoice = 2;

// used to calculate each setting's performance degree
[Setting hidden]
uint expectedFrameRate = 60;


// sets the current settings config
void SetConfig() {
    switch (performanceChoice) {
        // very fast
        // AIM FOR 5 MINUTES OF LOG AT FRAME RATE
        // LOG EVERY 2 FRAMES
        // SHOW GAP 3 TIMES PER SECOND
        case 0:
            // prints setting name
            print("Setting: Very Fast");
    
            searchRadius = 1000;

            // 5 minutes at frame rate ( /4 because thats how many frames between a log)
            arrayMaxSize = expectedFrameRate * 60 * 5 / 4;
            numCars = 3;

            // sets new counts
            framesBetweenLog.SetCount(4);
            // sets the gap to the integer version of expectedFrameRate / 4 to get 4 times per second
            framesBetweenGap.SetCount(uint(Math::Round(expectedFrameRate / 4, 0)));

            // estimation is the absolute fastest availible
            gapAlg = GapAlgorithm::Estimation;

            break;

        // fast
        // SUITABLE FOR 10 MINUTES AT FRAME RATE
        // UPDATES LOG EVERY 2 FRAMES
        // JUST OVER 100 CHECKS PER GAP
        // 10 UPDATES PER SECOND
        case 1:
            // prints setting name
            print("Setting: Fast");

            // 10 minutes at frame rate ( /2 because thats how many frames between a log)
            arrayMaxSize = expectedFrameRate * 60 * 10 / 2;
            numCars = 4;

            // sets new counts
            framesBetweenLog.SetCount(2);
            // sets the gap to the integer version of expectedFrameRate / 10 to get 10 times per second
            framesBetweenGap.SetCount(uint(Math::Round(expectedFrameRate / 10, 0)));

            gapAlg = GapAlgorithm::ModifiedLinear;

            break;

        // default
        // 20 MINUTES AT FRAME RATE
        case 2:
            // prints setting name
            print("Setting: Default");

            // 20 minutes
            arrayMaxSize = expectedFrameRate * 60 * 20;
            numCars = 5;

            // sets new counts
            framesBetweenLog.SetCount(1);
            framesBetweenGap.SetCount(12);

            gapAlg = GapAlgorithm::ModifiedLinear;

            break;

        // high
        // SUITABLE FOR 45 MINUTES HOUR AT FRAME RATE
        case 3:
            // prints setting name
            print("Setting: High");

            arrayMaxSize = expectedFrameRate * 60 * 45;
            numCars = 7;

            // sets new counts
            framesBetweenLog.SetCount(1);
            framesBetweenGap.SetCount(8);

            gapAlg = GapAlgorithm::ModifiedLinear;

            break;

        // very high
        // SUITABLE FOR 2 HOUR AT FRAME RATE
        case 4:
            // prints setting name
            print("Setting: Very High");

            arrayMaxSize = expectedFrameRate * 60 * 120;
            numCars = 10;

            // sets new counts
            framesBetweenLog.SetCount(1);
            framesBetweenGap.SetCount(4);

            gapAlg = GapAlgorithm::Linear;

            break;
        
        // none
        default:
            // prints setting name
            print("Setting: Other");

            // invalid so do nothing
            break;
    }

    // resets everything to prevent issues
    ResetAllVars();
}


// ON OR OFF
// PERFORMANCE MODE
// SHOW GAP WHILE LOGGING

[SettingsTab name="Basic"]
void BasicSettings() {
    // create a checkbox to say if the plugin is enabled
    isEnabled = UI::Checkbox("Enable Plugin", isEnabled);

    // gets expectedFrameRate
    expectedFrameRate = UI::InputInt("Frame Rate", expectedFrameRate, 5);

    // max frame rate is 100
    if (expectedFrameRate > 500) {
        expectedFrameRate = 500;
    }

    // min frame rate is 10
    if (expectedFrameRate < 10) {
        expectedFrameRate = 10;
    }
    
    // creates a combo box
    if (UI::BeginCombo("Performance Option", performanceOptions[performanceChoice])) {
        // iterate all options and include them as selectables
        for (uint i = 0; i < performanceOptions.Length; i++) {
            // get the current value
            bool value = (performanceChoice == i);

            // if clicked, set the new selected option
            if (UI::Selectable(performanceOptions[i], value)) {
                // set the performance choice
                performanceChoice = i;

                // updatge the config
                SetConfig();

                // print changed 
                print("changed.");
            }
        }

        UI::EndCombo();
    }

    // checkbox for getGapOverride;
    getGapOverride = UI::Checkbox("Show Gap While Logging", getGapOverride);
}