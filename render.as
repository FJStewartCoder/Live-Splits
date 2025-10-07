int FONT_SIZE = 100;
int TEXT_SPACING = 10;
int FRAME_PADDING = 10;


// TODO: FIX GAME CRASH WHEN LEAVE TRACK


// TODO: reduce number of times per seconds rendering of gap
void Render() {
    ISceneVis@ scene = GetApp().GameScene;

    // ensures the player is in a race
    if (scene is null) {
        return;
    }

    // gets the number of valid cars
    int validCars;

    for (validCars = 1; validCars < numCars + 1; validCars++) {
        if (miscArray[validCars].id == 0) {
            break;
        }
    }

    // --------------------------------------------------------
    // styling

    int height = (FONT_SIZE * validCars) + (TEXT_SPACING * (validCars - 1)) + (FRAME_PADDING * 2);

    // set window height
    // TODO: fix error where window is not dynamically resized when changing number of cars
    UI::SetNextWindowSize(300, height);

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

        // ONLY FOR DEBUGGING
        // UI::InputInt("LOG", currentLogIndex);
        // UI::InputInt("TIME", GetApp().TimeSinceInitMs - startTime);

        for (int i = 0; i < validCars - 1; i++) {
            float curGap = miscArray[i].gap / 1000.0;
            // includes "+" if greater than 0
            string curGapString = ((curGap > 0)? "+" : "") + tostring(curGap);

            UI::PushID(i);
            // UI::InputInt("SIZE", miscArray[i].arraySize);
            // UI::InputInt("ID", miscArray[i].id);
            // UI::Checkbox("COMPLETE", miscArray[i].isArrayComplete);

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