bool updateWindowSize = false;

namespace Render {
    enum TextAlignment {
        LEFT,
        RIGHT,
        CENTRE
    }
    
    class NormalSectionSettings {
        float width;

        float padding;

        TextAlignment textAlignment;

        vec4 backgroundColour;
        vec4 textColour;


        const bool isValid() {
            // TODO: implement
            return true;
        }

        void SetDefaults() {
            // width as a percentage of the screen width
            width = 0.075;

            padding = 2;

            textAlignment = TextAlignment::LEFT;

            backgroundColour = vec4(0, 0, 0, 0.7);
            textColour = vec4(1, 1, 1, 1);
        }

        NormalSectionSettings() {
            SetDefaults();
        }
    }

    class NormalSettings {
        bool summary;
        uint numCarsInSummary;

        NormalSectionSettings positionSettings;
        bool positionEnabled;

        NormalSectionSettings nameSettings;
        bool nameEnabled;

        NormalSectionSettings gapSettings;
        bool gapEnabled;

        NormalSectionSettings rateSettings;
        bool rateEnabled;

        float sectionHeight;
        // margin between the player record and the rest of the table
        float playerSectionYMargin;

        vec2 position;
        
        // colour for the gap based on performance
        vec4 neutralColour;
        vec4 positiveColour;
        vec4 negativeColour;


        const bool isValid() {
            // TODO: implement
            return true;
        }

        void SetDefaults() {
            summary = true;
            numCarsInSummary = 4;

            positionSettings.width = 0.02;
            positionSettings.textAlignment = TextAlignment::CENTRE;
            positionEnabled = true;

            nameSettings.width = 0.1;
            nameEnabled = true;

            gapSettings.width = 0.05;
            gapSettings.textAlignment = TextAlignment::CENTRE;
            gapEnabled = true;

            rateSettings.width = 0.05;
            rateSettings.textAlignment = TextAlignment::CENTRE;
            rateEnabled = true;

            sectionHeight = 0.025;
            playerSectionYMargin = 0.01;

            // the below calculation allows the table to be the same width from the top as the left
            // 16 * x == 9 * y
            // y = 16x / 9
            position = vec2(0.02, (16.0 / 9.0) * 0.02);

            neutralColour = vec4(0.7, 0.7, 0.7, 1);
            negativeColour = vec4(1, 0.3, 0.3, 1);
            positiveColour = vec4(0, 1, 0, 1);
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
        UI::DrawList@ drawList = UI::GetBackgroundDrawList();

        const float width = settings.width * Display::GetWidth();

        // re-assignment since it is quicker to type
        const float padding = settings.padding;

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
            settings.backgroundColour
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
            settings.textColour,
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
        const int screenWidth = Display::GetWidth();
        const float height = settings.sectionHeight * Display::GetHeight();

        float cumulativeX = topLeftPos.x;

        if (settings.positionEnabled) {
            // draw the position section and accumulate the x pos
            NormalSection(
                tostring(racePosition),
                height,
                vec2(cumulativeX, topLeftPos.y),
                settings.positionSettings
            );
            cumulativeX += settings.positionSettings.width * screenWidth;
        }

        if (settings.nameEnabled) {
            // draw the name section and accumulate the x pos
            NormalSection(
                name,
                height,
                vec2(cumulativeX, topLeftPos.y),
                settings.nameSettings
            );
            cumulativeX += settings.nameSettings.width * screenWidth;
        }

        if (settings.gapEnabled) {
            // calculate the text colour based on the gap
            if (gap == 0) { settings.gapSettings.textColour = settings.neutralColour; }
            else if (gap < 0) { settings.gapSettings.textColour = settings.positiveColour; }
            else { settings.gapSettings.textColour = settings.negativeColour; }

            // draw the gap section and accumulate the x pos
            NormalSection(
                GapToString(gap),
                height,
                vec2(cumulativeX, topLeftPos.y),
                settings.gapSettings
            );
            cumulativeX += settings.gapSettings.width * screenWidth;
        }

        if (settings.rateEnabled) {
            // calculate the text colour based on the gap rate
            if (gapRate == 0) { settings.rateSettings.textColour = settings.neutralColour; }
            else if (gapRate < 0) { settings.rateSettings.textColour = settings.positiveColour; }
            else { settings.rateSettings.textColour = settings.negativeColour; }

            // draw the gap rate section
            NormalSection(
                GapToString(gapRate),
                height,
                vec2(cumulativeX, topLeftPos.y),
                settings.rateSettings
            );
        }
    }

    // returns the value as an index not position
    int PlayerPosition(ref@[]@ ghosts) {
        // iterate the ghosts list until we find an entry greater than on equal to 0 time
        for (uint i = 0; i < ghosts.Length; i++) {
            GhostGapData@ data = cast<GhostGapData@>(ghosts[i]);

            print(i + " " + data.ghostInfo.name + " " + data.gap.GetGap());

            // the position will be determined by the first gap that the player is faster than (<= 0)
            // so return that index
            if (data.gap.GetGap() <= 0) { return i; }
        }

        return ghosts.Length;
    }

    int CompareGhosts(ref@ a, ref@ b) {
        GhostGapData@ a1 = cast<GhostGapData@>(a);
        GhostGapData@ b1 = cast<GhostGapData@>(b);

        return b1.gap.GetGap() - a1.gap.GetGap();
    }

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

        // sort the ghosts in order of fastest to slowest at any given time
        Sort(ghostRefs, @CompareGhosts);

        const float sectionHeight = settings.sectionHeight;
        const vec2 topLeft(
            Display::GetWidth() * settings.position.x,
            Display::GetHeight() * settings.position.y
        );

        const int playerRacePosition = PlayerPosition(ghostRefs);

        NormalDrawEntry(
            playerRacePosition + 1,
            "You",
            0,
            0, 
            vec2(topLeft.x, topLeft.y),
            settings
        );

        const float playerRecordMargin = settings.playerSectionYMargin * Display::GetHeight();

        // by default, it is all of the ghosts
        uint numGhostsToRender = ghostRefs.Length;

        // if summary, and more cars than the max in a summary, then set the number to render to the number in the summary
        if (settings.summary && settings.numCarsInSummary < ghostRefs.Length) {
            numGhostsToRender = settings.numCarsInSummary;
        }

        // render the sorted ghosts
        for (uint i = 0; i < numGhostsToRender; i++) {
            GhostGapData@ data = cast<GhostGapData@>(ghostRefs[i]);

            // race position is the index + 1 (for real position)
            // then +1 if the index is after where the player is
            const int racePosition = i + 1 + ((i >= playerRacePosition)? 1 : 0);

            NormalDrawEntry(
                racePosition,
                data.ghostInfo.name,
                data.gap.GetGap(),
                data.gap.GapRate(),
                // +1 to i here because we render one section for the player
                vec2(
                    topLeft.x, 
                    topLeft.y + (sectionHeight * Display::GetHeight() * (i + 1)) + playerRecordMargin
                ),
                settings
            );
        }
    }
}