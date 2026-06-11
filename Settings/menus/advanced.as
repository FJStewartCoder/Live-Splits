// list of algorithm names as strings
array<string> algorithmChoices = {
    "Full",
    "Estimation"
};

// -----------------------------------------------------------------------------------------------

void GeneralSettings() {
    // --------------------------------------------------------------------
    // numCars

    // get number of cars using custom wrapper thing
    Settings::Gap::numCars =
        UIX::InputInt("Number of Cars", Settings::Gap::numCars, 1, 255);

    // --------------------------------------------------------------------
    // arrayMaxSize

    // get array max size using custom wrapper thing
    Settings::Logger::arrayMaxSize =
        UIX::InputInt("Array Max Size", Settings::Logger::arrayMaxSize, 500, 10000000, 100);  // 500 - 10_000_000

    // --------------------------------------------------------------------
    // framesBetweenLog

    Settings::Performance::framesBetweenLogValue =
        UIX::InputInt(
            "Frames Between Logging Point",
            Settings::Performance::framesBetweenLogValue,
            1, 500, 1
        );

    // --------------------------------------------------------------------
    // framesBetweenGap

    Settings::Performance::framesBetweenGapValue =
        UIX::InputInt(
            "Frames Between Getting Gap",
            Settings::Performance::framesBetweenGapValue,
            1, 500, 1
        );
}

void GapSettings() {
    // --------------------------------------------------------------------
    // gapAlg

    int algorithmChoice = int(Settings::Gap::algorithm);

    // toggle for use linear gap
    Settings::Gap::useLinearGap =
        UIX::Checkbox("Use Linear", Settings::Gap::useLinearGap);

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
                Settings::Gap::algorithm = intToEnum(i);
            }
        }

        UI::EndCombo();
    }

    // --------------------------------------------------------------------
    // searchRangeSeconds

    // only allow for changing this if using estimation algorithm
    if (Settings::Gap::algorithm == GapAlgorithm::Estimation) {
        // get array max size using custom wrapper thing
        Settings::Gap::searchRangeSeconds =
            UIX::InputInt("Search Radius (Seconds)", Settings::Gap::searchRangeSeconds, 1, 60, 1);
    }
    // only allow for changing this if using mod lin
    else if (Settings::Gap::algorithm == GapAlgorithm::Full) {
        // get array max size using custom wrapper thing
        Settings::Gap::modLinResolution =
            UIX::InputInt("Search Resolution", Settings::Gap::modLinResolution, 2, 30, 1);
    }
}

void CacheSettings() {
    Settings::Cache::enabled =
        UIX::Checkbox("Enable Cache", Settings::Cache::enabled);

    if (Settings::Cache::enabled) {
        // cache max size
        Settings::Cache::maxSize =
            UIX::InputInt("Max Cache Size", Settings::Cache::maxSize, 100, 25000 );
    }

    Settings::Cache::useApproximation =
        UIX::Checkbox("Enable Cache Approximation", Settings::Cache::useApproximation);
}

void FileSettings() {
    // deletes all ghost point saves
    if (UI::Button("Delete All Saved Ghosts")) {
        reference.localGhostMgr.DeleteAll();
    }
}

// ACCESS TO EVERY SETTING IN DETAIL

[SettingsTab name="Advanced" order="1"]
void AdvancedSettings() {
    UI::BeginTabBar("AdvancedTabBar");

    if (UI::BeginTabItem("General")) {
        GeneralSettings();

        UI::EndTabItem();
    }

    if (UI::BeginTabItem("Gap")) {
        GapSettings();

        UI::EndTabItem();
    }

    if (UI::BeginTabItem("Cache")) {
        CacheSettings();

        UI::EndTabItem();
    }

    if (UI::BeginTabItem("File")) {
        FileSettings();

        UI::EndTabItem();
    }

    UI::EndTabBar();
}