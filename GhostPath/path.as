// array of the main ghost's points
array<Point> ghostPoints(0);
bool arrayComplete = false;


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

    // set all vars to default
    void Reset() {
        lastGhost = 0;
        lastIndex = 0;
        lastPoints.Resize(0);
        isComplete = false;
    }

    // response codes:
    // 0 - success complete
    // 1 - no ghosts
    // 2 - incomplete load
    int PreloadPoints() {
        allGhosts = GetAllGhostSamples();

        if (allGhosts.Length == 0) { return 1; }

        ResizeArrays(0);

        // get the ghost samples
        ghostPoints = GhostSamplesToArray(allGhosts[0]);

        // gives 0.010s precision
        InterpolateGhost(ghostPoints, 4);

        // this allows the gaps to be computed so must be before this point
        arrayComplete = true;

        Miscellaneous miscTemp;

        // iterate each other ghost and get the gaps and cache them all
        for (int i = 0; i < allGhosts.Length; i++) {
            lastPoints = GhostSamplesToArray(allGhosts[i]);
            // InterpolateGhost(points, 4);

            for (int p = 0; p < lastPoints.Length; p++) {
                SetGaps::Full(lastPoints[p], ghostPoints, miscTemp, false);

                // great cache items for every point
                SetCacheItem(miscTemp.relGap, lastPoints[p].timeStamp, i + 1, miscTemp.lastIdx);
            }
        }

        print("Preloading complete");

        return 0;
    }
}

// could use this for a non linear transform to the points
float InterpolationFunc(float num) {
    return num;
}

void InterpolateGhost(Point[] @pointArray, uint levels = 4) {
    // no points so do nothing
    if (pointArray.IsEmpty()) {
        return;
    }
    
    // adding n number of points between each point
    // we will end up with ((len * 2) - 1)
    // example of 3 x n x n x (x is original, n is new) 3 -> 5
    // example of n new ones x nn x nn x 3 -> 7 ((len * (levels + 1)) - levels)

    uint newSize = (pointArray.Length * (levels + 1)) - levels;

    print("Converting ghost points of length " + pointArray.Length + " into length " + newSize);
    // gets the precision of the interpolation
    print((float(pointArray[1].timeStamp - pointArray[0].timeStamp) / (levels + 1)) / 1000);

    // make new array of new size
    array<Point> newGhostPoints(newSize);

    uint curPtr = 0;

    Point curPoint;
    Point nextPoint = pointArray[0];

    for (uint i = 0; i < pointArray.Length - 1; i++) {
        // swap the points
        curPoint = nextPoint;
        nextPoint = pointArray[i + 1];

        // add the current point
        newGhostPoints[curPtr++] = curPoint;

        // get interpolated points
        // if levels = 1 (1 new point) we need the point 1/2
        // levels = 2, we need points 1/3 and 2/3
        for (uint j = 1; j < levels + 1; j++) {
            // get the multiplier
            float multiplier = double(j) / (levels + 1);

            newGhostPoints[curPtr].x = ((nextPoint.x - curPoint.x) * multiplier) + curPoint.x;
            newGhostPoints[curPtr].y = ((nextPoint.y - curPoint.y) * multiplier) + curPoint.y;
            newGhostPoints[curPtr].z = ((nextPoint.z - curPoint.z) * multiplier) + curPoint.z;
            newGhostPoints[curPtr].timeStamp = ((nextPoint.timeStamp - curPoint.timeStamp) * multiplier) + curPoint.timeStamp;

            // increment the current pointer once new point has been added
            curPtr++;
        }
    }

    // add the last point after the loop
    newGhostPoints[newGhostPoints.Length - 1] = nextPoint;

    // set ghost points to be new ghost points
    pointArray = newGhostPoints;
}