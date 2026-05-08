class LogMgr {
    // the list of samples
    private SampleArray@ sampleArray;

    // the current index to be logged
    private uint currentLogIndex = 0;


    bool IsFinished() {
        return currentLogIndex > ghostPoints.Length + 0;
    }  

    void LogPoint(CSceneVehicleVisState @car) {
        // only log points if not complete
        if (sampleArray.isComplete) { return; }
        if (car is null) { return; }

        // check for size greater or equal to the hard limit
        if (currentLogIndex >= arrayMaxSize) {
            warn("Max array size hit");

            // if at limit the array must be complete
            SampleArray.SetComplete(true);
            return;
        }

        if (IsFinished()) {
            print("Logging finished");
            SampleArray.SetComplete(true);
            return;
        }

        // create the new point
        Point currentPoint;
        currentPoint.LoadFromState(currentCar);

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
    }

    LogMgr(SampleArray @sampleArray) {
        this.sampleArray = sampleArray;
    }
};