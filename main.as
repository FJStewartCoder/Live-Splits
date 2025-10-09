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
array<array<Point>> ghostPoints(numCars, array<Point>(0));

// arraySize is not in here
// create a miscellaneous array for each ghost
array<Miscellaneous> miscArray(numCars);

// stores the number of where to log the value
uint32 currentLogIndex = 0;

// variable to store the start time
uint startTime = 0;

// current and last pb
bool newPbSet = false;
uint currentPb = uint(-1);


void ResizeArrays(uint numberGhosts, uint runLength) {
    // resize the main array
    ghostPoints.Resize(numberGhosts);

    // resize each subarray
    for (uint i = 0; i < numberGhosts; i++) {
        ghostPoints[i].Resize(runLength);
    }
}

// taken from 
// https://github.com/Phlarx/tm-ultimate-medals/blob/main/PersonalBest/NextPersonalBestMedal.as
// WON'T WORK UNTIL REAL BUILD BECAUSE LEADERBOARDS DISABLED
int GetPb(CGameCtnChallenge@ map) {
    int score = -1;

    auto app = GetApp();
    auto network = cast<CTrackManiaNetwork>(app.Network);

    if(network.ClientManiaAppPlayground !is null) {
        auto scoreMgr = network.ClientManiaAppPlayground.ScoreMgr;
        // from: OpenplanetNext\Extract\Titles\Trackmania\Scripts\Libs\Nadeo\TMNext\TrackMania\Menu\Constants.Script.txt
        // ScopeType can be: "Season", "PersonalBest"
        score = scoreMgr.Map_GetRecord_v2(0x100, map.MapInfo.MapUid, "PersonalBest", "", "TimeAttack", "");
    }

    return score;
}


// taken from 
// https://github.com/ArEyeses79/tm-ultimate-medals-extended/blob/main/PreviousRun.as#L30
uint GetCurrentTime() {
    uint score = 0;

    CGameCtnApp@ app = GetApp();
    CGamePlayground@ playground = cast<CGamePlayground>(app.CurrentPlayground);

    if (playground !is null && playground.GameTerminals.Length > 0) {
        CSmArenaRulesMode@ playgroundScript = cast<CSmArenaRulesMode>(app.PlaygroundScript);
        if (playgroundScript !is null) {
            CSmPlayer@ player = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
            if (player !is null) {
                CGameGhostScript@ ghost = playgroundScript.Ghost_RetrieveFromPlayer(cast<CSmScriptPlayer>(player.ScriptAPI));
                if (ghost !is null) {
                    score = uint(-1);
                    if (ghost.Result.Time > 0 && ghost.Result.Time < uint(-1)) {
                        score = ghost.Result.Time;
                    }
                }
            }
        }
    }

    return score;
}

// reset only the vars relevant to the current race
void ResetRaceVars() {
    // reset the current log number to 0
    currentLogIndex = 0;

    // reset current time
    startTime = GetApp().TimeSinceInitMs;

    // when restarting the race allow newPbSetting
    newPbSet = false;

    // iterate miscArray and set last idx to 0
    for (int i = 0; i < numCars; i++) {
        if (miscArray[i].id == 0) {
            break;
        }

        // reset the last idx
        miscArray[i].lastIdx = 0;
    }

    // reset currentFrameNumber just so always starts at 0
}

// function to reset all variables
void ResetAllVars() {
    ResetRaceVars();

    // empty the arrays
    ResizeArrays(numCars, 0);

    // reset the misc array
    ResetMiscArray(numCars, miscArray);

    // reset last pb if changing track
    currentPb = uint(-1);

    // optimise for the current track
    SetGaps::Optimise(expectedFrameRate, 4);
}

// TODO: fix multilap (it will go completely wrong)
// TODO: FIX VERY SLOW TO CLOSE MAP
// TODO: FIX RESET MISC ARRAY GOING OUT OF RANGE IF CHANGING SETTINGS

void Main() {
    // assign array size on load
    // ResizeArrays(numCars, arraySize);

    // upon loading sets the current config
    SetConfig();
}

