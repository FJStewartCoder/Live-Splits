bool updateWindowSize = false;

namespace Render {
    enum TextAlignment {
        LEFT,
        RIGHT,
        CENTRE
    }
    
    // TODO: implement text colour
    // TODO: implement background colour
    class NormalSectionSettings {
        float width;

        float padding;

        TextAlignment textAlignment;


        const bool isValid() {
            // TODO: implement
            return true;
        }

        void SetDefaults() {
            width = 40;

            padding = 2;

            textAlignment = TextAlignment::LEFT;
        }

        NormalSectionSettings() {
            SetDefaults();
        }
    }

    // TODO: implement position and scale regardless of resolution
    class NormalSettings {
        bool summary;

        NormalSectionSettings positionSettings;
        bool positionEnabled;

        NormalSectionSettings nameSettings;
        bool nameEnabled;

        NormalSectionSettings gapSettings;
        bool gapEnabled;

        NormalSectionSettings rateSettings;
        bool rateEnabled;

        float sectionHeight;

        const bool isValid() {
            // TODO: implement
            return true;
        }

        void SetDefaults() {
            summary = false;

            positionSettings.width = 30;
            positionSettings.textAlignment = TextAlignment::CENTRE;
            positionEnabled = true;

            nameSettings.width = 100;
            nameEnabled = true;

            gapSettings.width = 60;
            gapSettings.textAlignment = TextAlignment::CENTRE;
            gapEnabled = true;

            rateSettings.width = 60;
            rateSettings.textAlignment = TextAlignment::CENTRE;
            rateEnabled = true;

            sectionHeight = 20;
        }

        NormalSettings() {
            SetDefaults();
        }
    }

    void NormalSection(
        const string&in text,
        const float height,
        const vec2 topLeftPos,
        NormalSectionSettings@ settings
    ) {
        UI::DrawList@ drawList = UI::GetForegroundDrawList();

        // re-assignment since it is quicker to type
        const float padding = settings.padding;

        const float widthForText = settings.width - (padding * 2);
        // this is equivalent to the font size (font size is character height)
        const float heightForText = height - (padding * 2);

        // set the font size
        float fontSize = heightForText;

        // if there is not enough space for the text, return
        if (widthForText <= 0) { return; }
        if (heightForText <= 0) { return; }

        // draw the background box
        drawList.AddRectFilled(
            vec4(topLeftPos.x, topLeftPos.y, settings.width, height),
            vec4(0, 0, 0, 0.5)
        );

        // measure the text to ensure that it fits
        vec2 textMeasurements = UI::MeasureString(text, null, fontSize);

        // height and width measurements used for positioning
        float textWidth = textMeasurements.x;
        float textHeight = textMeasurements.y;

        // if the text is too large, size down the text to fit in the width
        if (textWidth > widthForText) {
            fontSize = CalculateFontSizeForWidth(text, widthForText);

            // re-calculate the text width and height
            textWidth = widthForText;
            textHeight = fontSize;
        }

        // the x position of the text
        float xPos;

        switch (settings.textAlignment) {
            case (TextAlignment::LEFT):
                xPos = topLeftPos.x + padding;
                break;
            case (TextAlignment::RIGHT):
                // width for - width gives the spare space
                xPos = topLeftPos.x + padding + (widthForText - textWidth);
                break;
            case (TextAlignment::CENTRE):
                // same as above but half of spare space
                xPos = topLeftPos.x + padding + ((widthForText - textWidth) / 2);
                break;
        }

        // draw the text
        drawList.AddText(
            // y pos is top left + half height == centre then - textHeight / 2 to centre vertically
            vec2(
                xPos,
                (topLeftPos.y + (height / 2)) - (textHeight / 2)
            ),
            vec4(1, 1, 1, 1),
            text,
            null,
            fontSize
        );
    }

    void NormalDrawEntry(
        const int racePosition,
        const string&in name,
        const int gap,
        const int gapRate,
        const vec2 topLeftPos,
        NormalSettings@ settings
    ) {
        const float height = settings.sectionHeight;

        float cumulativeX = topLeftPos.x;

        // draw the position section and accumulate the x pos
        NormalSection(
            tostring(racePosition),
            height,
            vec2(cumulativeX, topLeftPos.y),
            settings.positionSettings
        );
        cumulativeX += settings.positionSettings.width;

        // draw the name section and accumulate the x pos
        NormalSection(
            name,
            height,
            vec2(cumulativeX, topLeftPos.y),
            settings.nameSettings
        );
        cumulativeX += settings.nameSettings.width;

        // draw the gap section and accumulate the x pos
        NormalSection(
            GapToString(gap),
            height,
            vec2(cumulativeX, topLeftPos.y),
            settings.gapSettings
        );
        cumulativeX += settings.gapSettings.width;

        // draw the gap rate section
        NormalSection(
            GapToString(gapRate),
            height,
            vec2(cumulativeX, topLeftPos.y),
            settings.rateSettings
        );
    }

    int CompareGhosts(ref@ a, ref@ b) {
        GhostGapData@ a1 = cast<GhostGapData@>(a);
        GhostGapData@ b1 = cast<GhostGapData@>(b);

        return b1.gap.GetGap() - a1.gap.GetGap();
    }

    // TODO: add back colouring for text
    void Normal(
        NormalSettings@ settings
    ) {
        // if the settings are not valid, set them to the defaults
        if (!settings.isValid()) {
            settings.SetDefaults();
        }

        array<GhostGapData>@ ghosts = gapMgr.ghostGaps;
        array<ref@> ghostRefs;

        for (uint i = 0; i < ghosts.Length; i++) {
            ref@ ghost = ghosts[i];
            ghostRefs.InsertLast(ghost);
        }

        Sort(ghostRefs, @CompareGhosts);

        const float sectionHeight = settings.sectionHeight;
        const vec2 topLeft = vec2(50, 50);

        // sort the ghosts

        for (uint i = 0; i < ghostRefs.Length; i++) {
            GhostGapData@ data = cast<GhostGapData@>(ghostRefs[i]);

            NormalDrawEntry(
                i + 1,
                data.ghostInfo.name,
                data.gap.GetGap(),
                data.gap.GapRate(),
                vec2(topLeft.x, topLeft.y + (sectionHeight * i)),
                settings
            );
        }
    }
}