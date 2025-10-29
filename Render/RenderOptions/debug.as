namespace Render {
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
}