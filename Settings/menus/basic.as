[SettingsTab name="Basic" order="0"]
void BasicSettings() {
    // create a checkbox to say if the plugin is enabled
    Settings::General::pluginEnabled =
        UIX::Checkbox("Enable Plugin", Settings::General::pluginEnabled);

    // gets expectedFrameRate
    Settings::Performance::expectedFrameRate =
        UIX::InputInt("Frame Rate", Settings::Performance::expectedFrameRate, 10, 1500, 1);

    // checkbox for getGapOverride;
    Settings::Gap::getGapOverride =
        UIX::Checkbox("Show Gap While Logging", Settings::Gap::getGapOverride);

    // save toggle
    Settings::Save::enabled =
        UIX::Checkbox("Enable Saving", Settings::Save::enabled);
}