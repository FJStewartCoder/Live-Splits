namespace Render {
    void DebugRenderGhost(GhostGapData@ ghost) {
        UI::SeparatorText("");

        GhostData @info = ghost.ghostInfo;

        UI::InputText("NAME", info.name);

        if (info.ghostData !is null) {
            UI::InputInt("GHOST ID", info.ghostData.IdUint);
        }

        if (info.entityVis !is null) {
            UI::InputInt("ENTITY ID", GetEntityId(info.entityVis));
        }

        UI::InputInt("GAPS LENGTH", ghost.gap.gaps.Length);
        UI::InputInt("GAP", ghost.gap.GetGap());
        UI::InputInt("REL GAP", ghost.rel.GetGap());
        UI::InputInt("LAST REL GAP", ghost.rel.GetGap(1));
        UI::InputInt("GAP RATE", ghost.gap.GapRate());
        UI::InputInt("LAST IDX", ghost.lastPointIdx);

        UI::InputText("TYPE", GhostTypeToString(ghost.ghostInfo.type));
    }

    void DebugCheckpoint() {
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
    }

    void DebugCache() {
        if (UI::Begin("Cache Breakdown")) {
            auto names = gapMgr.cacheDict.GetKeys();

            for (uint i = 0; i < names.Length; i++) {
                const auto name = names[i];
                GapCache@ cache = cast<GapCache@>(gapMgr.cacheDict[name]);

                UI::SeparatorText(name);
                UI::InputInt("Cache Entries", cache.cacheEntries.Length);
                UI::InputInt("Cache Hits", cache.cacheHits);
                UI::InputInt("Cache Attempts", cache.cacheAttempts);
            }

            UI::End();
        }
    }

    void DebugGhostsAndGaps() {
        // creates window
        if (UI::Begin("Ghost and Gap Breakdown")) {
            auto ghosts = gapMgr.ghostGaps;

            DebugRenderGhost(gapMgr.playerData);

            for (int i = 0; i < ghosts.Length; i++) {
                GhostGapData@ ghost = ghosts[i];

                UI::PushID(i);

                DebugRenderGhost(ghost);

                UI::PopID();
            }

            UI::End();
        }
    }

    void Debug() {
        DebugCheckpoint();
        DebugGhostsAndGaps();
        DebugCache();
    }
}