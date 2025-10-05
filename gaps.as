// dist between the two points
float GetDist(Point p1, Point p2) {
    return Math::Sqrt((Math::Pow((p1.x - p2.x), 2) + Math::Pow((p1.y - p2.y), 2) + Math::Pow((p1.z - p2.z), 2)));
}

// TODO: improve gap algorithm
// COULD SEARCH EVERY N LOGS AND TAKE THE MINIMUM
// THEN SEARCH N - 1 EACH SIDE AND FIND THE MIN THERE
// (LIKELY FASTER OVERALL BECAUSE LESS ITEMS OVERALL SEARCHED)

// TODO: only check points after the previous selection (improves efficiency)
// TODO: add a maximum forward search distance or improve searching algorithm (better frame rate)

uint checkInterval = 30;

int GetMinDistIndex(Point@ currentPoint, Point[]@ points, int minCheckIdx, int maxCheckIdx, int interval) {
    // dont allow min idx less than 0
    if (minCheckIdx < 0) {
        minCheckIdx = 0;
    }

    // dont let max greater than length
    if (maxCheckIdx > points.Length) {
        maxCheckIdx = points.Length;
    }

    float curDist = 0;
    float minDist = 0;
    float minIdx = minCheckIdx;

    for (int p = minCheckIdx; p < maxCheckIdx; p += interval) {
        curDist = GetDist(points[p], currentPoint);
        // print(curDist);

        // if the current distance is less or at the start of loop
        if (curDist < minDist || p == minCheckIdx) {
            minDist = curDist;
            minIdx = p;
        }
    }

    // returns the minIdx
    return minIdx;
}

// need the misc array, current position and array of points
void SetGaps(Point currentPoint, array<Miscellaneous> @miscArray, array<array<Point>>@ ghostPoints) {
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

        int minIdx = GetMinDistIndex(currentPoint, ghostPoints[i], 0, miscArray[i].arraySize, checkInterval);

        // -----------------------------------------------------------------------------------
        // check checkInterval - 1 indexes either side of the current min to refine the min

        int checkIntervalTwo = 8;

        // check start for the second time
        int checkStart = minIdx - checkInterval;
        // check end for the second time
        int checkEnd = minIdx + checkInterval;

        // refine min index (EASIER TO INCLUDE THE CURRENT MIN AS WELL TO SAVE ON VARIABLES)
        // (AND THE PREVIOUS MIN IDX GUESS COULD HAVE BEEN THE SMALLEST)
        minIdx = GetMinDistIndex(currentPoint, ghostPoints[i], checkStart, checkEnd, checkIntervalTwo);
        
        // -----------------------------------------------------------------------------------
        // check checkInterval - 1 indexes either side of the current min to refine the min

        // check start
        checkStart = minIdx - checkIntervalTwo;
        // check end
        checkEnd = minIdx + checkIntervalTwo;

        // refine min index (EASIER TO INCLUDE THE CURRENT MIN AS WELL TO SAVE ON VARIABLES)
        // (AND THE PREVIOUS MIN IDX GUESS COULD HAVE BEEN THE SMALLEST)
        minIdx = GetMinDistIndex(currentPoint, ghostPoints[i], checkStart, checkEnd, 1);
        
        // -----------------------------------------------------------------------------------

        // FOR DEBUG
        // print(i);

        // set the gap based on the timestamps
        miscArray[i].gap = currentPoint.timeStamp - ghostPoints[i][minIdx].timeStamp;
    }
}