// function to log the points
void LogPoints(ISceneVis@ scene) {
    // iterate all cars and accept the first ones that appear that are less than numCars
    for (int car = 0; car < miscArray.Length; car++) {
        // only continue logging if the array is not complete
        if (miscArray[car].isArrayComplete) {
            // print(miscArray[carIdx].id + " is complete " + carIdx);
            continue;
        }

        // check for size greater or equal to the hard limit
        if (currentLogIndex >= arrayMaxSize) {
            // print("Max array size hit");

            // if at limit the array must be complete
            miscArray[car].isArrayComplete = true;
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
            // if current log index is greater than the size + 2, the array must have stopped tracking so must have finished
            // + 2 simply for safety
            if (miscArray[car].arraySize + 2 < currentLogIndex) {
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
}

void Update(float dt) {
    // if the plugin is off don't do anything
    if (!isEnabled) {
        return;
    }

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
        // debug message
        // print("reset");

        // reset all vars related to the current race
        ResetRaceVars();

        // DONT NEED TO CONTINUE IF AT START
        return;
    }

    // ----------------------------------------------------------------------------
    // pre-log housekeeping and checks

    // increment all rotating counters
    framesBetweenLog.Increment();
    framesBetweenGap.Increment();

    // cars must be greater than one to ensure the cars are included
    // only do this once the race has started (if newPbSet is true the race must be at the end)
    if (cars.Length > 1 && !newPbSet) {
        // make misc array (only does this if not already set)
        MakeMiscArray(cars, numCars, miscArray);
    }

    // -------------------------------------------------------------------------
    // adding points scripts

    // only log frames if frame number is 0
    // unless you are at the start
    if (framesBetweenLog.GetValue() || currentLogIndex == 0) {
        LogPoints(scene);
    }

    // -------------------------------------------------------------------------
    // calculate the gaps

    // only calculate if the frames between gap requirement is met
    if (framesBetweenGap.GetValue()) {
        // define a point
        Point thisPoint;

        // get the point data
        thisPoint.y = cars[0].AsyncState.Position.y;
        thisPoint.x = cars[0].AsyncState.Position.x;
        thisPoint.z = cars[0].AsyncState.Position.z;

        // gets time stamp
        thisPoint.timeStamp = GetApp().TimeSinceInitMs - startTime;

        // set the based on the chosen algorithm
        switch (gapAlg) {
            case GapAlgorithm::Linear:
                // set the gaps using the linear algorithm
                SetGaps::Linear(thisPoint, miscArray, ghostPoints);
                break;

            case GapAlgorithm::ModifiedLinear:
                // set the gaps using the modified linear algorithm 
                SetGaps::ModifiedLinear(thisPoint, miscArray, ghostPoints);
                break;

            case GapAlgorithm::Estimation:
                // set the gaps using the estimation algorithm
                SetGaps::Estimation(thisPoint, miscArray, ghostPoints);
                break;
        }   
    }

    // ------------------------------------------------------------------------
    // evaluate pbs in order to correctly reset the arrays

    // if the current pb is unset, set the current pb
    if (currentPb == uint(-1)){
        // get the current pb
        currentPb = GetPb(track);

        if (currentPb != uint(-1)) {
            print("Current PB: " + currentPb);
        }
    }

    // new pb is whatever the last time was (it is trying to be the new pb)
    uint newPb = GetCurrentTime();

    // if newPb is less than or equal to old pb and new pb is not 0 or uint(-1) and newPbSet is false
    // both of last two can both regularly occur
    if (newPb <= currentPb && newPb != 0 && newPb != uint(-1) && !newPbSet) {
        // reset all of the arrays
        ResetAllVars();

        // set the current pb to the new pb
        currentPb = newPb;

        // to prevent continuously repeating set pb
        newPbSet = true;

        print("New PB Set: " + newPb);
    }

    // -------------------------------------------------------------------------
    // housekeeping

    // increment currentLogIndex
    currentLogIndex++;
}