// map id
string lastMap;
string currentMap;

// ensure data is only reset once every cycle
bool startDataSet = false;

// bool to store if already saved the points
bool isSaved = false;

// the time manager
Time timer;
ReferenceMgr reference;
GapMgr gapMgr;


// reset only the vars relevant to the current race
void ResetRaceVars() {
    reference.OnRestart();

    // reset current time
    timer.SetStartTime();

    // reset currentFrameNumber just so always starts at 0
    framesBetweenLog.Reset();
}

// function to reset all variables
void ResetAllVars() {
    ResetRaceVars();

    // set change track / reset
    reference.OnChangeTrack();

    // optimise for the current track
    SetGaps::Optimise(expectedFrameRate, modLinResolution);

    // reset the cache
    ResetCacheArray();

    // on longer saved
    isSaved = false;
}

// TODO: fix multilap (it will go completely wrong)

// TODO: fix error where car entity IDs shift when you (the player) finish
// the cars do however remain the same order despite the shift
// this is so that the cache array doesn't continue to grow because new IDs keep getting added

// TODO: fix car finishing early bug as well
// seems to be related to having a ghost already and resetting

// TODO:
// fix ghost replays not finishing in the gap manager leading to the ghost not properly showing gap at finish because it does not
// know that the ghost has finished (only applies if you are slower than a ghost)

void Main() {
    // upon loading sets the current config
    SetConfig();

    // load values that need syncing
    LoadAlg();
    LoadCounters();

    // create the dist cache array
    MakeDistCacheArray();
}

void GetGaps(ISceneVis @scene) {
    // gap for the user
    int myGap = 0;

    for (int i = 0; i < miscArray.Length; i++) {
        // gets id from misc array
        uint currentId = miscArray[i].id;

        const bool noMorePlayers = currentId == 0;
        if (noMorePlayers) { break; }

        CSceneVehicleVis@ currentCar = VehicleState::GetVisFromId(scene, currentId);

        // the current gap
        int curGap;
        const bool isPlayer = i == 0;

        // if there is car calculate new gap
        if (currentCar !is null) {
            CacheReturnItem cacheItem;
            // by default is error so if not using cache will not attempt to use cache
            cacheItem.isError = true;
            
            // only if using cache will the cache be obtained
            // else it will be error val which skips by default
            if (useCache) {
                cacheItem = GetCacheItem(timer.GetTime(), miscArray[i].id, useCacheApproximation);
            }

            // only use cache if valid item and not the player car
            if (!cacheItem.isError && !isPlayer) {
                // fill in the cached data
                miscArray[i].relGap = cacheItem.gap;
                miscArray[i].lastIdx = cacheItem.idx;

                // print("Got Cache!");
            }
            else {
                Point thisPoint;
                thisPoint.LoadFromState(currentCar.AsyncState);
                SubSamples@ curSamples = reference.sampleArray.samples[0];

                // set the based on the chosen algorithm
                switch (gapAlg) {
                    case GapAlgorithm::Full:
                        // set the gaps using the linear algorithm
                        SetGaps::Full(thisPoint, curSamples.samples, miscArray[i], useLinearGap);
                        break;

                    case GapAlgorithm::Estimation:
                        // set the gaps using the estimation algorithm
                        SetGaps::Estimation(thisPoint, curSamples.samples, miscArray[i], useLinearGap);
                        break;
                }

                // only if using cache will cache item be added
                if (useCache) {
                    // create a new cache item
                    // only add a cache item if there was not found a cache item
                    SetCacheItem(miscArray[i].relGap, timer.GetTime(), miscArray[i].id, miscArray[i].lastIdx);
                }
            }
        }

        // current gap is relGap regardless of if car exists or not
        curGap = miscArray[i].relGap;

        // user's gap is miscArray at 0
        if (isPlayer) { myGap = curGap; }

        // get the gap relative to the ghost
        miscArray[i].gap = myGap - curGap;
    }
}

void Update(float dt) {
    // if the plugin is off don't do anything
    if (!isEnabled) {
        return;
    }

    ISceneVis@ scene = GetApp().GameScene;
    // if not in game, don't do anything
    if (!IsInGame()) { return; } 

    // gets the track
    CGameCtnChallenge@ track = GetApp().RootMap;

    // get all of the cars and ghosts
    // ONLY DO THIS IF SCENE IS NOT NULL
    CSceneVehicleVis@[] cars = VehicleState::GetAllVis(scene);
    CSceneVehicleVisState@ thisCar = VehicleState::ViewingPlayerState();

    // ----------------------------------------------------------------------

    // ensures the track exists
    if (track is null) {
        // not the current map should be nothing
        currentMap = "";
    }
    else {
        // otherwise update the map
        lastMap = currentMap;
        currentMap = track.EdChallengeId;
    }

    const bool switchedTrack = lastMap != currentMap;

    // only set certain values upon switching track to reduce processing
    if (switchedTrack) {
        print("Track is now track id: " + currentMap);

        ResetAllVars();
    }

    // if paused, don't continue
    if (timer.IsPaused()) {
        // DEBUG MESSAGE
        // print("paused");
        return;
    }

    // -------------------------------------------------------------------------
    // checks to ensure we can proceed

    // if the currently viewing car is null (the player has finished)
    // return

    const bool playerFinished = thisCar is null;

    if (playerFinished) {
        // print("Player has finished");
        return;
    }

    const bool playerAtStart = cars[0].AsyncState.RaceStartTime == 4294967295;

    // check if the first vehicle (you) have a race start time of this specific value which shows when you are at the start
    if (playerAtStart) {
        if (startDataSet) {
            return;
        }

        // debug message
        print("reset");

        // reset all vars related to the current race
        ResetRaceVars();

        // the data is now set
        startDataSet = true;

        // DONT NEED TO CONTINUE IF AT START
        return;
    }

    // the only time this will be true is on the first loop so set start time to 0
    if (startDataSet) {
        timer.SetStartTime();
    }

    // becomes false once we pass this stage
    startDataSet = false;

    // ----------------------------------------------------------------------------
    // pre-log housekeeping and checks

    // increment all rotating counters
    framesBetweenGap.Increment();

    // cars must be greater than one to ensure the cars are included
    // only do this once the race has started (if newPbSet is true the race must be at the end)
    if (cars.Length > 1) {
        // make misc array (only does this if not already set)
        MakeMiscArray(cars, numCars, miscArray);
        // updates the size of the window only once
        updateWindowSize = true;
    }

    // -------------------------------------------------------------------------
    // adding points scripts

    PlayerData::Update();
    reference.OnUpdate();
    gapMgr.OnUpdate();

    // -------------------------------------------------------------------------
    // calculate the gaps

    // only calculate if the frames between gap requirement is met
    if (framesBetweenGap.GetValue() && (reference.sampleArray.isComplete || getGapOverride)) {
        // gets all of the gaps
        GetGaps(scene);
    }

    // -------------------------------------------------------------------------
    // housekeeping

    // FOR DEBUG
    // V3::FileTest();
}