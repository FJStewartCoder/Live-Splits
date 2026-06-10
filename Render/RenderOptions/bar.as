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
    // 99 hours, 59 minutes, 59 seconds, 999 millis
    const string TEST_TEXT = "+99:59:59.999";

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

            fontWidth = 0.4;

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

    enum BarSide {
        RIGHT,
        LEFT,
        CENTRE
    }

    void DrawBarText(
        const string&in text,
        BarSettings@ settings,
        UI::DrawList@ drawList,
        float fontSize,
        float width, float height,
        vec2 centrePos,
        BarSide side
    ) {
        // the final position of the text
        vec2 textPos;
        float textWidth = UI::MeasureString(text, null, fontSize).x;

        switch (side) {
            case BarSide::RIGHT:
                textPos = vec2(centrePos.x + (width / 2) - textWidth, centrePos.y + (height / 2));
                break;
            case BarSide::LEFT:
                textPos = vec2(centrePos.x - (width / 2), centrePos.y + (height / 2));
                break;
            case BarSide::CENTRE:
                textPos = vec2(centrePos.x - (textWidth / 2), centrePos.y + (height / 2));
                break;
        }

        // write the gap on the right side of the bar
        drawList.AddText(
            textPos,
            RGBToRGBA(settings.textColour, settings.transparency),
            text,
            null,
            fontSize
        );
    }

    // draws the inner data of the bar
    void DrawBarData(
        UI::DrawList@ drawList,
        float fontSize,
        BarSettings@ settings,
        array<int>@ data,
        float width, float height,
        vec2 centrePos
    ) {
        // calculate the min and max values
        MinMax minMax = GetMinMax(data);

        int minGap = minMax.min;
        int maxGap = minMax.max;
        
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
        }

        // iterate miscArray to draw in each point that a car is gaining
        for (int i = 0; i < data.Length; i++) {
            int curGap = data[i];

            DrawGapLine(
                drawList,
                curGap,
                width, height,
                centrePos,
                settings
            );
        }
    }

    void Bar(
        Render::BarSettings@ settings
    ) {
        if (!settings.IsValid()) {
            settings.SetDefault();
        }

        // quarter screen width
        float width = Display::GetWidth() * settings.width;
        // 16th screen height
        float height = Display::GetHeight() * settings.height;

        // calculate the desired text width and font size using the test text 
        double desiredTextWidth = (width / 2) * settings.fontWidth;
        double fontSize = CalculateFontSizeForWidth(TEST_TEXT, desiredTextWidth);

        vec2 centrePos = CalculateCentreBarPosition(settings);
        vec2 topLeft = CalculateBarTopLeft(width, height, centrePos);

        UI::DrawList @drawList = UI::GetBackgroundDrawList();

        // top left pos, then the size
        // draw the outer bar
        drawList.AddRectFilled(
            vec4(topLeft.x, topLeft.y, width, height),
            RGBToRGBA(settings.backgroundColour, settings.transparency),
            settings.cornerRounding
        );

        auto ghosts = gapMgr.ghostGaps;

        // create arrays for the data to be drawn
        array<int> ghostGaps;
        array<int> ghostRates;

        // reserve space 
        ghostGaps.Reserve(ghosts.Length);
        ghostRates.Reserve(ghosts.Length);

        // populate the lists
        for (uint i = 0; i < ghosts.Length; i++) {
            ghostGaps.InsertLast(ghosts[i].gap.GetGap());
            ghostRates.InsertLast(ghosts[i].gap.GapRate());
        }

        // calculate a new height and centre for the gaps
        float gapsHeight = height * 0.65;
        // the y pos needs to be the centre of the bar
        // so, we can take the centre and sub half of the height to get the top of the bar
        // then we need to go down by half of the new bar width to get the centre
        vec2 gapsCentre(centrePos.x, (centrePos.y - (height / 2)) + (gapsHeight / 2));

        DrawBarData(
            drawList,
            fontSize,
            settings,
            ghostGaps,
            width, gapsHeight,
            gapsCentre
        );

        // calculate a new height and centre for the rates
        float rateHeight = height - gapsHeight;
        // to get this y pos, we need the centre again but based on two heights this time
        // take the centre pos of the previous bar and go down by half of its height to get the bottom of that bar
        // then, go down another half of this bar's height to get this centre
        vec2 rateCentre(centrePos.x, gapsCentre.y + (gapsHeight / 2) + (rateHeight / 2));

        DrawBarData(
            drawList,
            fontSize,
            settings,
            ghostRates,
            width, rateHeight,
            rateCentre
        );

        MinMax gapsMinMax = GetMinMax(ghostGaps);

        // draw the text for both the min and max gap

        // only draw the min gap if it is less than 0
        if (gapsMinMax.min < 0) {
            string text = GapToString(gapsMinMax.min);
            DrawBarText(text, settings, drawList, fontSize, width, height, centrePos, BarSide::RIGHT);
        }

        if (gapsMinMax.max > 0) {
            // draw the text for the max gap
            string text = GapToString(gapsMinMax.max);
            DrawBarText(text, settings, drawList, fontSize, width, height, centrePos, BarSide::LEFT);
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
