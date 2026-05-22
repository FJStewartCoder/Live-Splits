class GapMgr {
    RacingGhostManager ghostMgr;
    GhostGapData playerData;

    bool isGhostsSet = false;

    RotatingCounter framesBetweenGap(4);

    int EvaluateGapFromState(CSceneVehicleVisState@ state) {
        Point p;
        p.LoadFromState(state);

        Point@ p2 = GetGap::Full(p, reference.sampleArray, false);

        return timer.GetTime() - p2.timeStamp;
    }

    void EvaluateGap(GhostGapData@ data) {
        int gap = EvaluateGapFromState(data.entityVis.AsyncState);

        data.relGap = gap;
        // TODO: fix once it is fixed
        // data.lastPointLoc = 0;
    }

    void UpdateGaps() {
        // increment and evaluate the framesBetweenGap counter
        framesBetweenGap.Increment();
        if (!framesBetweenGap.GetValue()) { return; }

        auto a = VehicleState::ViewingPlayerState();
        playerData.relGap = EvaluateGapFromState(a);

        // get the ghost list and make the variable name more local
        auto ghosts = ghostMgr.ghostsList;

        // iterate the ghosts in the ghost list
        for (int i = 0; i < ghosts.Length; i++) {
            GhostGapData@ data = ghosts[i];

            // calculate the extra ghost info
            GhostExtraInfo info = GetExtraGhostInfo(data.ghostData);

            // only evaluate the gap to the reference if the ghost has not finished
            if (!info.isFinished) {
                EvaluateGap(data);
            }

            data.gap = playerData.relGap - data.relGap;

            // print(data.entityId + " " + data.ghostId + " " + data.ghostData.Nickname + " " + data.entityVis.AsyncState.Position.ToString());
        }
    }

    void OnUpdate() {
        if (reference.sampleArray.isComplete) {
            UpdateGaps();

            if (!isGhostsSet && timer.GetTime() > 100) {
                trace("Resetting ghost array");

                ghostMgr.CreateGhostsArray();

                // set ghosts set to true because it now is
                isGhostsSet = true;
            }
        }
    }

    void OnRestart() {
        isGhostsSet = false;
        framesBetweenGap.Reset();

        ghostMgr.OnRestart();

        playerData.ResetGaps();
    }

    void OnChangeTrack() {
        OnRestart();
        ghostMgr.Reset();
    }
}

// this will combine gap_cache.as and gaps.as