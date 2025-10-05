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

// variable to store the current time
// TODO: fix time desync or create a better time logging system
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
// TODO: update script so the current player is not included in the ghost logs
// this is because we only need the current position to compare against each log

// TODO: FIX ERROR WHERE WHEN CURRENTLOGNUMBER EXCEEDS THE CURRENT ARRAYSIZE AND YOU RESET,
// THE OTHER GHOSTS GETS COUNTED AS FINISHED AND THE CODE IS BRICKED

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

    // used to get the number of cars in the misc array that is valid
    uint validCars = 0;

    // iterate all cars and accept the first ones that appear that are less than numCars
    for (int car = 0; car < cars.Length; car++) {
        // get the index of the current car in the misc array
        // this lines up with the points array (ensures that when cars finish the points of another car are not added to the array)
        uint currentId = GetEntityId(cars[car]);
        int carIdx = IndexFromId(currentId, numCars, miscArray);

        // FOR DEBUG
        // print(currentId);
        // print(carIdx);

        // if carIdx is not in miscArray then skip
        if (carIdx == -1) {
            continue;
        }

        // increment valid cars
        validCars++;

        // end loop if already found numCars valid cars
        if (validCars >= numCars) {
            break;
        } 

        // only continue logging if the array is not complete
        if (miscArray[carIdx].isArrayComplete) {
            print(miscArray[carIdx].id + " is complete " + carIdx);
            continue;
        }

        Point currentPoint;

        // get all of the car's data and put in a point
        currentPoint.y = cars[car].AsyncState.Position.y;
        currentPoint.x = cars[car].AsyncState.Position.x;
        currentPoint.z = cars[car].AsyncState.Position.z;

        // gets time stamp
        currentPoint.timeStamp = GetApp().TimeSinceInitMs - startTime;

        // reassign a point if there is space for it else insert at the end the new point
        if (currentLogIndex >= miscArray[carIdx].arraySize) {
            // set last point
            ghostPoints[carIdx].InsertLast(currentPoint);
            // increment array size here
            miscArray[carIdx].arraySize++;
        }
        else {
            ghostPoints[carIdx][currentLogIndex] = currentPoint;
        }

        // debug print
        // print(car + " " + currentPoint.Get());
    }

    // -------------------------------------------------------------------------
    // calculate the gaps
    Point thisPosition = ghostPoints[0][currentLogIndex];

    // set the gaps
    SetGaps(thisPosition, miscArray, ghostPoints);

    // -------------------------------------------------------------------------
    // housekeeping

    // check if any ghosts are finished
    // look through all IDs in miscArray, if the ID is not in cars, the car must have finished
    // i = 1 TO PREVENT THE PLAYER'S LIST FROM BEING COMPLETED
    // TODO: FIX ERROR WHERE AS SOON AS FOUND IS FALSE THE CODE GETS BRICKED
    for (int i = 0; i < miscArray.Length; i++) {
        // gets the current id
        uint miscId = miscArray[i].id;
        // is the id found?
        bool found = false;

        // iterate cars
        for (int j = 0; j < cars.Length; j++) {
            // does the ID match?
            if (GetEntityId(cars[j]) == miscId) {
                // yes, found break
                found = true;
                // BREAK EQUIVALENT
                j = cars.Length;
            }
        }

        // if not found, must be compete so set the isArrayComplete to true
        // they will also not be found on frame zero so if frame zero do nothing
        if (!found && currentLogIndex != 0) {
            // DEBUG PRINT
            print(miscId + " is finished!");
            miscArray[i].isArrayComplete = true;
        }
    }

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
        UI::InputInt("a", currentLogIndex);
        UI::InputInt("size", miscArray[0].arraySize);
        UI::InputInt("time", GetApp().TimeSinceInitMs - startTime);

        for (int i = 0; i < numCars; i++) {
            UI::PushID(i);
            UI::InputFloat("GAP", miscArray[i].gap / 1000.0);
            UI::PopID();
        }

        // UI::InputFloat3("Position", vec3(ghostPoints[0][currentLogIndex].y, ghostPoints[0][currentLogIndex].x, ghostPoints[0][currentLogIndex].z));
    }
    UI::End();
}