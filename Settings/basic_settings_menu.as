// used to calculate each setting's performance degree
uint expectedFrameRate = 60;

// ON OR OFF
// PERFORMANCE MODE
// SHOW GAP WHILE LOGGING

[SettingsTab name="Main" order="0"]
void BasicSettings() {
    // create a checkbox to say if the plugin is enabled
    isEnabled = UI::Checkbox("Enable Plugin", isEnabled);

    // --------------------------------------------------------------------
    // framesBetweenGap

    // reuses value
    int value = IntInput("Frames Between Getting Gap", framesBetweenGap.GetCount(), 1, 500, 1);
    // set both the stored value and the actual value to the same number to preserve sync
    SetGapValue(value);

    UI::Separator();
    AllSettings();
}