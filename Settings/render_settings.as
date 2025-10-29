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
}

void DebugSettings() {
    bool enabled = UI::Checkbox("Enabled", EnabledStatus(2));
    SetEnabled(2, enabled);
}

// -----------------------------------------------------------------------

[SettingsTab name="UI"]
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