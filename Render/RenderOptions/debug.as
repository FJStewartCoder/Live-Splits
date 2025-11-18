namespace Render {
    void Debug() {
        // creates window
        if (UI::Begin("Debug Menu")) {
            // ONLY FOR DEBUGGING
            UI::InputInt("LOG", currentLogIndex);
            UI::InputInt("TIME", timer.GetTime());
            UI::InputInt("SIZE", ghostPoints.Length);
            UI::Checkbox("COMPLETE", arrayComplete);

            UI::InputInt("MISC SIZE", miscArray.Length);

            UI::SeparatorText("Preloader");  // ----------------------------
            UI::InputInt("LAST GHOST", preloader.lastGhost);
            UI::InputInt("LAST IDX", preloader.lastIndex);

            UI::SeparatorText("Interpolater");  // ----------------------------
            UI::InputInt("CURRENT PTR", interpolater.curPtr);

            for (int i = 0; i < miscArray.Length; i++) {
                UI::PushID(i);

                UI::SeparatorText("");

                UI::InputText("NAME", tostring(miscArray[i].name));
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