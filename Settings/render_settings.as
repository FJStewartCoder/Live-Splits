bool EnabledStatus(int bit) {
    return ((enabledRenderingOptions >> bit) & 1) == 1;
}

void SetEnabled(int bit, bool val) {
    bool curVal = EnabledStatus(bit);

    // if not the same, needs to be flipped. So, xor
    if (curVal != val) {
        enabledRenderingOptions = enabledRenderingOptions ^ (1 << bit);
    }
}

// ----------------------------------------------------------------------

void TableSettings() {
    bool enabled = UI::Checkbox("Enabled", EnabledStatus(0));
    SetEnabled(0, enabled);

    // get each value using the settings function for this
    FONT_SIZE = IntInput("Font Size", FONT_SIZE, 1, 100);
    TEXT_SPACING = IntInput("Text Spacing", TEXT_SPACING, 1, 20);
    FRAME_PADDING = IntInput("Frame Padding", FRAME_PADDING, 1, 20);
}

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

void DebugSettings() {
    bool enabled = UI::Checkbox("Enabled", EnabledStatus(2));
    SetEnabled(2, enabled);
}

// -----------------------------------------------------------------------

[SettingsTab name="UI" order="2"]
void RenderSettings() {
    UI::BeginTabBar("RenderOptions");

    if (UI::BeginTabItem("Table")) {
        TableSettings();

        UI::EndTabItem();
    }

    if (UI::BeginTabItem("Bar")) {
        BarSettings();

        UI::EndTabItem();
    }

    if (UI::BeginTabItem("Debug")) {
        DebugSettings();

        UI::EndTabItem();
    }

    UI::EndTabBar();
}