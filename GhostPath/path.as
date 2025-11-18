// array of the main ghost's points
array<Point> ghostPoints(0);
bool arrayComplete = false;

Interpolater interpolater;


void ResizeArrays(uint runLength) {
    // resize the main array
    ghostPoints.Resize(runLength);
}

Point[] GhostSamplesToArray(CSceneVehicleVis::EntRecordDelta@[]@ samples) {
    // create an array of the length of the samples
    array<Point> pointArray(samples.Length);

    // create new points and add them to the array
    for (int i = 0; i < samples.Length; i++) {
        pointArray[i].x = samples[i].position.x;
        pointArray[i].y = samples[i].position.y;
        pointArray[i].z = samples[i].position.z;

        pointArray[i].timeStamp = samples[i].time;
    }

    return pointArray;
}

class Preloader {
    CSceneVehicleVis::EntRecordDelta@[]@[] allGhosts;
    
    // index of previous ghost
    int lastGhost;
    // index of current load
    int lastIndex;
    // point array for the previous car
    Point[] lastPoints;

    // is the entire process complete?
    bool isComplete = false;
    // is currently processing
    bool isProcessing = false;
    // is loading the ghost points
    bool isLoadingGhost = false;

    Miscellaneous miscTemp;

    // set all vars to default
    void Reset() {
        lastGhost = 0;
        lastIndex = 0;

        lastPoints.Resize(0);

        isComplete = false;
        isProcessing = false;
    }

    bool NextGhost() {
        // increment number of ghosts
        lastGhost++;

        // if already finished processing all ghosts, then return 0
        // else return 2 for more processing needed
        if (lastGhost == allGhosts.Length) {
            // no more ghosts
            return true;
        }

        // there are more ghosts
        return false;
    }

    // response codes:
    // 0 - success complete
    // 1 - no ghosts
    // 2 - incomplete load
    int PreloadPoints(uint pointsPerProcess = 10) {
        // startup processes
        if (!isProcessing) {
            // reset
            Reset();
    
            allGhosts = GetAllGhostSamples();

            // technically has complete the job but no ghosts
            if (allGhosts.Length == 0) { 
                isComplete = true;
                return 1;
            }

            isProcessing = true;

            // allows begining the next section
            isLoadingGhost = true;

            // begin the processing
            ResizeArrays(0);

            // get the ghost samples
            ghostPoints = GhostSamplesToArray(allGhosts[0]);

            // gives 0.010s precision
            interpolater.PassArgs(ghostPoints, 49);
        }

        if (isLoadingGhost) {
            // this also assigns data into the ghost points array
            int res = interpolater.InterpolateGhost(ghostPoints, 50);

            // if still processing, return the still processing warning
            if (res != 0) {
                return 2;
            }

            // this allows the gaps to be computed so must be before this point
            arrayComplete = true;

            // no longer loading so will not loop this
            isLoadingGhost = false;
        }

        // if the this is the first time preocessing this ghost
        // configure the setup for this ghost
        if (lastIndex == 0) {
            // reset the misc item for each ghost
            ResetMiscItem(miscTemp);

            // get the array of points
            lastPoints = GhostSamplesToArray(allGhosts[lastGhost]);

            // optionally interpolate the points
            // InterpolateGhost(points, 4);
        }

        // stores if currently finished with this ghost
        bool isFinishedThisGhost = false;

        // get the end idx
        int endIdx = lastIndex + pointsPerProcess;

        // some processing for if at the end
        if (endIdx > lastPoints.Length) {
            isFinishedThisGhost = true;
            endIdx = lastPoints.Length;
        }

        // begin at the last index
        // iterate n number of times until end idx
        // increment last index
        for (; lastIndex < endIdx; lastIndex++) {
            SetGaps::Estimation(lastPoints[lastIndex], ghostPoints, miscTemp, false);

            // great cache items for every point
            SetCacheItem(miscTemp.relGap, lastPoints[lastIndex].timeStamp, lastGhost + 1, miscTemp.lastIdx);
        }

        // if not finished simply return 2 (more processing needed)
        if (!isFinishedThisGhost) { return 2; }

        // if next ghost didn't fail (not finished)
        if (!NextGhost()) {
            // there are more ghosts so set lastIndex to 0 to reset the value
            lastIndex = 0;
            return 2;
        }

        print("Preloading complete");
        isComplete = true;

        return 0;
    }
}

class Interpolater {
    // basic vars to decide state
    bool isComplete = false;
    bool isProcessing = false;

    Point[] currentArray;
    uint levels = 4;

    // the pointer to the current location in the original array
    uint curPtr = 0;

    void PassArgs(Point[] @pointArray, uint interpolationLevels = 4) {
        currentArray = pointArray;
        levels = interpolationLevels;
    }

    // could use this for a non linear transform to the points
    float InterpolationFunc(float num) {
        return num;
    }

    void Reset() {
        isComplete = false;
        isProcessing = false;
        curPtr = 0;
    }

    // codes
    // 0 - complete successful
    // 1 - complete unsuccessful
    // 2 - incomplete
    int InterpolateGhost(Point[] @resultArray, uint pointsPerProcess = 10, bool useDithering = true) {
        if (!isProcessing) {
            Reset();

            // no points so do nothing
            if (currentArray.IsEmpty()) {
                isComplete = true;
                return 0;
            }
            
            // adding n number of points between each point
            // we will end up with ((len * 2) - 1)
            // example of 3 x n x n x (x is original, n is new) 3 -> 5
            // example of n new ones x nn x nn x 3 -> 7 ((len * (levels + 1)) - levels)

            uint newSize = (currentArray.Length * (levels + 1)) - levels;

            print("Converting ghost points of length " + currentArray.Length + " into length " + newSize);
            // gets the precision of the interpolation
            print((float(currentArray[1].timeStamp - currentArray[0].timeStamp) / (levels + 1)) / 1000);

            // set to length 0
            resultArray.Resize(0);

            // now currently processing
            isProcessing = true;
        }

        Point curPoint;
        Point nextPoint = currentArray[curPtr];
        
        // used to determine the finished state of the loop
        bool isFinished = false;
        uint endPtr = curPtr + pointsPerProcess;

        // ensure we only loop to the end
        if (endPtr > currentArray.Length - 1) {
            endPtr = currentArray.Length - 1;
            isFinished = true;
        }

        Point newPoint;

        for (; curPtr < endPtr; curPtr++) {
            // swap the points
            curPoint = nextPoint;
            nextPoint = currentArray[curPtr + 1];

            // add the current point
            resultArray.InsertLast(curPoint);

            // get interpolated points
            // if levels = 1 (1 new point) we need the point 1/2
            // levels = 2, we need points 1/3 and 2/3
            for (uint j = 1; j < levels + 1; j++) {
                // get the multiplier
                float multiplier = double(j) / (levels + 1);

                newPoint.x = ((nextPoint.x - curPoint.x) * multiplier) + curPoint.x;
                newPoint.y = ((nextPoint.y - curPoint.y) * multiplier) + curPoint.y;
                newPoint.z = ((nextPoint.z - curPoint.z) * multiplier) + curPoint.z;
                newPoint.timeStamp = ((nextPoint.timeStamp - curPoint.timeStamp) * multiplier) + curPoint.timeStamp;

                resultArray.InsertLast(newPoint);
            }
        }

        if (!isFinished) {
            return 2;
        }

        // result passing
        isComplete = true;
        isProcessing = false;

        // add the last point after the loop
        resultArray.InsertLast(nextPoint);

        return 0;
    }
}
