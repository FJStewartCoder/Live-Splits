// save the settings as JSON rather than the in-built system

IOX::Entry@[] GetSettingsFS() {
    return {
        SaveLocations::directory,
        SaveLocations::Base::file,
        SaveLocations::Performance::file,
        SaveLocations::UI::directory,
        SaveLocations::UI::baseFile,
        SaveLocations::UI::normalFile,
        SaveLocations::UI::barFile
    };
}

// returns true if the file stucture is good
// returns false if the file stucture is bad
bool VerifySettingFileStructure() {
    auto entries = GetSettingsFS();

    for (uint i = 0; i < entries.Length; i++) {
        // create a copy of the entry
        IOX::Entry@ entry = entries[i];

        if (!entry.Exists()) { return false; }
    }

    return true;
}

// creates the file structure
void CreateSettingFileStructure() {
    auto entries = GetSettingsFS();

    for (uint i = 0; i < entries.Length; i++) {
        // create a copy of the entry
        IOX::Entry@ entry = entries[i];

        // create the entry
        entry.Create();
    }
}

void HandleFS() {
    if (!VerifySettingFileStructure()) {
        CreateSettingFileStructure();
    }
}

namespace SaveSettings {
    void Base() {
        HandleFS();
    }

    void BarSettings() {
        // get the settings
        Render::BarSettings@ settings = Settings::UI::barSettings;

        dictionary settingsDict = {
            {"width", settings.width},
            {"height", settings.height},
            {"xPos", settings.xPos},
            {"yPos", settings.yPos},
            {"transparency", settings.transparency},
            {"backgroundColour", Serialise(settings.backgroundColour)},
            {"outlineColour", Serialise(settings.outlineColour)},
            {"lineColour", Serialise(settings.lineColour)},
            {"positiveColour", Serialise(settings.positiveColour)},
            {"negativeColour", Serialise(settings.negativeColour)},
            {"textColour", Serialise(settings.textColour)},
            {"cornerRounding", settings.cornerRounding},
            {"outlineThickness", settings.outlineThickness},
            {"lineThickness", settings.lineThickness},
            {"fontWidth", settings.fontWidth},
            {"maxPositiveGap", settings.maxPositiveGap},
            {"maxNegativeGap", settings.maxNegativeGap}
        };

        Json::Value settingsJson(settingsDict);

        // write the output to the barFile
        Json::ToFile(SaveLocations::UI::barFile.Path(), settingsJson);
    }

    void UI() {
        HandleFS();

        BarSettings();
    }

    void Performance() {
        HandleFS();
    }

    // just calls every thing else
    void All() {
        Base();
        UI();
        Performance();
    }
}

namespace LoadSettings {
    void Base() {
        HandleFS();
    }

    void BarSettings() {
        // get the settings
        Render::BarSettings@ settings = Settings::UI::barSettings;

        // get the json from the bar file
        Json::Value jsonSettings = Json::FromFile(SaveLocations::UI::barFile.Path());

        // TODO: continue loading from here
        auto tmp = settings;
        print("BarSettings.width: " + tostring(tmp.width)); /* position and size */
        print("BarSettings.height: " + tostring(tmp.height));
        print("BarSettings.xPos: " + tostring(tmp.xPos));
        print("BarSettings.yPos: " + tostring(tmp.yPos));
        print("BarSettings.transparency: " + tostring(tmp.transparency)); /* colour and transparency */
        print("BarSettings.backgroundColour: " + tostring(tmp.backgroundColour));
        print("BarSettings.outlineColour: " + tostring(tmp.outlineColour));
        print("BarSettings.lineColour: " + tostring(tmp.lineColour));
        print("BarSettings.positiveColour: " + tostring(tmp.positiveColour));
        print("BarSettings.negativeColour: " + tostring(tmp.negativeColour));
        print("BarSettings.textColour: " + tostring(tmp.textColour));
        print("BarSettings.cornerRounding: " + tostring(tmp.cornerRounding)); /* other style options */
        print("BarSettings.outlineThickness: " + tostring(tmp.outlineThickness));
        print("BarSettings.lineThickness: " + tostring(tmp.lineThickness));
        print("BarSettings.fontWidth: " + tostring(tmp.fontWidth)); /* the width of the font relative to half of the width of the bar */
        print("BarSettings.maxPositiveGap: " + tostring(tmp.maxPositiveGap)); /* both are in milliseconds (1.252s == 1252) */
        print("BarSettings.maxNegativeGap: " + tostring(tmp.maxNegativeGap)); /* in reference to -1.2s */
    }

    void UI() {
        HandleFS();
    }

    void Performance() {
        HandleFS();
    }

    // calls the other functions
    void All() {
        Base();
        UI();
        Performance();
    }
}