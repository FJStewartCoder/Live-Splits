class GapMgr {
    GhostGapData[] ghostGaps;
    GhostGapData playerData;

    bool isGhostsSet = false;


    // stores the player name then a cache array
    dictionary cacheDict;


    RotatingCounter framesBetweenGap(4);

    GapInfo EvaluateGapFromState(
        CSceneVehicleVisState@ state,
        uint lastIdx = -1,

        // checkpoint estimation related features
        bool useCheckpointEstimation = false,
        uint checkpoint = -1,
        uint lap = -1
    ) {
        Point p;
        p.LoadFromState(state);

        ArrayRange range(0, reference.sampleArray.samples.Length);

        if (useCheckpointEstimation) {
            PointLocation loc(checkpoint, lap);
            range = reference.sampleArray.GetSampleRange(loc, loc);
        }

        // print(range.ToString());

        GapInfo gapInfo;

        // gapInfo = GetGap::Estimation(p, reference.sampleArray, lastIdx, 50, range.min, range.max, false);
        gapInfo = GetGap::Full(p, reference.sampleArray, range.min, range.max, false);
        // gapInfo = GetGap::Full(p, reference.sampleArray, -1, -1, true);

        gapInfo.gap = timer.GetTime() - gapInfo.point.timeStamp;

        return gapInfo;
    }

    void EvaluateGap(GhostGapData@ data) {
        GhostData@ ghostInfo = data.ghostInfo;
        GapInfo gap;

        // if there is no extra data, just get the gap as usual
        if (ghostInfo.ghostData is null) {
            gap = EvaluateGapFromState(
                ghostInfo.entityVis.AsyncState,
                data.lastPointIdx,
                false
            );
        }
        // if there is extra data to work with, use it
        else {
            GhostExtraInfo extraData = GetExtraGhostInfo(data.ghostInfo.ghostData);

            // print(data.ghostName);

            gap = EvaluateGapFromState(
                ghostInfo.entityVis.AsyncState,
                data.lastPointIdx,
                true,
                extraData.checkpoint,
                extraData.lap
            );
        }

        // TODO: implement distance threshold

        data.ApplyGapInfo(gap);
    }

    void InfolessGhostGap(GhostGapData@ data) {
        // TODO: determine a method of analysing whether a ghost has finsihed
        const bool isFinished = false;

        if (!isFinished) { EvaluateGap(data); }
        data.gap = playerData.relGap - data.relGap;
    }

    void WithInfoGhostGap(GhostGapData@ data) {
        // get the extra info
        GhostData@ info = data.ghostInfo;

        // calculate the extra ghost info
        GhostExtraInfo extraInfo = GetExtraGhostInfo(info.ghostData);

        // only evaluate the gap to the reference if the ghost has not finished
        if (extraInfo.isFinished) {
            data.gap = playerData.relGap - data.relGap;
            return;
        }

        // if there is no cache entry for this ghost, create one
        if (!cacheDict.Exists(info.name)) {
            GapCache newCache;
            cacheDict[info.name] = newCache;
        }

        // get the ghost cache list
        GapCache@ ghostCache = cast<GapCache@>(cacheDict[info.name]);
        CacheReturnItem cacheReturn = ghostCache.GetCache(timer.GetTime(), 50);

        // if there is an error (no cache item, create a new one and set the gap)
        if (cacheReturn.isError) {
            // trace("Unable to get cache for " + data.ghostName + " @ " + timer.GetTime());
            EvaluateGap(data);

            // add new cache entry
            ghostCache.AddCache(data.relGap, timer.GetTime(), data.lastPointIdx);
        }
        // else, use the cache item
        else {
            // trace("Got cache for " + data.ghostName + " @ " + cacheReturn.entry.timeStamp);
            data.relGap = cacheReturn.entry.gap;
            data.lastPointIdx = cacheReturn.entry.idx;
        }

        // regardless of cache or not, calculate the gap
        data.gap = playerData.relGap - data.relGap;

        // print(data.entityId + " " + data.ghostId + " " + data.ghostData.Nickname + " " + data.entityVis.AsyncState.Position.ToString());
    }

    void HandleUpdateGhostGap(GhostGapData@ data) {
        GhostData@ info = data.ghostInfo;

        // if there is no ghost data to work with, use a more primitive process
        if (info.ghostData is null) {
            InfolessGhostGap(data);
            return;
        }

        WithInfoGhostGap(data);
    }

    void UpdateGaps() {
        // increment and evaluate the framesBetweenGap counter
        framesBetweenGap.Increment();
        if (!framesBetweenGap.GetValue()) { return; }

        if (PlayerData::isFinished) { return; }

        auto a = VehicleState::ViewingPlayerState();

        GapInfo playerGapInfo = EvaluateGapFromState(a, playerData.lastPointIdx, true, PlayerData::cp, PlayerData::lap);
        playerData.ApplyGapInfo(playerGapInfo);

        // get the ghost list and make the variable name more local
        auto ghosts = ghostGaps;

        // iterate the ghosts in the ghost list
        for (int i = 0; i < ghosts.Length; i++) {
            HandleUpdateGhostGap(ghosts[i]);
        }
    }

    void CreateGhostsArray() {
        ghostGaps.Resize(0);

        auto ghosts = GhostManager::GetAllGhosts();

        for (uint i = 0; i < ghosts.Length; i++) {
            GhostData@ curGhost = ghosts[i];
            GhostGapData newGapData;

            newGapData.ghostInfo = curGhost;

            if (curGhost.type == GhostType::LOCAL_PLAYER) {
                playerData = newGapData;
            }
            else {
                ghostGaps.InsertLast(newGapData);
            }
        }
    }

    void OnUpdate() {
        if (reference.sampleArray.isComplete) {
            UpdateGaps();

            // TODO:
            // check the ghost hash
            // if different from last hash
            // update the ghosts array

            if (!isGhostsSet && timer.GetTime() > 100) {
                trace("Resetting ghost array");

                CreateGhostsArray();

                // set ghosts set to true because it now is
                isGhostsSet = true;
            }
        }
    }

    void OnRestart() {
        isGhostsSet = false;
        framesBetweenGap.Reset();

        ghostGaps.Resize(0);

        playerData.ResetGaps();
    }

    void OnChangeTrack() {
        OnRestart();
        ghostGaps.Resize(0);

        // clear the cache dictionary
        cacheDict.DeleteAll();
    }
}

// this will combine gap_cache.as and gaps.as