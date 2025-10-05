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

// 2d array of ghost points
// first array is always the current player
// 2nd and 3rd array are always the player's ghost if it exists

// hard limit on the array size
uint32 arrayMaxSize = 1000000;  // 1,000,000
uint8 numCars = 3;
array<array<Point>> ghostPoints(numCars, array<Point>(0));

// optimisation setting
uint8 framesBetweenLog = 1;
uint8 currentFrameNumber = 0;

// arraySize is not in here
// create a miscellaneous array for each ghost
array<Miscellaneous> miscArray(numCars);

// stores the number of where to log the value
uint32 currentLogIndex = 0;

// variable to store the start time
uint startTime = 0;

void ResizeArrays(uint numberGhosts, uint runLength) {
    // resize the main array
    ghostPoints.Resize(numberGhosts);

    // resize each subarray
    for (uint i = 0; i < numberGhosts; i++) {
        ghostPoints[i].Resize(runLength);
    }
}

// reset only the vars relevant to the current race
void ResetRaceVars() {
    // reset the current log number to 0
    currentLogIndex = 0;

    // reset current time
    startTime = GetApp().TimeSinceInitMs;

    // reset currentFrameNumber just so always starts at 0
}

// function to reset all variables
void ResetAllVars() {
    ResetRaceVars();

    // empty the arrays
    ResizeArrays(numCars, 0);

    // reset the misc array
    ResetMiscArray(numCars, miscArray);
}

// TODO: fix issue where misc array is not updated after setting a record for the first time
// TODO: fix issue where setting a new record will not update the misc array (update misc array if new record is set)
// TODO: fix issue where all cars are not added to misc array when switching track

void Main() {
    // assign array size on load
    // ResizeArrays(numCars, arraySize);
}

void Update(float dt) {
    ISceneVis@ scene = GetApp().GameScene;
    // gets the track
    CGameCtnChallenge@ track = GetApp().RootMap;

    // ensures the player is in a race
    if (scene is null) {
        return;
    }

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
        // reset all vars related to the current race
        ResetRaceVars();
        
        // debug message
        // print("reset");

        // DONT NEED TO CONTINUE IF AT START
        return;
    }

    // check for greater than a hard limit
    if (currentLogIndex >= arrayMaxSize) {
        // print("Max array size hit");
        return;
    }

    // ----------------------------------------------------------------------------
    // pre-log housekeeping and checks

    // increment frame number then always set bound as frames framesBetweenLog
    currentFrameNumber = (currentFrameNumber + 1) % framesBetweenLog;

    // only log frames if frame number is 0
    // unless you are at the start
    if (currentFrameNumber != 0 && currentLogIndex != 0) {
        return;
    }

    // make misc array (only does this if not already set)
    MakeMiscArray(cars, numCars, miscArray);

    // -------------------------------------------------------------------------
    // adding points scripts

    // iterate all cars and accept the first ones that appear that are less than numCars
    for (int car = 0; car < miscArray.Length; car++) {
        // only continue logging if the array is not complete
        if (miscArray[car].isArrayComplete) {
            // print(miscArray[carIdx].id + " is complete " + carIdx);
            continue;
        }
    
        // gets id from misc array
        uint currentId = miscArray[car].id;

        // not a valid id
        if (currentId == 0) {
            continue;
        }

        // gets current car based on entity ID with native functions
        CSceneVehicleVis@ currentCar = VehicleState::GetVisFromId(scene, currentId);

        // if is null, must have finished or is gone
        if (currentCar is null) {
            // if current log index is greater than the size, the array must have stopped tracking so must have finished
            if (miscArray[car].arraySize < currentLogIndex) {
                print(currentId + " has finished");
                miscArray[car].isArrayComplete = true;
            }

            // if null must continue
            continue;
        }

        Point currentPoint;

        // get all of the car's data and put in a point
        currentPoint.y = currentCar.AsyncState.Position.y;
        currentPoint.x = currentCar.AsyncState.Position.x;
        currentPoint.z = currentCar.AsyncState.Position.z;

        // gets time stamp
        currentPoint.timeStamp = GetApp().TimeSinceInitMs - startTime;

        // reassign a point if there is space for it else insert at the end the new point
        if (currentLogIndex >= miscArray[car].arraySize) {
            // set last point
            ghostPoints[car].InsertLast(currentPoint);
            // increment array size here
            miscArray[car].arraySize++;
        }
        else {
            ghostPoints[car][currentLogIndex] = currentPoint;
        }

        // debug print
        // print(car + " " + currentPoint.Get());
    }

    // -------------------------------------------------------------------------
    // calculate the gaps
    Point thisPoint;

    thisPoint.y = cars[0].AsyncState.Position.y;
    thisPoint.x = cars[0].AsyncState.Position.x;
    thisPoint.z = cars[0].AsyncState.Position.z;

    // gets time stamp
    thisPoint.timeStamp = GetApp().TimeSinceInitMs - startTime;

    // set the gaps
    SetGaps(thisPoint, miscArray, ghostPoints);

    // -------------------------------------------------------------------------
    // housekeeping

    // increment currentLogIndex
    currentLogIndex++;
}
    

// TODO: reduce number of times per seconds rendering of gap
void Render() {
    ISceneVis@ scene = GetApp().GameScene;

    // ensures the player is in a race
    if (scene is null) {
        return;
    }

    // creates window
    if (UI::Begin("Live Splits")) {
        // ONLY FOR DEBUGGING
        // UI::InputInt("LOG", currentLogIndex);
        // UI::InputInt("TIME", GetApp().TimeSinceInitMs - startTime);

        for (int i = 0; i < numCars; i++) {
            UI::PushID(i);
            // UI::InputInt("SIZE", miscArray[i].arraySize);
            UI::InputInt("ID", miscArray[i].id);
            UI::InputFloat("GAP", miscArray[i].gap / 1000.0);
            UI::Checkbox("COMPLETE", miscArray[i].isArrayComplete);
            UI::PopID();
        }

        // UI::InputFloat3("Position", vec3(ghostPoints[0][currentLogIndex].y, ghostPoints[0][currentLogIndex].x, ghostPoints[0][currentLogIndex].z));
    }
    UI::End();
}