bool EnabledStatus(int bit) {
    return ((Settings::UI::enabledRenderingOptions >> bit) & 1) == 1;
}

void SetEnabled(int bit, bool val) {
    bool curVal = EnabledStatus(bit);

    // if not the same, needs to be flipped. So, xor
    if (curVal != val) {
        Settings::UI::enabledRenderingOptions ^= (1 << bit);
    }
}

// ----------------------------------------------------------------------

void TableSectionSettings(const string&in sectionName, Render::NormalSectionSettings@ settings) {
    settings.width = RelativeWidth(sectionName + " Width", settings.width);

    const int fullWidth = settings.width * Display::GetWidth();
    settings.padding = IntInput(sectionName + " Padding", settings.padding, 0, int(fullWidth / 2));

    // print("NormalSectionSettings.textAlignment: " + tostring(tmp.textAlignment));

    // print("NormalSectionSettings.backgroundColour: " + tostring(tmp.backgroundColour));
    // print("NormalSectionSettings.textColour: " + tostring(tmp.textColour));

}

void TableSettings() {
    Render::NormalSettings@ settings = Settings::UI::normalSettings;

    bool enabled = UI::Checkbox("Enabled", EnabledStatus(0));
    SetEnabled(0, enabled);

    UI::Separator();  // -----------------------------------------------------------------

    settings.positionEnabled = UI::Checkbox("Position Enabled", settings.positionEnabled);
    TableSectionSettings("Position", settings.positionSettings);

    UI::Separator();  // -----------------------------------------------------------------

    settings.nameEnabled = UI::Checkbox("Name Enabled", settings.nameEnabled);
    TableSectionSettings("Name", settings.nameSettings);

    UI::Separator();  // -----------------------------------------------------------------

    settings.gapEnabled = UI::Checkbox("Gap Enabled", settings.gapEnabled);
    TableSectionSettings("Gap", settings.gapSettings);

    UI::Separator();  // -----------------------------------------------------------------

    settings.rateEnabled = UI::Checkbox("Gap Rate Enabled", settings.rateEnabled);
    TableSectionSettings("Gap Rate", settings.rateSettings);

    UI::Separator();  // -----------------------------------------------------------------

    settings.position.x = RelativeWidth("X Position", settings.position.x);
    settings.position.y = RelativeHeight("Y Position", settings.position.y);

    UI::Separator();  // -----------------------------------------------------------------

    settings.summary = UI::Checkbox("Enable Summary", settings.summary);

    // only render this if we want a summary
    if (settings.summary) {
        settings.numCarsInSummary = IntInput("Max Cars In Summary", settings.numCarsInSummary, 0, 1000);
    }

    UI::Separator();  // -----------------------------------------------------------------

    settings.sectionHeight = RelativeHeight("Section Height", settings.sectionHeight);
    settings.playerSectionYMargin = RelativeHeight("Player Y Margin", settings.playerSectionYMargin);

    UI::Separator();  // -----------------------------------------------------------------

    settings.neutralColour = UI::InputColor4("Neutral Gap Colour", settings.neutralColour);
    settings.positiveColour = UI::InputColor4("Positive Gap Colour", settings.positiveColour);
    settings.negativeColour = UI::InputColor4("Negative Gap Colour", settings.negativeColour);
}

/*
void BarSettings() {
    bool enabled = UI::Checkbox("Enabled", EnabledStatus(1));
    SetEnabled(1, enabled);

    // set the bar transparency
    // get from scale of 0 to 100 then scale down to 0 to 1
    int trans = UI::SliderInt("Opacity", barTransparency * 100, 0, 100, "%d%%");
    barTransparency = float(trans) / 100;

    // quick validation
    if (barTransparency < 0) { barTransparency = 0; }
    else if (barTransparency > 1) { barTransparency = 1; }

    // 0.2s to 240s
    float temp = FloatInput("Gap Range", barGapRange / 1000, 0.2, 240, 0.1, 1, "%.2fs");
    // convert from seconds to milliseconds
    barGapRange = temp * 1000;

    UI::Separator();  // ------------------------------------------------------------------------------------

    // the min and max don't really matter because the ensure function will sort it
    xOffset = IntInput("X Offset", xOffset, -10000, 10000, 5);
    yOffset = IntInput("Y Offset", yOffset, -10000, 10000, 5);
}
*/

void DebugSettings() {
    bool enabled = UI::Checkbox("Enabled", EnabledStatus(2));
    SetEnabled(2, enabled);
}

// ------------------------------------------------------------------------------------

[SettingsTab name="UI" order="2"]
void RenderSettings() {
    UI::BeginTabBar("RenderOptions");

    if (UI::BeginTabItem("Table")) {
        TableSettings();

        UI::EndTabItem();
    }

    if (UI::BeginTabItem("Bar")) {
        // BarSettings();

        UI::EndTabItem();
    }

    if (UI::BeginTabItem("Debug")) {
        DebugSettings();

        UI::EndTabItem();
    }

    UI::EndTabBar();
}