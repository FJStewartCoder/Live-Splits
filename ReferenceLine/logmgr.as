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


    bool IsFinished() {
        return GetApp().CurrentPlayground.GameTerminals[0].UISequence_Current == SGamePlaygroundUIConfig::EUISequence::Finish;
        // return currentLogIndex > sampleArray.samples.Length + 0;
    }

    void LogPoint() {
        // only log points if not complete
        if (sampleArray.isComplete) { return; }

        CSceneVehicleVisState@ car = VehicleState::ViewingPlayerState();
        if (car is null) { return; }

        // print(PlayerData::lap + " " + PlayerData::cp);

        if (PlayerData::hasRespawned) {
            print('Player has respawned; deleting current samples');

            // TODO: fix
            // get the range of this checkpoint
            ArrayRange thisCheckpointRange = sampleArray.GetSampleRange(
                PointLocation(), PointLocation()
            );
            // delete this checkpoint's samples
            sampleArray.DeleteSamples(thisCheckpointRange);
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

        if (IsFinished()) {
            print("Logging finished");
            sampleArray.SetComplete(true);
            return;
        }

        // create the new point
        Point currentPoint;
        currentPoint.LoadFromState(car);

        // insert the new sample
        // TODO: set this accurately
        sampleArray.AppendSample(currentPoint, 0, 0);

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