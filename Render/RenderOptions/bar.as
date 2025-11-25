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

vec2 CalculateMaxOffsets(float barWidth, float barHeight) {
    int width = Draw::GetWidth();
    int height = Draw::GetHeight();

    return vec2((width - barWidth) / 2, (height - barHeight) / 2);
}

// ensures offsets are valid
void EnsureOffsets(float width, float height) {
    vec2 maxOffsets = CalculateMaxOffsets(width, height);

    // basic validation for x and y offset
    if (xOffset > maxOffsets.x) { xOffset = maxOffsets.x; }
    else if (xOffset < -1 * maxOffsets.x) { xOffset = -1 * maxOffsets.x; }

    if (yOffset > maxOffsets.y) { yOffset = maxOffsets.y; }
    else if (yOffset < -1 * maxOffsets.y) { yOffset = -1 * maxOffsets.y; }
}

namespace Render {
    void Bar() {
        // quarter screen width
        float width = Draw::GetWidth() / 4;
        // 16th screen height
        float height = Draw::GetHeight() / 16;

        // ensure the offsets
        EnsureOffsets(width, height);

        vec4 lineColour = vec4(1, 1, 1, barTransparency);
        float thickness = width / 160;

        const float rounding = 5;

        UI::DrawList @drawList = UI::GetForegroundDrawList();

        // get the centre of the screen
        vec2 centrePos = GetScreenCentre();

        // offset the centre pos by the x and y offsets
        centrePos.x += xOffset;
        centrePos.y -= yOffset;

        vec2 topLeft = vec2(centrePos.x - (width / 2), centrePos.y - (height / 2));

        // top left pos, then the size
        // draw the outer bar
        drawList.AddRectFilled(vec4(topLeft.x, topLeft.y, width, height), vec4(0, 0, 0, barTransparency), rounding);

        float minGap;
        float maxGap;

        // iterate miscArray to draw the largest bars only
        for (int i = 0; i < miscArray.Length - 1; i++) {
            if (miscArray[i].id == 0) {
                break;
            }

            int curGap = miscArray[i].gap;

            if (i == 0) {
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
            drawLength = GetLineOffset(minGap, barGapRange, width);
            drawList.AddRectFilled(vec4(centrePos.x - drawLength, centrePos.y - (height / 2), drawLength, height), vec4(0, 1, 0, barTransparency));

            string text = GapToString(minGap);

            // write the gap the side
            drawList.AddText(vec2(centrePos.x + (width / 2) - Draw::MeasureString(text).x, centrePos.y + (height / 2)), vec4(1, 1, 1, barTransparency), text);
        }

        // only draw max offset if actually positive
        if (maxGap > 0) {
            drawLength = GetLineOffset(maxGap, barGapRange, width);
            drawList.AddRectFilled(vec4(centrePos.x - drawLength, centrePos.y - (height / 2), drawLength, height), vec4(1, 0, 0, barTransparency));

            string text = GapToString(maxGap);

            // write the gap the side
            drawList.AddText(vec2(centrePos.x - (width / 2), centrePos.y + (height / 2)), vec4(1, 1, 1, barTransparency), text);
        }

        // iterate miscArray to draw in each point that a car is gaining
        for (int i = 0; i < miscArray.Length - 1; i++) {
            if (miscArray[i].id == 0) {
                break;
            }

            // draw a line per car
            drawLength = GetLineOffset(miscArray[i].gap, barGapRange, width);
            drawList.AddLine(vec2(centrePos.x - drawLength, centrePos.y + (height / 2)), vec2(centrePos.x - drawLength, centrePos.y - (height / 2)), vec4(0, 0, 0, barTransparency), thickness / 2);
        }

        // draw the centre line
        drawList.AddLine(vec2(centrePos.x, centrePos.y + (height / 2)), vec2(centrePos.x, centrePos.y - (height / 2)), lineColour, thickness);

        // draw outer border
        drawList.AddRect(vec4(topLeft.x, topLeft.y, width, height), lineColour, rounding, thickness);
    }
}
