class Point {
    // stores the x, y, z coordinates
    double x, y, z;
    // stores the timeStamp of these coordinates
    // used to calculate the split
    // int but miliseconds
    uint timeStamp;

    string Get() {
        return "x = " + x + ", y = " + y + ", z = " + z + ", time = " + timeStamp;
    }
}


// map id
string lastMap;
string currentMap;

// arraySize is not in here
// create a miscellaneous array for each ghost
array<Miscellaneous> miscArray(numCars);

// stores the number of where to log the value
uint32 currentLogIndex = 0;

// ensure data is only reset once every cycle
bool startDataSet = false;

// bool to store if already saved the points
bool isSaved = false;

// the time manager
Time timer;

void ResetMiscItem(Miscellaneous @miscPtr) {
    // reset the last idx
    miscPtr.lastIdx = 0;

    // reset gaps
    miscPtr.gap = 0;
    miscPtr.relGap = 0;
}

// reset only the vars relevant to the current race
void ResetRaceVars() {
    // reset the current log number to 0
    currentLogIndex = 0;

    // reset current time
    timer.SetStartTime();

    // iterate miscArray and set last idx to 0
    for (int i = 0; i < miscArray.Length; i++) {
        if (miscArray[i].id == 0) {
            break;
        }

        ResetMiscItem(miscArray[i]);
    }

    // resets the player misc item as well  
    ResetMiscItem(miscArray[miscArray.Length - 1]);
}

// function to reset all variables
void ResetAllVars() {
    ResetRaceVars();

    // empty the arrays
    ResizeArrays(0);
    arrayComplete = false;

    // reset the misc array
    ResetMiscArray(numCars, miscArray);

    // optimise for the current track
    SetGaps::Optimise(expectedFrameRate, modLinResolution);

    // reset the cache
    ResetCacheArray();

    // on longer saved
    isSaved = false;
}

void Main() {
    // upon loading sets the current config
    SetConfig();

    // load values that need syncing
    LoadAlg();
    LoadCounters();
}

// overload thing below
Point MakePoint(CSceneVehicleVis@ car) {
    Point newPoint;

    // get the point data
    newPoint.y = car.AsyncState.Position.y;
    newPoint.x = car.AsyncState.Position.x;
    newPoint.z = car.AsyncState.Position.z;

    // gets time stamp
    newPoint.timeStamp = timer.GetTime();

    return newPoint;
}

Point MakePoint(CSceneVehicleVisState@ car) {
    Point newPoint;

    // get the point data
    newPoint.y = car.Position.y;
    newPoint.x = car.Position.x;
    newPoint.z = car.Position.z;

    // gets time stamp
    newPoint.timeStamp = timer.GetTime();

    return newPoint;
}

void GetGaps() {
    // gap for the user
    int myGap = 0;

    // only iterate all regular cars
    for (int i = 0; i < miscArray.Length - 1; i++) {
        // gets id from misc array
        uint currentId = miscArray[i].id;

        if (currentId == 0) {
            break;
        }

        CSceneVehicleVisState@ playerCar = VehicleState::ViewingPlayerState();
        // the player item is the last item in the misc array
        Miscellaneous @playerItem = miscArray[miscArray.Length - 1];

        // no player so return
        if (playerCar is null) { return; }

        Point thisPoint = MakePoint(playerCar);

        // set the based on the chosen algorithm
        switch (gapAlg) {
            case GapAlgorithm::Full:
                // set the gaps using the linear algorithm
                SetGaps::Full(thisPoint, ghostPoints, playerItem, useLinearGap);
                break;

            case GapAlgorithm::Estimation:
                // set the gaps using the estimation algorithm
                SetGaps::Estimation(thisPoint, ghostPoints, playerItem, useLinearGap);
                break;
        }

        // set the player gap using the original system
        myGap = playerItem.relGap;


        // the current gap
        int curGap;

        // if there is car calculate new gap
        CacheReturnItem cacheItem;
        // by default is error so if not using cache will not attempt to use cache
        cacheItem.isError = true;
        
        // only if using cache will the cache be obtained
        // else it will be error val which skips by default
        cacheItem = GetCacheItem(timer.GetTime(), miscArray[i].id, useCacheApproximation);

        // print(cacheItem.Get() + " " + miscArray[i].id);

        // only use cache if valid item and not the player car
        if (!cacheItem.isError) {
            // fill in the cached data
            miscArray[i].relGap = cacheItem.gap;
            miscArray[i].lastIdx = cacheItem.idx;

            // print("Got Cache!");
        }

        // current gap is relGap regardless of if car exists or not
        curGap = miscArray[i].relGap;

        // get the gap relative to the ghost
        miscArray[i].gap = myGap - curGap;
    }
}

void Update(float dt) {
    // if the plugin is off don't do anything
    if (!isEnabled) {
        return;
    }

    // get the app
    CGameCtnApp@ app = GetApp();

    ISceneVis@ scene = app.GameScene;
    // if not in game, don't do anything
    if (!IsInGame()) { return; } 

    // gets the track
    CGameCtnChallenge@ track = app.RootMap;

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

    // only set certain values upon switching track to reduce processing
    if (lastMap != currentMap) {
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
    if (thisCar is null) {
        // print("Player has finished");
        return;
    }

    // check if the first vehicle (you) have a race start time of this specific value which shows when you are at the start
    if (cars[0].AsyncState.RaceStartTime == 4294967295) {
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
        auto ghostCars = GetCurrentGhosts(app);

        // make misc array (only does this if not already set)
        MakeMiscArray(ghostCars, numCars, miscArray);
        // updates the size of the window only once
        updateWindowSize = true;
    }

    // -------------------------------------------------------------------------
    // get all ghosts

    // TODO: FIX ERRORS WHEN NO GHOSTS
    if (!arrayComplete) {
        // when entering a new track, get new points
        PreloadPoints();
        arrayComplete = true;
    }

    // -------------------------------------------------------------------------
    // calculate the gaps

    // only calculate if the frames between gap requirement is met
    if (framesBetweenGap.GetValue() && (arrayComplete || getGapOverride)) {
        // gets all of the gaps
        GetGaps();
    }

    // -------------------------------------------------------------------------
    // housekeeping

    // increment currentLogIndex
    currentLogIndex++;
}