void SortGhostInfo(array<MLFeed::GhostInfo_V2@>@ arr) {
    while (true) {
        bool swapped = false;

        for (uint i = 0; i < arr.Length - 1; i++) {
            MLFeed::GhostInfo_V2@ temp = null;
            MLFeed::GhostInfo_V2@ cur = arr[i];
            MLFeed::GhostInfo_V2@ next = arr[i + 1];

            if (cur.IdUint > next.IdUint) {
                @temp = cur;

                @arr[i] = next;
                @arr[i + 1] = temp;

                swapped = true;
            }
        }

        if (!swapped) { break; }
    }
}

class GapMgr {
    GhostGapData[] ghosts;

    void CreateGhostsArray() {
        // TODO: fix the dodgy system
        // when adding more ghosts, your own state gets duplicated which causes errors
        // it mostly works

        // get the loaded ghosts
        // the ids are in the same order as the vehicle state vis
        array<MLFeed::GhostInfo_V2@> mlGhosts = MLFeed::GetGhostData().LoadedGhosts;
        SortGhostInfo(mlGhosts);

        // reset the ghosts array
        ghosts.Resize(0);

        // get those vis
        CSceneVehicleVis@[] vehicleStates = VehicleState::GetAllVis(GetApp().GameScene);

        // iterate the vehicle visibilities and relate them to the ghost 
        for (int i = 1; i < vehicleStates.Length; i++) {
            CSceneVehicleVis@ vis = vehicleStates[i];

            GhostGapData data;

            @data.entityVis = vis;
            data.entityId = GetEntityId(vis);

            @data.ghostData = mlGhosts[i - 1];
            data.ghostId = data.ghostData.IdUint;
            data.ghostName = data.ghostData.Nickname;

            ghosts.InsertLast(data);
        }
    }

    uint EvaluateGap(CSceneVehicleVisState@ state) {
        Point p;
        p.LoadFromState(state);

        Point@ p2 = GetGap::Simple(p, reference.sampleArray);
        return timer.GetTime() - p2.timeStamp;
    }

    void UpdateGaps() {
        auto a = VehicleState::ViewingPlayerState();

        uint playerGap = EvaluateGap(a);
        
        // iterate the ghosts in the ghost list
        for (int i = 0; i < ghosts.Length; i++) {
            GhostGapData@ data = ghosts[i];

            data.relGap = EvaluateGap(data.entityVis.AsyncState);
            data.gap = playerGap - data.gap;

            // print(data.entityId + " " + data.ghostId + " " + data.ghostData.Nickname + " " + data.entityVis.AsyncState.Position.ToString());
        }
    }

    void OnUpdate() {
        if (reference.sampleArray.isComplete) {
            CreateGhostsArray();
            UpdateGaps();
        }
    }

    void OnRestart() {
    }

    void OnChangeTrack() {
    }
}

// this will combine gap_cache.as and gaps.as