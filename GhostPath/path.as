// array of the main ghost's points
array<Point> ghostPoints(0);
bool arrayComplete = false;


void ResizeArrays(uint runLength) {
    // resize the main array
    ghostPoints.Resize(runLength);
}

int GetPoints() {
    auto allGhosts = GetAllGhosts();

    if (allGhosts.Length == 0) { return 1; }

    ResizeArrays(0);

    for (int i = 0; i < allGhosts[0].Length; i++) {
        Point newPoint;

        newPoint.x = allGhosts[0][i].position.x;
        newPoint.y = allGhosts[0][i].position.y;
        newPoint.z = allGhosts[0][i].position.z;

        newPoint.timeStamp = allGhosts[0][i].time;

        ghostPoints.InsertLast(newPoint);
    }

    // gives 0.010s precision
    InterpolateGhost(4);
    print("Complete");

    arrayComplete = true;

    return 0;
}

// could use this for a non linear transform to the points
float InterpolationFunc(float num) {
    return num;
}

void InterpolateGhost(uint levels = 4) {
    // adding n number of points between each point
    // we will end up with ((len * 2) - 1)
    // example of 3 x n x n x (x is original, n is new) 3 -> 5
    // example of n new ones x nn x nn x 3 -> 7 ((len * (levels + 1)) - levels)

    uint newSize = (ghostPoints.Length * (levels + 1)) - levels;

    print("Converting ghost points of length " + ghostPoints.Length + " into length " + newSize);
    print((float(ghostPoints[1].timeStamp - ghostPoints[0].timeStamp) / (levels + 1)) / 1000);

    // make new array of new size
    array<Point> newGhostPoints(newSize);

    uint curPtr = 0;

    Point curPoint;
    Point nextPoint = ghostPoints[0];

    for (uint i = 0; i < ghostPoints.Length - 1; i++) {
        // swap the points
        curPoint = nextPoint;
        nextPoint = ghostPoints[i + 1];

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
    ghostPoints = newGhostPoints;
}