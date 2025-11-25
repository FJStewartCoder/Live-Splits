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
array<Miscellaneous> miscArray;

// ensure data is only reset once every cycle
bool startDataSet = false;

// the time manager
Time timer;

// the ghost preloader
Preloader preloader;

// variables related to ghost loading
bool checkedGhosts = false;
uint lastNumGhosts = 0;

// reset only the vars relevant to the current race
void ResetRaceVars() {
    // reset current time
    timer.SetStartTime();

    // iterate miscArray and set last idx to 0
    for (int i = 0; i < miscArray.Length; i++) {
        if (miscArray[i].id == 0) {
            break;
        }

        ResetMiscItem(miscArray[i]);
    }

    // only clear last if the misc array exists
    if (!miscArray.IsEmpty()) {
        // resets the player misc item as well  
        ResetMiscItem(miscArray[miscArray.Length - 1]);
    }

    // makes sure the ghosts are checked again
    checkedGhosts = false;
}

// function to reset all variables
void ResetAllVars() {
    ResetRaceVars();

    // empty the arrays
    ResizeArrays(0);
    arrayComplete = false;

    // reset the misc array
    ResetMiscArray(miscArray);

    // optimise for the current track
    SetGaps::Optimise(expectedFrameRate, modLinResolution);

    // reset the cache
    ResetCacheArray();

    // reset the preloader
    preloader.Reset();

    // in case there are the same number of ghosts
    lastNumGhosts = uint(-1);
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

    // ---------------------------------------------------------------------------
    // ghost related functions

    bool reloadGhosts = false;

    // this is run everytime there is a reset
    if (!checkedGhosts) {
        auto ghostCars = GetCurrentGhosts(app);

        // if there is a new number of ghosts, then reset the ghosts
        if (lastNumGhosts != ghostCars.Length) {
            // reset to ensure we can make
            ResetMiscArray(miscArray);

            // make misc array (only does this if not already set)
            MakeMiscArray(ghostCars, miscArray);

            // resets the cache array as well
            ResetCacheArray();

            // updates the size of the window only once
            updateWindowSize = true;

            // reload all of the ghosts
            reloadGhosts = true;
        }

        // set the last num ghosts
        lastNumGhosts = ghostCars.Length;

        // don't need to do this process again until reset
        checkedGhosts = true;
    }

    if (!preloader.isComplete || reloadGhosts) {
        // when entering a new track, get new points
        int res = preloader.PreloadPoints(100);

        switch (res) {
            case 0:
                print("Success!");
                arrayComplete = true;
                break;
            case 1:
                print("No ghosts!");
                break;
            case 2:
                // print("Still loading...");
                break;
            default:
                // print("How did you even do this?");
                break;
        }
    }

    // -------------------------------------------------------------------------
    // calculate the gaps

    // only calculate if the frames between gap requirement is met
    if (framesBetweenGap.GetValue() && arrayComplete) {
        // gets all of the gaps
        GetGaps();
    }
}