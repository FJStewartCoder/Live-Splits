/*
SYSTEM:
Log the player car's points per checkpoint and lap
If the player respawns, reset the current lap-checkpoint samples

STEPS:
Get the current sample list based on checkpoint and lap
Check respawn status

IF respawned
    reset current sample list

append current point to the current sample list
*/

/*
TODO:
- implement the frames between log in the logmgr class
- implement log per s seconds rather than per frames
*/

class LogMgr : SubReferenceMgr {
    // the current index to be logged
    uint currentLogIndex = 0;

    // a counter that is the number of frames between logging
    RotatingCounter framesBetweenLog(2);


    bool IsFinished() {
        return GetApp().CurrentPlayground.GameTerminals[0].UISequence_Current == SGamePlaygroundUIConfig::EUISequence::Finish;
        // return currentLogIndex > sampleArray.samples.Length + 0;
    }
    
    uint GetLapNumber() {
        auto a = MLFeed::GetRaceData_V4();
        auto b = a.get_LocalPlayer();

        return b.CurrentLap; 
    }

    uint GetCPNumber() {
        auto a = MLFeed::GetRaceData_V4();
        auto b = a.get_LocalPlayer();

        return b.spawnIndex; 
    }

    void LogPoint() {
        // only log points if not complete
        if (sampleArray.isComplete) { return; }

        CSceneVehicleVisState@ car = VehicleState::ViewingPlayerState();
        if (car is null) { return; }

        print(GetLapNumber() + " " + GetCPNumber());

        // we need a and b
        /*
        CSmPlayer@ a = GetApp().CurrentPlayground.Players[0];
        CSmScriptPlayer@ b = a.ScriptAPI;

        for (uint i = 0; i < b.LapWaypointTimes.Length; i++) {
            print(b.LapWaypointTimes[i]);
        }
        */

        CSmPlayer@ a = cast<CSmPlayer@>(GetApp().CurrentPlayground.GameTerminals[0].GUIPlayer);
        CSmScriptPlayer@ b = cast<CSmScriptPlayer>(a.ScriptAPI);
        auto c = a.Score;

        // counts the number of respawns
        c.NbRespawnsRequested;

        for (uint i = 0; i < b.LapWaypointTimes.Length; i++) {
            print(b.LapWaypointTimes[i]);
        }

        return;


        if (sampleArray.samples.Length == 0) {
            sampleArray.samples.InsertLast(SubSamples(0, 0));
        }

        // increment the counter
        framesBetweenLog.Increment();

        // check if we need to perform a log
        const bool performLog = framesBetweenLog.GetValue();
        if ( !performLog ) { return; }

        // check for size greater or equal to the hard limit
        if (currentLogIndex >= arrayMaxSize) {
            warn("Max array size hit");

            // if at limit the array must be complete
            sampleArray.SetComplete(true);
            return;
        }

        if (IsFinished()) {
            print("Logging finished");
            sampleArray.SetComplete(true);
            return;
        }

        // create the new point
        Point currentPoint;
        currentPoint.LoadFromState(car);

        // reassign a point if there is space for it else insert at the end the new point
        if (currentLogIndex >= sampleArray.samples.Length) {
            // set last point
            sampleArray.samples[0].samples.InsertLast(currentPoint);
        }
        else {
            // TODO: this no longer works
            sampleArray.samples[0].samples[currentLogIndex] = currentPoint;
        }

        // increment the log index
        currentLogIndex++;

        // debug print
        // print(car + " " + currentPoint.Get());
    }

    void Reset() override {
        // reset the sample array
        sampleArray.Reset();

        // reset log index
        currentLogIndex = 0;

        // reset the rotating counter
        framesBetweenLog.Reset();
    }

    LogMgr(SampleArray @sampleArray) {
        super(sampleArray);
    }
};