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

        // reset the last idx
        miscArray[i].lastIdx = 0;

        // reset gaps
        miscArray[i].gap = 0;
        miscArray[i].relGap = 0;
    }

    // reset currentFrameNumber just so always starts at 0
    framesBetweenLog.Reset();

    // reset the misc array (this magically fixes an issue I had where the vehicle IDs keep changing)
    ResetMiscArray(numCars, miscArray);
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

// TODO: fix multilap (it will go completely wrong)

// TODO: fix error where car entity IDs shift when you (the player) finish
// the cars do however remain the same order despite the shift
// this is so that the cache array doesn't continue to grow because new IDs keep getting added

// TODO: fix car finishing early bug as well

void Main() {
    // upon loading sets the current config
    SetConfig();

    // load values that need syncing
    LoadAlg();
    LoadCounters();

    // create the dist cache array
    MakeDistCacheArray();

    CGameCtnApp@ app = GetApp();
    CGameCtnNetwork@ net = app.Network;
    CGamePlaygroundScript@ playground = app.PlaygroundScript;

    MwFastBuffer<CGameGhostScript@> netGhosts = net.ClientManiaAppPlayground.DataFileMgr.Ghosts;

    for (int i = 0; i < netGhosts.Length; i++) {
        print(tostring(netGhosts[i].Nickname));
    }

    MwFastBuffer<CGameGhostScript@> localGhosts = playground.DataFileMgr.Ghosts;

    for (int i = 0; i < localGhosts.Length; i++) {
        print(tostring(localGhosts[i].Nickname));
    }

    // ENTITY ID TO NAME
    // THE FIRST GHOST begins with 2 is your current player
    // THE LAST 2 GHOSTS are your pb then your no respawn ghost
    // IDs ARE ALLOCATED IN THE ORDER OF THE GHOST NAMES

    // IF GHOSTS ARE CHANGED IN RACE your pb becomes second but no respawn stays last

    // DEFINITIVE ORDER:
    // ALL GHOSTS ARE ADDED IN THE ORDER IN WHICH YOU SELECTED THEM (SAME AS NETGHOSTS ORDER)
    // THEN YOUR PB IS ADDED

    // ALL SUBSEQUENT GHOSTS ARE ADDED AT THE END OF THIS (AFTER YOUR PB) UNTIL YOU FINISH (ORDER IS THEN RESET TO ABOVE)
    // REMOVING GHOSTS JUST BREAKS THE WHOLE SYSTEM

    // auto allGhosts = GetAllGhosts();

    GetPoints();
}

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

void GetGaps(ISceneVis @scene) {
    // gap for the user
    int myGap = 0;

    for (int i = 0; i < miscArray.Length; i++) {
        // gets id from misc array
        uint currentId = miscArray[i].id;

        if (currentId == 0) {
            break;
        }

        CSceneVehicleVis@ currentCar = VehicleState::GetVisFromId(scene, currentId);

        // the current gap
        int curGap;

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
            if (!cacheItem.isError && i != 0) {
                // fill in the cached data
                miscArray[i].relGap = cacheItem.gap;
                miscArray[i].lastIdx = cacheItem.idx;

                // print("Got Cache!");
            }
            else {
                Point thisPoint = MakePoint(currentCar);

                // set the based on the chosen algorithm
                switch (gapAlg) {
                    case GapAlgorithm::Full:
                        // set the gaps using the linear algorithm
                        SetGaps::Full(thisPoint, ghostPoints, miscArray[i], useLinearGap);
                        break;

                    case GapAlgorithm::Estimation:
                        // set the gaps using the estimation algorithm
                        SetGaps::Estimation(thisPoint, ghostPoints, miscArray[i], useLinearGap);
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
        if (i == 0) {
            myGap = curGap;
        }

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
    framesBetweenLog.Increment();
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

    // only log frames if frame number is 0
    // unless you are at the start
    if (framesBetweenLog.GetValue() || currentLogIndex == 0) {
        // GetPoints();
    }

    // -------------------------------------------------------------------------
    // calculate the gaps

    // only calculate if the frames between gap requirement is met
    if (framesBetweenGap.GetValue() && (arrayComplete || getGapOverride)) {
        // gets all of the gaps
        GetGaps(scene);
    }

    // -------------------------------------------------------------------------
    // housekeeping

    // increment currentLogIndex
    currentLogIndex++;
}