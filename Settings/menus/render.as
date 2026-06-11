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

const string TextAlignmentToString(Render::TextAlignment alignment) {
    string res;

    switch (alignment) {
        case Render::TextAlignment::LEFT:
            res = "Left";
            break;
        case Render::TextAlignment::CENTRE:
            res = "Centre";
            break;
        case Render::TextAlignment::RIGHT:
            res = "Right";
            break;
    }

    return res;
}

void TableSectionSettings(const string&in sectionName, Render::NormalSectionSettings@ settings) {
    settings.width = UIX::RelativeWidth(sectionName + " Width", settings.width);

    const int fullWidth = settings.width * Display::GetWidth();
    settings.padding = UIX::InputInt(sectionName + " Padding", settings.padding, 0, int(fullWidth / 2));

    // text alignment settings below
    const string textAlignmentString = TextAlignmentToString(settings.textAlignment);

    if (UI::BeginCombo(sectionName + " Text Alignment", textAlignmentString)) {
        const Render::TextAlignment[] options = {
            Render::TextAlignment::LEFT,
            Render::TextAlignment::RIGHT,
            Render::TextAlignment::CENTRE
        };

        for (uint i = 0; i < options.Length; i++) {
            const Render::TextAlignment option = options[i];
            const string optionString = TextAlignmentToString(option);

            const bool isSelected = settings.textAlignment == option;

            if (UI::Selectable(optionString, isSelected)) {
                settings.textAlignment = option;
            }
        }

        UI::EndCombo();
    }

    // colour related settings
    settings.backgroundColour = UIX::InputColor4("Background Colour", settings.backgroundColour);
    settings.textColour = UIX::InputColor4("Text Colour", settings.textColour);
}

void TableSettings() {
    Render::NormalSettings@ settings = Settings::UI::normalSettings;

    UI::BeginTabBar("TableSettingsBar");

    // tab section for the basic general settings
    if (UI::BeginTabItem("General")) {
        bool enabled = UIX::Checkbox("Enabled", EnabledStatus(0));
        SetEnabled(0, enabled);

        UI::Separator();  // -----------------------------------------------------------------

        settings.position.x = UIX::RelativeWidth("X Position", settings.position.x);
        settings.position.y = UIX::RelativeHeight("Y Position", settings.position.y);

        UI::Separator();  // -----------------------------------------------------------------

        settings.summary = UIX::Checkbox("Enable Summary", settings.summary);

        // only render this if we want a summary
        if (settings.summary) {
            settings.numCarsInSummary = UIX::InputInt("Max Cars In Summary", settings.numCarsInSummary, 0, 1000);
        }

        UI::Separator();  // -----------------------------------------------------------------

        settings.neutralColour = UIX::InputColor4("Neutral Gap Colour", settings.neutralColour);
        settings.positiveColour = UIX::InputColor4("Positive Gap Colour", settings.positiveColour);
        settings.negativeColour = UIX::InputColor4("Negative Gap Colour", settings.negativeColour);

        UI::EndTabItem();
    }

    // tab item for the sections
    if (UI::BeginTabItem("Sections")) {
        settings.sectionHeight = UIX::RelativeHeight("Section Height", settings.sectionHeight);
        settings.playerSectionYMargin = UIX::RelativeHeight("Player Y Margin", settings.playerSectionYMargin);

        UI::Separator();  // -----------------------------------------------------------------

        UI::PushID(0);
        settings.positionEnabled = UIX::Checkbox("Position Enabled", settings.positionEnabled);

        // only render the section if it is enabled
        if (settings.positionEnabled) {
            TableSectionSettings("Position", settings.positionSettings);
        }

        UI::PopID();

        UI::Separator();  // -----------------------------------------------------------------

        UI::PushID(1);
        settings.nameEnabled = UIX::Checkbox("Name Enabled", settings.nameEnabled);

        // only render the section if it is enabled
        if (settings.nameEnabled) {
            TableSectionSettings("Name", settings.nameSettings);
        }

        UI::PopID();

        UI::Separator();  // -----------------------------------------------------------------

        UI::PushID(2);
        settings.gapEnabled = UIX::Checkbox("Gap Enabled", settings.gapEnabled);

        // only render the section if it is enabled
        if (settings.gapEnabled) {
            TableSectionSettings("Gap", settings.gapSettings);
        }

        UI::PopID();

        UI::Separator();  // -----------------------------------------------------------------

        UI::PushID(3);
        settings.rateEnabled = UIX::Checkbox("Gap Rate Enabled", settings.rateEnabled);

        // only render the section if it is enabled
        if (settings.rateEnabled) {
            TableSectionSettings("Gap Rate", settings.rateSettings);
        }

        UI::PopID();

        UI::EndTabItem();
    }

    UI::EndTabBar();
}

