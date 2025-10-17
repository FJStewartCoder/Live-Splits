bool updateWindowSize = false;

namespace Render {
    void Normal() {
        // gets the number of valid cars
        int validCars;

        for (validCars = 0; validCars < numCars; validCars++) {
            if (miscArray[validCars].id == 0) {
                break;
            }
        }

        // --------------------------------------------------------
        // styling

        if (updateWindowSize) {
            int height = (FONT_SIZE * validCars) + (TEXT_SPACING * (validCars - 1)) + (FRAME_PADDING * 2);
            int width = FONT_SIZE * 6;

            // set window height
            // UI::Cond:Always always updates the height
            UI::SetNextWindowSize(width, height, UI::Cond::Always);

            updateWindowSize = false;
        }

        // set font size
        UI::PushFontSize(FONT_SIZE);
        // set item spacing
        UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(TEXT_SPACING, TEXT_SPACING));
        // set item spacing
        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(FRAME_PADDING, FRAME_PADDING));

        // --------------------------------------------------------

        // set flags
        auto flags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoDecoration;

        // creates window
        if (UI::Begin("Live Splits", flags)) {
            for (int i = 0; i < validCars; i++) {
                float curGap = miscArray[i].gap / 1000.0;
                // includes "+" if greater than 0
                string curGapString = ((curGap > 0)? "+" : "") + tostring(curGap);

                UI::PushID(i);

                // change colour based on success
                if (curGap > 0) {
                    // slower
                    UI::PushStyleColor(UI::Col::Text, vec4(1, 0, 0, 1));
                }
                else if (curGap < 0) {
                    // faster
                    UI::PushStyleColor(UI::Col::Text, vec4(0 , 1, 0, 1));
                }
                else {
                    // equal
                    UI::PushStyleColor(UI::Col::Text, vec4(1, 1, 1, 1));
                }

                // display text
                UI::Text(curGapString);
                
                UI::PopStyleColor();
                UI::PopID();
            }
        }
        UI::End();

        // pop style
        UI::PopStyleVar(2);
        UI::PopFontSize();
    }

    void Debug() {
        // creates window
        if (UI::Begin("Live Splits", flags)) {
            // ONLY FOR DEBUGGING
            UI::InputInt("LOG", currentLogIndex);
            UI::InputInt("TIME", GetApp().TimeSinceInitMs - startTime);

            for (int i = 0; i < numCars; i++) {
                UI::PushID(i);

                UI::InputInt("ID", miscArray[i].id);
                UI::InputInt("SIZE", miscArray[i].arraySize);
                UI::InputInt("ACTUAL SIZE", ghostPoints[i].Length);
                UI::Checkbox("COMPLETE", miscArray[i].isArrayComplete);

                UI::PopID();
            }
        }
        UI::End();
    }
}

void Render() {
    // if the plugin is off don't do anything
    if (!isEnabled) {
        return;
    }

    ISceneVis@ scene = GetApp().GameScene;

    // ensures the player is in a race
    if (scene is null) {
        return;
    }

    Render::Normal();
}