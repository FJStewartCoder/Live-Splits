// dist between the two points
float GetDist(Point p1, Point p2) {
    return Math::Sqrt((Math::Pow((p1.x - p2.x), 2) + Math::Pow((p1.y - p2.y), 2) + Math::Pow((p1.z - p2.z), 2)));
}

// TODO: improve gap algorithm
// TODO: only check points after the previous selection (improves efficiency)
// TODO: add a maximum forward search distance or improve searching algorithm (better frame rate)

// need the misc array, current position and array of points
void SetGaps(Point currentPoint, array<Miscellaneous> @miscArray, array<array<Point>> ghostPoints) {
    // iterate all cars lists
    for (int i = 0; i < miscArray.Length; i++) {
        // end of loop because this is all of the cars
        if (miscArray[i].id == 0) {
            break;
        }

        // if array not complete don't calculate gap
        if (!miscArray[i].isArrayComplete) {
            continue;
        }

        float minDist = 0;
        float curDist = 0;
        // index of the shortest distance
        int minIdx = 0;

        // iterate all points in current points array
        for (int p = 0; p < miscArray[i].arraySize; p++) {
            curDist = GetDist(ghostPoints[i][p], currentPoint);
            // print(curDist);

            if (curDist < minDist || p == 0) {
                minDist = curDist;
                minIdx = p;
            }
        }

        // FOR DEBUG
        // print(i);

        // TODO: FIX SOME INDEX OUT OF RANGE ERROR HERE
        // set the gap based on the timestamps
        miscArray[i].gap = currentPoint.timeStamp - ghostPoints[i][minIdx].timeStamp;
    }
}