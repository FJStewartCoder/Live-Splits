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

// array of the main ghost's points
array<Point> ghostPoints(0);
bool arrayComplete = false;

// arraySize is not in here
// create a miscellaneous array for each ghost
array<Miscellaneous> miscArray(numCars);

// stores the number of where to log the value
uint32 currentLogIndex = 0;

// variable to store the start time
uint startTime = 0;

// ensure data is only reset once every cycle
bool startDataSet = false;


void ResizeArrays(uint runLength) {
    // resize the main array
    ghostPoints.Resize(runLength);
}

// reset only the vars relevant to the current race
void ResetRaceVars() {
    // reset the current log number to 0
    currentLogIndex = 0;

    // reset current time
    startTime = GetApp().TimeSinceInitMs;

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
    SetGaps::Optimise(expectedFrameRate, 10);

    // reset the cache
    ResetCacheArray();
}

// TODO: fix multilap (it will go completely wrong)

// TODO: add setting for Optimise(resolution) resolution

// TODO: fix error where car entity IDs shift when you (the player) finish
// the cars do however remain the same order despite the shift
// this is so that the cache array doesn't continue to grow because new IDs keep getting added

// TODO: fix car finishing early bug as well
// THIS IS CAUSED BY PAUSING THE GAME

// TODO: fix pause bugs

void Main() {
    // upon loading sets the current config
    SetConfig();

    // load values that need syncing
    LoadAlg();
    LoadCounters();
}

int GetTime() {
    return GetApp().TimeSinceInitMs - startTime;
}

Point MakePoint(CSceneVehicleVis@ car) {
    Point newPoint;

    // get the point data
    newPoint.y = car.AsyncState.Position.y;
    newPoint.x = car.AsyncState.Position.x;
    newPoint.z = car.AsyncState.Position.z;

    // gets time stamp
    newPoint.timeStamp = GetTime();

    return newPoint;
}

// function to log the points
void LogPoints(ISceneVis@ scene) {
    // only log points if not complete
    if (arrayComplete) {
        return;
    }

    // check for size greater or equal to the hard limit
    if (currentLogIndex >= arrayMaxSize) {
        // print("Max array size hit");

        // if at limit the array must be complete
        arrayComplete = true;
        return;
    }

    // gets id from misc array
    uint currentId = miscArray[1].id;

    // not a valid id
    if (currentId == 0) {
        return;
    }

    // gets current car based on entity ID with native functions
    CSceneVehicleVis@ currentCar = VehicleState::GetVisFromId(scene, currentId);

    // if is null, must have finished or is gone
    if (currentCar is null) {
        // if current log index is greater than the size + 2, the array must have stopped tracking so must have finished
        // + 2 simply for safety
        if (ghostPoints.Length + 2 < currentLogIndex) {
            print("Logging finished");
            arrayComplete = true;
        }

        // if null must return
        return;
    }

    Point currentPoint = MakePoint(currentCar);

    // reassign a point if there is space for it else insert at the end the new point
    if (currentLogIndex >= ghostPoints.Length) {
        // set last point
        ghostPoints.InsertLast(currentPoint);
    }
    else {
        ghostPoints[currentLogIndex] = currentPoint;
    }

    // debug print
    // print(car + " " + currentPoint.Get());
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
            int cacheItem = GetCacheItem(GetTime(), miscArray[i].id);

            // only use cache if valid item and not the player car
            if (cacheItem != errorVal && i != 0) {
                miscArray[i].relGap = cacheItem;
                // print("Got Cache!");
            }
            else {
                Point thisPoint = MakePoint(currentCar);

                // set the based on the chosen algorithm
                switch (gapAlg) {
                    case GapAlgorithm::Linear:
                        // set the gaps using the linear algorithm
                        SetGaps::Linear(thisPoint, ghostPoints, miscArray[i]);
                        break;

                    case GapAlgorithm::ModifiedLinear:
                        // set the gaps using the modified linear algorithm 
                        SetGaps::ModifiedLinear(thisPoint, ghostPoints, miscArray[i]);
                        break;

                    case GapAlgorithm::Estimation:
                        // set the gaps using the estimation algorithm
                        SetGaps::Estimation(thisPoint, ghostPoints, miscArray[i]);
                        break;
                }

                // create a new cache item
                // only add a cache item if there was not found a cache item
                SetCacheItem(miscArray[i].relGap, GetTime(), miscArray[i].id);
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
    // ensures the player is in a race
    if (scene is null) { return; }

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

    // the only time this wiull be true is on the first loop so set start time to 0
    if (startDataSet) {
        startTime = GetApp().TimeSinceInitMs;
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
    // TODO: fix error where no items in misc array
    if (framesBetweenLog.GetValue() || currentLogIndex == 0) {
        LogPoints(scene);
    }

    // -------------------------------------------------------------------------
    // calculate the gaps

    // only calculate if the frames between gap requirement is met
    if (framesBetweenGap.GetValue() && arrayComplete) {
        // gets all of the gaps
        GetGaps(scene);
    }

    // -------------------------------------------------------------------------
    // housekeeping

    // increment currentLogIndex
    currentLogIndex++;
}