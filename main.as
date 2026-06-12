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
void OnRestart() {
    reference.OnRestart();
    gapMgr.OnRestart();

    // reset current time
    timer.SetStartTime();
}

// function to reset all variables
void OnChangeTrack() {
    OnRestart();

    // set change track / reset
    reference.OnChangeTrack();
    gapMgr.OnChangeTrack();

    // on longer saved
    isSaved = false;
}

// TODO: fix multilap (it will go completely wrong)

void Main() {
    // load all of the settings
    LoadSettings::All();
    
    // load the loaded settings into the relevant locations
    AssignSettings();

    // create the dist cache array
    MakeDistCacheArray();
}

void Update(float dt) {
    // if the plugin is off don't do anything
    if (!Settings::General::pluginEnabled) {
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

        OnChangeTrack();
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
        OnRestart();

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

    // -------------------------------------------------------------------------
    // adding points scripts

    PlayerData::Update();
    reference.OnUpdate();
    gapMgr.OnUpdate();

    // -------------------------------------------------------------------------
    // housekeeping

    // FOR DEBUG
    // V3::FileTest();
}

// save all settings on destruction
void Destroy() {
    SaveSettings::All();
}

// when ending, destroy safely
void OnDestroyed() { Destroy(); }
void OnDisabled() { Destroy(); }