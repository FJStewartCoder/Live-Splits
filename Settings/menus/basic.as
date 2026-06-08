[SettingsTab name="Basic" order="0"]
void BasicSettings() {
    // create a checkbox to say if the plugin is enabled
    Settings::General::pluginEnabled =
        UI::Checkbox("Enable Plugin", Settings::General::pluginEnabled);

    // gets expectedFrameRate
    Settings::Performance::expectedFrameRate =
        IntInput("Frame Rate", Settings::Performance::expectedFrameRate, 10, 1500, 1);

    // checkbox for getGapOverride;
    Settings::Gap::getGapOverride =
        UI::Checkbox("Show Gap While Logging", Settings::Gap::getGapOverride);

    // save toggle
    Settings::Save::enabled =
        UI::Checkbox("Enable Saving", Settings::Save::enabled);
}