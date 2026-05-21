namespace Render {
    void DebugRenderGhost(GhostGapData@ ghost) {
        UI::SeparatorText("");

        UI::InputText("NAME", ghost.ghostName);
        UI::InputInt("GHOST ID", ghost.ghostId);
        UI::InputInt("ENTITY ID", ghost.entityId);

        UI::InputInt("GAP", ghost.gap);
        UI::InputInt("REL GAP", ghost.relGap);
        UI::InputText("LAST IDX", ghost.lastPointLoc.ToString());
    }

    void Debug() {
        if (UI::Begin("Checkpoint Breakdown")) {
            // ONLY FOR DEBUGGING
            UI::InputInt("TIME", timer.GetTime());
            UI::InputInt("SIZE", reference.sampleArray.samples.Length);
            UI::Checkbox("COMPLETE", reference.sampleArray.isComplete);

            UI::SeparatorText("Player Data");
            UI::InputInt("Player Respawned", (PlayerData::hasRespawned) ? 1 : 0);

            for (int i = 0; i < reference.sampleArray.definitions.Length; i++) {
                SubSampleDefinition@ samples = reference.sampleArray.definitions[i];

                UI::SeparatorText("LAP: " + samples.lap + ", CP: " + samples.checkpoint);
                UI::InputInt("Start", samples.startIdx);
                UI::InputInt("Size", samples.length);
            }

            UI::End();
        }

        // creates window
        if (UI::Begin("Ghost and Gap Breakdown")) {
            DebugRenderGhost(gapMgr.playerData);

            for (int i = 0; i < gapMgr.ghosts.Length; i++) {
                GhostGapData@ ghost = gapMgr.ghosts[i];

                UI::PushID(i);

                DebugRenderGhost(ghost);

                UI::PopID();
            }
        }
        UI::End();
    }
}