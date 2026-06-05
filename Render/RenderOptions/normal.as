bool updateWindowSize = false;

namespace Render {
    class NormalSettings {
        bool summary;

        const bool isValid() {
            // TODO: implement
            return true;
        }

        void SetDefaults() {
            summary = false;
        }

        NormalSettings() {
            SetDefaults();
        }
    };

    // TODO: add text alignment options
    void NormalSection(
        const string&in text,
        const float width,
        const float height,
        const vec2 topLeftPos,
        const float padding
    ) {
        UI::DrawList@ drawList = UI::GetForegroundDrawList();

        const float widthForText = width - (padding * 2);
        // this is equivalent to the font size (font size is character height)
        const float heightForText = height - (padding * 2);

        // set the font size
        float fontSize = heightForText;

        // if there is not enough space for the text, return
        if (widthForText <= 0) { return; }
        if (heightForText <= 0) { return; }

        // draw the background box
        drawList.AddRectFilled(
            vec4(topLeftPos.x, topLeftPos.y, width, height),
            vec4(0, 0, 0, 0.5)
        );

        // measure the text to ensure that it fits
        const float textWidth = UI::MeasureString(text, null, fontSize).x;

        // if the text is too large, size down the text to fit in the width
        if (textWidth > widthForText) {
            fontSize = CalculateFontSizeForWidth(text, widthForText);
        }

        // draw the text
        drawList.AddText(
            vec2(topLeftPos.x + padding, topLeftPos.y + padding),
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
        const float height = 20;
        const float padding = 2;

        const float posWidth = 20;

        NormalSection(
            tostring(racePosition),
            posWidth,
            height,
            topLeftPos,
            padding
        );
        
        const float nameWidth = 75;
        
        NormalSection(
            name,
            nameWidth,
            height,
            vec2(topLeftPos.x + posWidth, topLeftPos.y),
            padding
        );

        const float gapWidth = 40;

        NormalSection(
            GapToString(gap),
            gapWidth,
            height,
            vec2(topLeftPos.x + posWidth + nameWidth, topLeftPos.y),
            padding
        );

        const float rateWidth = 50;

        NormalSection(
            GapToString(gapRate),
            rateWidth,
            height,
            vec2(topLeftPos.x + posWidth + nameWidth + gapWidth, topLeftPos.y),
            padding
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

        const float sectionHeight = 20;
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