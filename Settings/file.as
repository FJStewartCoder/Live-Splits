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

    void UI() {
        HandleFS();
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