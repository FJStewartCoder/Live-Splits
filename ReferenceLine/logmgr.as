class LogMgr {
    // the list of samples
    SampleArray@ sampleArray;

    // the current index to be logged
    uint currentLogIndex = 0;

    // a counter that is the number of frames between logging
    RotatingCounter framesBetweenLog(6);


    bool IsFinished(CSceneVehicleVisState@ car) {
        return GetApp().CurrentPlayground.GameTerminals[0].UISequence_Current == SGamePlaygroundUIConfig::EUISequence::Finish;
        // return currentLogIndex > sampleArray.samples.Length + 0;
    }  

    void LogPoint(CSceneVehicleVisState @car) {
        // only log points if not complete
        if (sampleArray.isComplete) { return; }
        if (car is null) { return; }

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

        if (IsFinished(car)) {
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
            sampleArray.samples.InsertLast(currentPoint);
        }
        else {
            sampleArray.samples[currentLogIndex] = currentPoint;
        }

        // increment the log index
        currentLogIndex++;

        // debug print
        // print(car + " " + currentPoint.Get());
    }

    void Reset() {
        // reset the sample array
        sampleArray.Reset();

        // reset log index
        currentLogIndex = 0;

        // reset the rotating counter
        framesBetweenLog.Reset();
    }

    LogMgr(SampleArray @sampleArray) {
        @this.sampleArray = sampleArray;
    }

    LogMgr() {}
};



// TODO:
// implement the frames between log in the logmgr class