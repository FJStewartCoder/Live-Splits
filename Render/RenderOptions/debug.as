namespace Render {
    void Debug() {
        // creates window
        if (UI::Begin("Debug Menu")) {
            // ONLY FOR DEBUGGING
            UI::InputInt("TIME", timer.GetTime());
            UI::InputInt("SIZE", reference.sampleArray.samples.Length);
            UI::Checkbox("COMPLETE", reference.sampleArray.isComplete);

            UI::SeparatorText("Player Data");
            UI::InputInt("Player Respawned", (PlayerData::hasRespawned) ? 1 : 0);

            for (int i = 0; i < reference.sampleArray.samples.Length; i++) {
                SubSamples@ samples = reference.sampleArray.samples[i];

                UI::SeparatorText("LAP: " + samples.lap + ", CP: " + samples.checkpoint);
                UI::InputInt("Size", samples.samples.Length);
            }

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