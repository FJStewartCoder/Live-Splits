string IntToString(int val, int length) {
    string str = tostring(val);
    int curLength = str.Length;

    if (curLength < length) {
        string filler = "";

        for (int i = 0; i < length - curLength; i++) {
            filler += "0";
        }

        str = filler + str;
    }

    return str;
}

string GapToString(int gap) {
    // get + or minus
    // 0 is considered to be +0
    string symbol = (gap < 0) ? "-" : "+";

    // get absolute because we know the symbol
    gap = Math::Abs(gap);

    // get number of hours and remove from gap
    int hours = gap / (60 * 60 * 1000);
    gap -= (hours * (60 * 60 * 1000));

    // get minutes and remove number of milliseconds of this from gap
    int minutes = gap / (60 * 1000);
    gap -= (minutes * (60 * 1000));

    // get seconds and remove from gap
    int seconds = gap / 1000;
    gap -= (seconds * 1000);

    int milliseconds = gap;

    string stringGap = symbol;

    if (hours > 0) {
        stringGap += hours + ":" + IntToString(minutes, 2) + ":";
    }
    else if (minutes > 0) {
        stringGap += IntToString(minutes, 2) + ":";
    }

    stringGap += IntToString(seconds, 2) + "." + IntToString(milliseconds, 3);

    // DEBUG PRINT
    // print(stringGap);

    return stringGap;
}

void Render() {
    // if the plugin is off don't do anything
    if (!isEnabled) {
        return;
    }

    // if not in game, don't do anything
    if (!IsInGame()) { return; }

    if (EnabledStatus(0)) {
        Render::Normal();
    }
    
    if (EnabledStatus(1)) {
        Render::Bar();
    }

    if (EnabledStatus(2)) {
        Render::Debug();
    }
}

void RenderOptionsMenu() {
    if (UI::BeginMenu("Render")) {
        // variable to store the value if enabled or disabled
        bool enabled = EnabledStatus(0);

        // option for normal view
        if (UI::MenuItem("Table", "", enabled)) {
            SetEnabled(0, !enabled);
        }

        // set the enabled status
        enabled = EnabledStatus(1);
        // option for normal view
        if (UI::MenuItem("Bar", "", enabled)) {
            SetEnabled(1, !enabled);
        }

        // set the enabled status
        enabled = EnabledStatus(2);
        // option for normal view
        if (UI::MenuItem("Debug", "", enabled)) {
            SetEnabled(2, !enabled);
        }

        UI::EndMenu();
    }
}

void RenderMenu() {
    if (UI::BeginMenu("Live Splits")) {
        // toggle for on of off    
        if (UI::MenuItem("Enabled", "", isEnabled)) {
            isEnabled = !isEnabled;
        }

        // render the menu to render options
        RenderOptionsMenu();

        // toggle for gap override
        if (UI::MenuItem("Gap While Log", "", getGapOverride)) {
            getGapOverride = !getGapOverride;
        }

        UI::EndMenu();
    }
}