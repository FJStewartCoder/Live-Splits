class GapMgr {
    RacingGhostManager ghostMgr;
    GhostGapData playerData;

    bool isGhostsSet = false;


    // stores the player name then a cache array
    dictionary cacheDict;


    RotatingCounter framesBetweenGap(4);

    GapInfo EvaluateGapFromState(
        CSceneVehicleVisState@ state,
        uint checkpoint,
        uint lap,
        uint lastIdx = -1
    ) {
        Point p;
        p.LoadFromState(state);

        PointLocation loc(checkpoint, lap);
        ArrayRange range = reference.sampleArray.GetSampleRange(loc, loc);

        // print(range.ToString());

        GapInfo gapInfo;

        // gapInfo = GetGap::Estimation(p, reference.sampleArray, lastIdx, 50, range.min, range.max, false);
        gapInfo = GetGap::Full(p, reference.sampleArray, range.min, range.max, false);

        gapInfo.gap = timer.GetTime() - gapInfo.point.timeStamp;

        return gapInfo;
    }

    void EvaluateGap(GhostGapData@ data) {
        GhostExtraInfo extraData = GetExtraGhostInfo(data.ghostData);

        // print(data.ghostName);

        GapInfo gap = EvaluateGapFromState(
            data.entityVis.AsyncState,
            extraData.checkpoint,
            extraData.lap,
            data.lastPointIdx
        );

        // TODO: implement distance threshold

        data.ApplyGapInfo(gap);
    }

    void UpdateGaps() {
        // increment and evaluate the framesBetweenGap counter
        framesBetweenGap.Increment();
        if (!framesBetweenGap.GetValue()) { return; }

        if (PlayerData::isFinished) { return; }

        auto a = VehicleState::ViewingPlayerState();

        GapInfo playerGapInfo = EvaluateGapFromState(a, PlayerData::cp, PlayerData::lap, playerData.lastPointIdx);
        playerData.ApplyGapInfo(playerGapInfo);

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
        // clear the cache dictionary
        cacheDict.DeleteAll();
    }
}

// this will combine gap_cache.as and gaps.as