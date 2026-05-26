vec2 GetScreenCentre() {
    int gameWidth = Display::GetWidth();
    int gameHeight = Display::GetHeight();

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

vec2 CalculateCentreBarPosition(Render::BarSettings@ settings) {
    return vec2(Display::GetWidth() * settings.xPos, Display::GetHeight() * settings.yPos);
}

vec2 CalculateBarTopLeft(double width, double height, vec2 centrePos) {
    return vec2(centrePos.x - (width / 2), centrePos.y - (height / 2));
}

vec4 RGBToRGBA(vec3 colour, double transparency) {
    return vec4(colour.x, colour.y, colour.z, transparency);
}

namespace Render {
    class BarSettings {
        // position and size
        double width;
        double height;
        double xPos;
        double yPos;

        // colour and transparency
        double transparency;
        vec3 backgroundColour;
        vec3 outlineColour;
        vec3 lineColour;
        vec3 positiveColour;
        vec3 negativeColour;
        vec3 textColour;

        // other style options
        double cornerRounding;
        double outlineThickness;
        double lineThickness;


        void SetDefault() {
            width = 1/4;
            height = 1/16;
            xPos = 0.5;
            yPos = 0.3;

            transparency = 0.7;

            backgroundColour = vec3(0, 0, 0);
            outlineColour = vec3(0, 0, 0);
            lineColour = vec3(0, 0, 0);
            positiveColour = vec3(0, 1, 0);
            negativeColour = vec3(1, 0, 0);
            textColour = vec3(1, 1, 1);

            cornerRounding = 5;
            outlineThickness = width / 160;
            lineThickness = width / 320;
        }

        // TODO: implement
        bool IsValid() {
            return true;
        }

        BarSettings() {
            SetDefault();
        }
    }

    void Bar(
        Render::BarSettings settings
    ) {
        if (!settings.IsValid()) {
            settings.SetDefault();
        }

        // quarter screen width
        float width = Display::GetWidth() * settings.width;
        // 16th screen height
        float height = Display::GetHeight() * settings.height;

        vec2 centrePos = CalculateCentreBarPosition(settings);
        vec2 topLeft = CalculateBarTopLeft(width, height, centrePos);

        UI::DrawList @drawList = UI::GetForegroundDrawList();

        // top left pos, then the size
        // draw the outer bar
        drawList.AddRectFilled(
            vec4(topLeft.x, topLeft.y, width, height),
            RGBToRGBA(settings.backgroundColour, settings.transparency),
            settings.cornerRounding
        );

        float minGap = 0;
        float maxGap = 0;

        auto ghosts = gapMgr.ghostMgr.ghostsList;

        // iterate miscArray to draw the largest bars only
        for (int i = 0; i < ghosts.Length; i++) {
            int curGap = ghosts[i].gap;

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
            drawList.AddRectFilled(
                vec4(centrePos.x - drawLength, centrePos.y - (height / 2), drawLength, height), 
                RGBToRGBA(settings.positiveColour, settings.transparency)
            );

            string text = GapToString(minGap);

            // write the gap the side
            drawList.AddText(
                vec2(centrePos.x + (width / 2) - UI::MeasureString(text).x, centrePos.y + (height / 2)), 
                RGBToRGBA(settings.lineColour, settings.transparency),
                text
            );
        }

        // only draw max offset if actually positive
        if (maxGap > 0) {
            drawLength = GetLineOffset(maxGap, barGapRange, width);
            drawList.AddRectFilled(
                vec4(centrePos.x - drawLength, centrePos.y - (height / 2), drawLength, height), 
                RGBToRGBA(settings.negativeColour, settings.transparency)
            );

            string text = GapToString(maxGap);

            // write the gap the side
            drawList.AddText(
                vec2(centrePos.x - (width / 2), centrePos.y + (height / 2)),
                RGBToRGBA(settings.textColour, settings.transparency),
                text
            );
        }

        // iterate miscArray to draw in each point that a car is gaining
        for (int i = 0; i < ghosts.Length; i++) {
            int curGap = ghosts[i].gap;

            // draw a line per car
            drawLength = GetLineOffset(curGap, barGapRange, width);
            drawList.AddLine(
                vec2(centrePos.x - drawLength, centrePos.y + (height / 2)),
                vec2(centrePos.x - drawLength, centrePos.y - (height / 2)),
                RGBToRGBA(settings.lineColour, settings.transparency),
                settings.lineThickness
            );
        }

        // draw the centre line
        drawList.AddLine(
            vec2(centrePos.x, centrePos.y + (height / 2)),
            vec2(centrePos.x, centrePos.y - (height / 2)),
            RGBToRGBA(settings.lineColour, 1),
            settings.outlineThickness
        );

        // draw outer border
        drawList.AddRect(
            vec4(topLeft.x, topLeft.y, width, height),
            RGBToRGBA(settings.lineColour, 1),
            settings.cornerRounding,
            settings.outlineThickness
        );
    }
}
