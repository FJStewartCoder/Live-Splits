bool updateWindowSize = false;

vec2 GetScreenCentre() {
    int gameWidth = Draw::GetWidth();
    int gameHeight = Draw::GetHeight();

    return vec2(gameWidth / 2, gameHeight / 2);
}

namespace Render {
    void Normal() {
        // gets the number of valid cars
        int validCars;

        for (validCars = 1; validCars < numCars; validCars++) {
            if (miscArray[validCars].id == 0) {
                break;
            }
        }

        // --------------------------------------------------------
        // styling

        if (updateWindowSize) {
            int height = (FONT_SIZE * (validCars - 1)) + (TEXT_SPACING * (validCars - 2)) + (FRAME_PADDING * 2);

            // get the string width of placeholder amount using this function
            vec2 textSize = Draw::MeasureString("+99.999", null, FONT_SIZE);
            int width = textSize.x + (FRAME_PADDING * 2);

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
            // show gaps for all cars except the current car
            for (int i = 1; i < validCars; i++) {
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
        if (UI::Begin("Debug Menu")) {
            // ONLY FOR DEBUGGING
            UI::InputInt("LOG", currentLogIndex);
            UI::InputInt("TIME", GetApp().TimeSinceInitMs - startTime);
            UI::InputInt("SIZE", ghostPoints.Length);
            UI::Checkbox("COMPLETE", arrayComplete);

            for (int i = 0; i < miscArray.Length; i++) {
                UI::PushID(i);

                UI::SeparatorText("");

                UI::InputInt("ID", miscArray[i].id);
                UI::InputInt("GAP", miscArray[i].gap);
                UI::InputInt("REL GAP", miscArray[i].relGap);
                UI::InputInt("LAST IDX", miscArray[i].lastIdx);

                UI::PopID();
            }
        }
        UI::End();
    }

    void Bar() {
        // the maximum gap each side the bar will accept
        const float gapRange = 4000;  // 4 seconds in milliseconds

        const float width = 400;
        const float height = 100;

        UI::DrawList @drawList = UI::GetForegroundDrawList();

        vec2 screenCentre = GetScreenCentre();

        vec2 topLeft = vec2(screenCentre.x - (width / 2), screenCentre.y - (height / 2));

        // top left pos, then the size
        // draw the outer bar
        drawList.AddRectFilled(vec4(topLeft.x, topLeft.y, width, height), vec4(1, 1, 1, 0.3));

        // draw the centre line
        drawList.AddLine(vec2(screenCentre.x, screenCentre.y + (height / 2)), vec2(screenCentre.x, screenCentre.y - (height / 2)), vec4(0, 0, 0, 1), 2);

        // iterate miscArray
        for (int i = 1; i < miscArray.Length; i++) {
            if (miscArray[i].id == 0) {
                break;
            }

            // get the current gap and calculate the length of the bar relative to the max
            int curGap = Math::Abs(miscArray[i].gap);

            if (curGap > gapRange) {
                curGap = gapRange;
            }

            float relativeLength = float(curGap) / gapRange;

            float lineOffset = (width / 2) * relativeLength;

            if (miscArray[i].gap < 0) {
                // draw line after the middle
                drawList.AddLine(vec2(screenCentre.x + lineOffset, screenCentre.y + (height / 2)), vec2(screenCentre.x + lineOffset, screenCentre.y - (height / 2)), vec4(0, 1, 0, 1), 5);
            }
            else {
                // draw line before middle
                drawList.AddLine(vec2(screenCentre.x - lineOffset, screenCentre.y + (height / 2)), vec2(screenCentre.x - lineOffset, screenCentre.y - (height / 2)), vec4(1, 0, 0, 1), 5);  
            }
        }
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
    // Render::Debug();
    Render::Bar();
}