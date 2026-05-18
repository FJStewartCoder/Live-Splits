class GapMgr {
    GhostGapData[] ghosts;

    void OnUpdate() {
        // currently super dodgy system to get the position pair with the ghost thing

        // TODO: fix the dodgy system
        // the ordering is the same but the indexing idea is not correct
        // somehow need to index them in the correct order then get the values back
        // there could be possibility to use other vehicle state functions like GetByID
        // we know the minimum vehicle state id and can probably do more maths and stuff

        // get the loaded ghosts
        // the ids are in the same order as the vehicle state vis
        auto b = MLFeed::GetGhostData().LoadedGhosts;

        // get those vis
        CSceneVehicleVis@[] d = VehicleState::GetAllVis(GetApp().GameScene);

        // get the smallest ghost id
        uint smallestGhostId = -1;

        for (int i = 0; i < b.Length; i++) {
            auto c = b[i];

            if (c.IdUint < smallestGhostId) { smallestGhostId = c.IdUint; }
        }

        // the (ghost id - smallest) + 1 gives the index in the vehicle vis array to the vis
        // +1 because idx 0 is the player

        // iterate all ghosts and apply above knowledge
        for (int i = 0; i < b.Length; i++) {
            auto c = b[i];

            CSceneVehicleVis@ thisVis = d[(c.IdUint - smallestGhostId) + 1];

            print(c.Nickname + " " + thisVis.AsyncState.Position.ToString());
        }
    }

    void OnRestart() {
    }

    void OnChangeTrack() {
    }
}

// this will combine gap_cache.as and gaps.as