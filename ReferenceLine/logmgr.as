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
    // a counter that is the number of frames between logging
    RotatingCounter framesBetweenLog(1);


    const bool IsFinished() {
        return GetApp().CurrentPlayground.GameTerminals[0].UISequence_Current == SGamePlaygroundUIConfig::EUISequence::Finish;
    }

    // checks if the first log is within 0.25 of the start
    const bool LoggedFromStart() {
        // if there are no logs, then it must be from the start
        if (sampleArray.samples.IsEmpty()) { return true; }

        // get the rules
        CSmArenaRulesMode@ rules = cast<CSmArenaRulesMode@>(GetApp().PlaygroundScript);

        // TODO: this could be useful
        // rules.Ghost_GetPosition();

        Point@ firstPoint = sampleArray.samples[0];

        // iterate all of the landmarks
        // if the landmark is a start (should only be one), then check if the distance is less than some threshold away from the first record
        // if it is, then the ghost must have logged from the start
        for (uint i = 0; i < rules.MapLandmarks.Length; i++) {
            auto landmark = rules.MapLandmarks[i];
            const bool isStart = landmark.PlayerSpawn !is null;

            if (!isStart) { continue; }

            vec3 startPos = landmark.Position;
            Point startPoint(startPos.x, startPos.y, startPos.z);

            // if the dist is valid, return true
            // TODO: optimise this dist
            if (GetDist(firstPoint, startPoint) < 20) {
                return true;
            }
        }

        // if we get here, we were nowhere near the start
        return false;
    }

    void LogPoint() {
        // only log points if not complete
        if (sampleArray.isComplete) { return; }

        CSceneVehicleVisState@ car = VehicleState::ViewingPlayerState();
        if (car is null) { return; }

        // print(PlayerData::lap + " " + PlayerData::cp);

        if (PlayerData::hasRespawned) {
            print('Player has respawned; deleting current samples');

            // delete this checkpoint's samples
            sampleArray.DeleteSubSamples(PlayerData::lap, PlayerData::cp);
        }

        // increment the counter
        framesBetweenLog.Increment();

        // check if we need to perform a log
        const bool performLog = framesBetweenLog.GetValue();
        if ( !performLog ) { return; }

        /*
        // check for size greater or equal to the hard limit
        if (currentLogIndex >= arrayMaxSize) {
            warn("Max array size hit");

            // if at limit the array must be complete
            sampleArray.SetComplete(true);
            return;
        }
        */

        if (IsFinished() && LoggedFromStart()) {
            print("Logging finished");
            sampleArray.SetComplete(true);
            return;
        }

        // create the new point
        Point currentPoint;
        currentPoint.LoadFromState(car);

        // insert the new sample
        // TODO: set this accurately
        sampleArray.AppendSample(currentPoint, PlayerData::lap, PlayerData::cp);

        // debug print
        // print(car + " " + currentPoint.Get());
    }

    void Reset() override {
        // reset the sample array
        sampleArray.Reset();

        // reset the rotating counter
        framesBetweenLog.Reset();
    }

    void OnRestart() override {
        if (!sampleArray.isComplete) {
            Reset();
        }
    }

    LogMgr(SampleArray @sampleArray) {
        super(sampleArray);
    }
};