void BarSettings() {
    Render::BarSettings@ settings = Settings::UI::barSettings;

    bool enabled = UIX::Checkbox("Enabled", EnabledStatus(1));
    SetEnabled(1, enabled);

    UI::Separator();  // -----------------------------------------------------------------

    settings.width = UIX::RelativeWidth("Width", settings.width);
    settings.height = UIX::RelativeHeight("Height", settings.height);

    settings.xPos = UIX::RelativeWidth("X Position", settings.xPos);
    settings.yPos = UIX::RelativeHeight("Y Position", settings.yPos);

    UI::Separator();  // -----------------------------------------------------------------

    settings.backgroundColour = UIX::InputColor3("Background Colour", settings.backgroundColour);
    settings.outlineColour = UIX::InputColor3("Outline Colour", settings.outlineColour);
    settings.lineColour = UIX::InputColor3("Line Colour", settings.lineColour);
    settings.positiveColour = UIX::InputColor3("Positive Colour", settings.positiveColour);
    settings.negativeColour = UIX::InputColor3("Negative Colour", settings.negativeColour);
    settings.textColour = UIX::InputColor3("Text Colour", settings.textColour);

    // transparency needs to be first converted to be out of 100
    double transparency = settings.transparency * 100;
    transparency = UI::SliderDouble("Transparency", transparency, 0, 100, "%.1f%%");
    settings.transparency = transparency / 100;

    UI::Separator();  // -----------------------------------------------------------------

    settings.cornerRounding = UIX::InputInt("Corner Rounding", settings.cornerRounding, 0, 10000);

    settings.outlineThickness = UIX::InputFloat("Outline Thickness", settings.outlineThickness, 0, 1000, 1, 2, "%.0f");
    settings.lineThickness = UIX::InputFloat("Line Thickness", settings.lineThickness, 0, 1000, 1, 2, "%.0f");

    double fontSize = settings.fontWidth * 100;
    fontSize = UI::SliderDouble("Font Size", fontSize, 0, 100, "%.1f%%");
    settings.fontWidth = fontSize / 100;

    UI::Separator();  // -----------------------------------------------------------------

    double maxPositiveGap = double(settings.maxPositiveGap) / 1000;
    double maxNegativeGap = double(settings.maxNegativeGap) / 1000;

    // max gap is 10 hours because 60 * 60 == 1 hour * 10 = 10 hours
    maxPositiveGap = UIX::InputFloat("Max Positive Gap", maxPositiveGap, 0.001, 36000.0, 0.25, 1, "%.3fs");
    maxNegativeGap = UIX::InputFloat("Max Negative Gap", maxNegativeGap, 0.001, 36000.0, 0.25, 1, "%.3fs");

    // update the values to be the correct format
    settings.maxPositiveGap = maxPositiveGap * 1000;
    settings.maxNegativeGap = maxNegativeGap * 1000;
}

void DebugSettings() {
    bool enabled = UIX::Checkbox("Enabled", EnabledStatus(2));
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
        BarSettings();

        UI::EndTabItem();
    }

    if (UI::BeginTabItem("Debug")) {
        DebugSettings();

        UI::EndTabItem();
    }

    UI::EndTabBar();
}