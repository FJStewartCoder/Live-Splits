class LogMgr {
    // array of the main ghost's points
    private array<Point@> loggedPoints(0); 
    // store the number of valid points
    private uint actualSize = 0;
    // have all of the points been logged
    private bool arrayComplete = false;

    // the current index to be logged
    private uint currentLogIndex = 0;

    void SetArrayComplete(bool value) {
        // set array complete to true or false based on the input
        arrayComplete = value;

        // if value is true, actualSize is the current log index, otherwise set to 0
        actualSize = (value) ? currentLogIndex : 0;
    }

    bool IsFinished() {
        return currentLogIndex > ghostPoints.Length + 0;
    }  

    void LogPoint(CSceneVehicleVisState @car) {
        // only log points if not complete
        if (arrayComplete) { return; }
        if (car is null) { return; }

        // check for size greater or equal to the hard limit
        if (currentLogIndex >= arrayMaxSize) {
            warn("Max array size hit");

            // if at limit the array must be complete
            SetArrayComplete(true);
            return;
        }

        if (IsFinished()) {
            print("Logging finished");
            SetArrayComplete(true);
            return;
        }

        Point currentPoint(currentCar);

        // reassign a point if there is space for it else insert at the end the new point
        if (currentLogIndex >= ghostPoints.Length) {
            // set last point
            ghostPoints.InsertLast(currentPoint);
        }
        else {
            ghostPoints[currentLogIndex] = currentPoint;
        }

        // increment the log index
        currentLogIndex++;

        // debug print
        // print(car + " " + currentPoint.Get());
    }

    void Reset() {
        // delete all points
        loggedPoints.Resize(0);

        // set incomplete
        SetArrayComplete(false);

        // reset log index
        currentLogIndex = 0;
    }
};