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
    bool isGhostsSet = false;

    RotatingCounter framesBetweenGap(4);

    void CreateGhostsArray() {
        // reset the ghosts array
        ghosts.Resize(0);

        // TODO: fix the dodgy system
        // when adding more ghosts, your own state gets duplicated which causes errors
        // it mostly works

        // get the loaded ghosts
        // the ids are in the same order as the vehicle state vis
        array<MLFeed::GhostInfo_V2@> mlGhosts = MLFeed::GetGhostData().LoadedGhosts;
        SortGhostInfo(mlGhosts);

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

    void EvaluateGap(GhostGapData@ data) {
        Point p;
        p.LoadFromState(data.entityVis.AsyncState);

        PointLocation loc = GetGap::Full(p, reference.sampleArray);
        Point@ p2 = reference.sampleArray.FindLapAndCP(loc.lap, loc.cp).samples[loc.idx];

        data.relGap = timer.GetTime() - p2.timeStamp;
        data.lastPointLoc = loc;
    }

    int EvaluateGap(CSceneVehicleVisState@ state) {
        Point p;
        p.LoadFromState(state);

        PointLocation loc = GetGap::Full(p, reference.sampleArray);
        Point@ p2 = reference.sampleArray.FindLapAndCP(loc.lap, loc.cp).samples[loc.idx];

        return timer.GetTime() - p2.timeStamp;
    }

    void UpdateGaps() {
        // increment and evaluate the framesBetweenGap counter
        framesBetweenGap.Increment();
        if (!framesBetweenGap.GetValue()) { return; }

        auto a = VehicleState::ViewingPlayerState();
        int playerGap = EvaluateGap(a);
        
        // iterate the ghosts in the ghost list
        for (int i = 0; i < ghosts.Length; i++) {
            GhostGapData@ data = ghosts[i];

            EvaluateGap(data);
            data.gap = playerGap - data.gap;

            // print(data.entityId + " " + data.ghostId + " " + data.ghostData.Nickname + " " + data.entityVis.AsyncState.Position.ToString());
        }
    }

    void OnUpdate() {
        if (reference.sampleArray.isComplete) {
            UpdateGaps();

            if (!isGhostsSet && timer.GetTime() > 100) {
                trace("Resetting ghost array");
 
                CreateGhostsArray();
                isGhostsSet = true;
            }
        }
    }

    void OnRestart() {
        isGhostsSet = false;
        framesBetweenGap.Reset();
    }

    void OnChangeTrack() {
        OnRestart();
    }
}

// this will combine gap_cache.as and gaps.as