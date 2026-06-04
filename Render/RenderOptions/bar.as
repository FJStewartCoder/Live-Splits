float GetLineOffset(
    int gap,
    uint maxGap,
    float totalWidth
) {
    // the width of half of the bar (because the gaps are only shown in half of the bar)
    float sectionWidth = totalWidth / 2;

    // get the absolute value of the gap as it is more convenient for calculations
    uint curGap = Math::Abs(gap);

    // if the current gap is greater max gap, the width is the full amount
    if (curGap > maxGap) { return sectionWidth; }

    // otherwise, calculate the percentage of bar filled as the current gap out of the max gap
    // this is multiplied with the section width
    return sectionWidth * (float(curGap) / maxGap);
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

double CalculateFontSizeForWidth(const string &in text, double desiredWidth, UI::Font@ font = null) {
    const double baseFontSize = 10.0;

    // calculate the base width using the base font size
    double baseWidth = UI::MeasureString(text, font, baseFontSize).x;

    // calculate the scale factor by calculating the division of the desired / base
    double scaleFactor = desiredWidth / baseWidth;

    // calculate the final font size by multiplying the scaleFactor by the baseFontSize
    return baseFontSize * scaleFactor;
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

        // the width of the font relative to half of the width of the bar
        double fontWidth;

        // the maximum gap that can be drawn on the bar before overflowing
        // both are in milliseconds (1.252s == 1252)
        int maxPositiveGap;  // in reference to -1.2s
        int maxNegativeGap;  // in reference to +1.2s


        void SetDefault() {
            width = 1.0 / 4;
            height = 1.0 / 16;
            xPos = 0.5;
            yPos = 0.3;

            transparency = 0.8;

            backgroundColour = vec3(0, 0, 0);
            outlineColour = vec3(1, 1, 1);
            lineColour = vec3(0, 0, 0);
            positiveColour = vec3(0, 1, 0);
            negativeColour = vec3(1, 0, 0);
            textColour = vec3(1, 1, 1);

            cornerRounding = 5;
            outlineThickness = 2;
            lineThickness = 1;

            fontWidth = 0.3;

            maxPositiveGap = 2000;
            maxNegativeGap = 2000;
        }

        // TODO: implement
        bool IsValid() {
            return true;
        }

        BarSettings() {
            SetDefault();
        }
    }

    void DrawGapLine(
        UI::DrawList@ drawList,
        int curGap,
        int barWidth, int barHeight,
        vec2 centre,
        Render::BarSettings@ settings
    ) {
        // is positive refers to being faster so gap is less than 0
        const bool isPositive = curGap < 0;
        
        int drawX;

        if (isPositive) {
            // get the x position of the line
            drawX = GetLineOffset(curGap, settings.maxPositiveGap, barWidth);
            // since it is a positive integer, convert it to negative to be correctly placed
            drawX *= -1;
        }
        else {
            // get the x pos
            drawX = GetLineOffset(curGap, settings.maxNegativeGap, barWidth);
        }

        // draw a line per car
        drawList.AddLine(
            vec2(centre.x - drawX, centre.y + (barHeight / 2)),
            vec2(centre.x - drawX, centre.y - (barHeight / 2)),
            RGBToRGBA(settings.lineColour, settings.transparency),
            settings.lineThickness
        );
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

        int minGap = 0;
        int maxGap = 0;

        auto ghosts = gapMgr.ghostGaps;

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

        float drawWidth;

        // only draw min offset if actually negative
        // this only draws the coloured section (it is more efficient to only do it once then draw the lines on top)
        if (minGap < 0) {
            // calculate the draw length
            drawWidth = GetLineOffset(minGap, settings.maxPositiveGap, width);

            // the min (positive (as in faster/improving/-1s) gap) is on the right side
            // so, draw from the middle line, to the right, by draw width
            drawList.AddRectFilled(
                vec4(
                    centrePos.x,
                    centrePos.y - (height / 2),
                    drawWidth,
                    height
                ), 
                RGBToRGBA(settings.positiveColour, settings.transparency)
            );

            string text = GapToString(minGap);

            double desiredTextWidth = (width / 2) * settings.fontWidth;
            double fontSize = CalculateFontSizeForWidth(text, desiredTextWidth);

            // write the gap on the right side of the bar
            drawList.AddText(
                vec2(centrePos.x + (width / 2) - desiredTextWidth, centrePos.y + (height / 2)), 
                RGBToRGBA(settings.textColour, settings.transparency),
                text,
                null,
                fontSize
            );
        }

        // only draw max offset if actually positive
        if (maxGap > 0) {
            // calculate the draw width
            drawWidth = GetLineOffset(maxGap, settings.maxNegativeGap, width);

            // the negative gap (you are slower) is on the left side
            // so draw from the centre line subtract the draw width, to the right, by draw width
            drawList.AddRectFilled(
                vec4(
                    centrePos.x - drawWidth,
                    centrePos.y - (height / 2),
                    drawWidth,
                    height
                ), 
                RGBToRGBA(settings.negativeColour, settings.transparency)
            );

            string text = GapToString(maxGap);

            double desiredTextWidth = (width / 2) * settings.fontWidth;
            double fontSize = CalculateFontSizeForWidth(text, desiredTextWidth);

            // write the gap on the left side of the bar
            drawList.AddText(
                vec2(centrePos.x - (width / 2), centrePos.y + (height / 2)),
                RGBToRGBA(settings.textColour, settings.transparency),
                text,
                null,
                fontSize
            );
        }

        // iterate miscArray to draw in each point that a car is gaining
        for (int i = 0; i < ghosts.Length; i++) {
            int curGap = ghosts[i].gap;
            DrawGapLine(
                drawList,
                curGap,
                width, height,
                centrePos,
                settings
            );
        }

        // draw the centre line
        drawList.AddLine(
            vec2(centrePos.x, centrePos.y + (height / 2)),
            vec2(centrePos.x, centrePos.y - (height / 2)),
            RGBToRGBA(settings.outlineColour, settings.transparency),
            settings.outlineThickness
        );

        // draw outer border
        drawList.AddRect(
            vec4(topLeft.x, topLeft.y, width, height),
            RGBToRGBA(settings.outlineColour, settings.transparency),
            settings.cornerRounding,
            settings.outlineThickness
        );
    }
}
