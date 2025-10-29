bool updateWindowSize = false;

vec2 GetScreenCentre() {
    int gameWidth = Draw::GetWidth();
    int gameHeight = Draw::GetHeight();

    return vec2(gameWidth / 2, gameHeight / 2);
}

float GetLineOffset(int gap, float maxGap, float totalWidth) {
    // get the current gap and calculate the length of the bar relative to the max
    int curGap = Math::Abs(gap);

    if (curGap > maxGap) {
        curGap = maxGap;
    }

    if (gap < 0) {
        return -1 * (totalWidth / 2) * float(curGap) / maxGap;
    }
    else {
        return (totalWidth / 2) * float(curGap) / maxGap;
    }
    
}

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
    // 1print(stringGap);

    return stringGap;
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
                int curGap = miscArray[i].gap;

                // includes "+" if greater than 0
                string curGapString = GapToString(curGap);

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

        const float transparency = 0.6;
        vec4 lineColour = vec4(1, 1, 1, transparency);
        const float thickness = 5;

        UI::DrawList @drawList = UI::GetForegroundDrawList();

        vec2 centrePos = GetScreenCentre();
        centrePos.y = centrePos.y / 4;

        vec2 topLeft = vec2(centrePos.x - (width / 2), centrePos.y - (height / 2));

        // top left pos, then the size
        // draw the outer bar
        drawList.AddRectFilled(vec4(topLeft.x, topLeft.y, width, height), vec4(0, 0, 0, transparency), 5);

        float minGap;
        float maxGap;

        // iterate miscArray to draw the largest bars only
        for (int i = 1; i < miscArray.Length; i++) {
            if (miscArray[i].id == 0) {
                break;
            }

            int curGap = miscArray[i].gap;

            if (i == 1) {
                minGap = curGap;
                maxGap = curGap;

                continue;
            }

            if (curGap < minGap) {
                minGap = curGap;
            }
            else if (curGap > maxGap) {
                maxGap = curGap;
            }
        }
        
        // DEBUG PRINT
        // print(minGap + " " + maxGap);

        float drawLength;

        // only draw min offset if actually negative
        if (minGap < 0) {
            drawLength = GetLineOffset(minGap, gapRange, width);
            drawList.AddRectFilled(vec4(centrePos.x - drawLength, centrePos.y - (height / 2), drawLength, height), vec4(0, 1, 0, transparency));

            string text = GapToString(minGap);

            // write the gap the side
            drawList.AddText(vec2(centrePos.x + (width / 2) - Draw::MeasureString(text).x, centrePos.y + (height / 2)), vec4(1, 1, 1, 1), text);
        }

        // only draw max offset if actually positive
        if (maxGap > 0) {
            drawLength = GetLineOffset(maxGap, gapRange, width);
            drawList.AddRectFilled(vec4(centrePos.x - drawLength, centrePos.y - (height / 2), drawLength, height), vec4(1, 0, 0, transparency));

            string text = GapToString(maxGap);

            // write the gap the side
            drawList.AddText(vec2(centrePos.x - (width / 2), centrePos.y + (height / 2)), vec4(1, 1, 1, 1), text);
        }

        // iterate miscArray to draw in each point that a car is gaining
        for (int i = 1; i < miscArray.Length; i++) {
            if (miscArray[i].id == 0) {
                break;
            }

            // draw a line per car
            drawLength = GetLineOffset(miscArray[i].gap, gapRange, width);
            drawList.AddLine(vec2(centrePos.x - drawLength, centrePos.y + (height / 2)), vec2(centrePos.x - drawLength, centrePos.y - (height / 2)), vec4(0, 0, 0, transparency), thickness / 2);
        }

        // draw the centre line
        drawList.AddLine(vec2(centrePos.x, centrePos.y + (height / 2)), vec2(centrePos.x, centrePos.y - (height / 2)), lineColour, thickness);

        // draw outer border
        drawList.AddRect(vec4(topLeft.x, topLeft.y, width, height), lineColour, 5, thickness);
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