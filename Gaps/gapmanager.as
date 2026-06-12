class GapMgr {
    GhostGapData[] ghostGaps;
    GhostGapData playerData;

    // the hash to quickly decide when to refresh the ghosts
    uint lastGhostHash = 0;
    
    // optionally toggle the cache
    bool cacheEnabled = true;

    // stores the player name then a cache array
    dictionary cacheDict;

    // the chosen gap algorithm
    // estimation is the best
    GapAlgorithm algorithm = GapAlgorithm::Estimation;

    // more gap related settings
    bool useLinear = false;
    uint searchRange = 50;

    // if more than 500 dist from closest point, set rel gap to 0
    float gapDistanceThreshold = 50;

    // checkpoint estimation related settings
    bool useCheckpointEstimation = true;    
    // how many checkpoints to check either side of the current one
    int2 cpCheckRange = int2(0, 0);


    RotatingCounter framesBetweenGap(3);

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
            // get the sample range 1cp each side of the current cp
            range = reference.sampleArray.GetSampleRange(
                checkpoint, lap,
                cpCheckRange
            );

            // print(range.ToString());
        }

        GapInfo gapInfo;

        switch (algorithm) {
            case GapAlgorithm::Full:
                gapInfo = GetGap::Full(
                    p, reference.sampleArray, 
                    range.min, range.max,
                    useLinear
                );
                break;

            case GapAlgorithm::Estimation:
                gapInfo = GetGap::Estimation(
                    p, reference.sampleArray,
                    lastIdx, searchRange,
                    range.min, range.max,
                    useLinear
                );
                break;
        }

        // set the gap to 0 by default
        gapInfo.gap = 0;

        // if does not exceed the distance threshold, calculate the gap
        if (gapInfo.distance <= gapDistanceThreshold) {
            // timestamp is the timestamp when the reference ghost reached the point the current car is
            // the gap must therefore be the time difference between when this car and the reference car got to the same point
            gapInfo.gap = timer.GetTime() - gapInfo.point.timeStamp;
        }

        return gapInfo;
    }

    void EvaluateGap(GhostGapData@ data) {
        GhostData@ ghostInfo = data.ghostInfo;

        // get the cp and lap
        LapAndCp lapCp = ghostInfo.GetLapAndCP();

        uint cp = lapCp.checkpoint;
        uint lap = lapCp.lap;

        // print("CP: " + cp + ", LAP: " + lap);

        const bool playerWantsCPEstimation = useCheckpointEstimation && (cp != uint(-1)) && (lap != uint(-1));

        // get the gap
        GapInfo gap = EvaluateGapFromState(
            ghostInfo.entityVis.AsyncState,
            data.lastPointIdx,
            playerWantsCPEstimation,
            cp,
            lap
        );

        data.ApplyRelGapInfo(gap);
    }

    void CacheProcess(GhostGapData@ data) {
        // get the info
        GhostData@ info = data.ghostInfo;

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
            ghostCache.AddCache(data.rel.GetGap(), timer.GetTime(), data.lastPointIdx);
        }
        // else, use the cache item
        else {
            // trace("Got cache for " + data.ghostName + " @ " + cacheReturn.entry.timeStamp);
            data.rel.SetGap(cacheReturn.entry.gap);
            data.lastPointIdx = cacheReturn.entry.idx;
        }

        // regardless of cache or not, calculate the gap
        data.ApplyGapInfo(playerData);

        // print(data.entityId + " " + data.ghostId + " " + data.ghostData.Nickname + " " + data.entityVis.AsyncState.Position.ToString());
    }

    void HandleUpdateGhostGap(GhostGapData@ data) {
        GhostData@ info = data.ghostInfo;

        // if the ghost or player is finished, return
        if (info.IsFinished()) {
            // update the gap to but don't recalculate the gap of the ghost, once finished
            data.ApplyGapInfo(playerData);
            return;
        }

        // only use cache if the ghost is cacheable and the cache is enabled
        const bool useCache = cacheEnabled && info.IsCacheable();

        if (useCache) {
            CacheProcess(data);
            return;
        }

        // evaluate the gap to the reference line 
        EvaluateGap(data);

        // calculate the gap for this ghost relative to the player
        data.ApplyGapInfo(playerData);
    }

    void UpdateGaps() {
        // increment and evaluate the framesBetweenGap counter
        framesBetweenGap.Increment();
        if (!framesBetweenGap.GetValue()) { return; }

        if (PlayerData::isFinished) { return; }

        auto a = VehicleState::ViewingPlayerState();

        GapInfo playerGapInfo = EvaluateGapFromState(a, playerData.lastPointIdx, useCheckpointEstimation, PlayerData::cp, PlayerData::lap);
        playerData.ApplyRelGapInfo(playerGapInfo);

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
        // why update gaps if the points are incomplete
        if (!reference.sampleArray.isComplete) { return; }

        // allow time for ghosts to load in
        if (timer.GetTime() < 100) { return; }
        
        // get the hash
        uint ghostHash = GhostManager::GetGhostHash();

        // print(ghostHash + " " + lastGhostHash);

        // check for hash equality
        const bool isHashEqual = ghostHash == lastGhostHash;

        // update the last hash to the current hash
        lastGhostHash = ghostHash;

        // if the set of ghosts before is not the same as the ghosts now, update them
        if (!isHashEqual) {
            trace("Resetting ghost array");
            CreateGhostsArray();
        }

        UpdateGaps();
    }

    void OnRestart() {
        framesBetweenGap.Reset();
        ghostGaps.Resize(0);
        playerData.ResetGaps();

        // ensures that ghosts are updated on restart
        lastGhostHash = 0;
    }

    void OnChangeTrack() {
        OnRestart();
        ghostGaps.Resize(0);

        lastGhostHash = 0;

        // clear the cache dictionary
        cacheDict.DeleteAll();

        // optimise the modified linear array for searches
        GetGap::Optimise(
            Settings::Performance::expectedFrameRate,
            Settings::Gap::modLinResolution
        );
    }
}

// this will combine gap_cache.as and gaps.as