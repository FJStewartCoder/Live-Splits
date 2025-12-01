// TODO: improve gap algorithm

int GetMinDistIndex(Point@ currentPoint, Point[]@ points, int minCheckIdx, int maxCheckIdx, uint interval) {
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

// used to specify in main which algorithm to use
enum GapAlgorithm {
    Full,
    Estimation
};

// function to convert numerical value to enum GapAlgorithm
GapAlgorithm intToEnum(int value) {
    GapAlgorithm enumValue = GapAlgorithm::Full;

    switch (value) {
        case 0:
            enumValue = GapAlgorithm::Full;
            break;
        case 1:
            enumValue = GapAlgorithm::Estimation;
            break;
        default:
            break;
    }

    return enumValue;
}

namespace SetGaps {
    // intervals in which the MODIFIED LINEAR algorithm will check
    // intervals between distance checks (reduces overall number of checks)
    // increasing this will improve efficiency but decrease accuracy
    // ACCURACY refers to how accurate the selection of closest point is
    // however, greater can help to filter out brief periods of crossing over the track
    array<uint> checkIntervals = {30, 8, 1};

    // how far either side of the last index will we search
    uint searchRadius = 500;

    // used to prevent 
    float distThreshold = -1;

    int PointsToGap(Point @p1, Point @p2) {
        // no threshold
        if (distThreshold == -1) {
            return p1.timeStamp - p2.timeStamp;
        }

        // only set gap if below threshold
        if (GetDist(p1, p2) <= distThreshold) {
            return p1.timeStamp - p2.timeStamp;
        }

        // fail so dist = 0
        return 0;
    }

    // function to optimise the intervals array based on the seconds between each gap and a desired resolution
    // resolution defines how many checks per second should be done
    void Optimise(float secondsBetweenGap, uint resolution) {
        // must be less than 1 and greater than 0
        if (secondsBetweenGap > 1 || secondsBetweenGap < 0) {
            print("Can not optimise for this value");
            return;
        }

        // get the number of logs per seconds and use it to get more accurate and optimised results

        // in order to calculate the intervals needed so we check resolution number times per second worth of gaps
        // STEP 1: how many gaps are there calculated per second
        // STEP 2: what interval do we need to check resolution number of times e.g 10 gaps per second, resolution = 2. We need to check every 5.
        // STEP 3: basically done

        // ------------------------------------------------------------------------------------------
        // STEP 1
        int logsPerSecond = 1 / secondsBetweenGap;

        // search size worth of 4 seconds
        searchRadius = logsPerSecond * 4;
        
        // STEP 2
        // defines how many points are between each check (logs per second / resolution) e.g 100 per second, res = 2. So, check each 50 logs
        int gapBetweenChecks = (logsPerSecond / resolution) + 1;

        // based on the formula x/n + 2n (logs / checkInterval + 2 * checkInterval), which tells how many logs will be taken in total, we can calculate the optimal check interval for the smallest number of checks
        // THE BELOW FORMULA (DEFIINED IN OPTIMISATIONS.txt) is the least number of checks possible
        // +1 just in case
        int optimalSecondGap = Math::Sqrt(gapBetweenChecks / 2) + 1;
        
        // sets the checkIntervals
        checkIntervals = {gapBetweenChecks, optimalSecondGap, 1};
    }

    // current position and array of points
    void Full(Point @currentPoint, Point[]@ ghostPoints, Miscellaneous @miscPtr, bool useLinear = false) {
        // if array not complete don't calculate gap
        // unless overridden
        if (!arrayComplete) {
            return;
        }
            
        // ------------------------------------------------------------------------------------
        // get min index

        // define some variables to start
        int minIdx = 0;
        int checkStart = 0;
        int checkEnd = ghostPoints.Length;

        // if linear, do a linear search
        if (useLinear) {
            minIdx = GetMinDistIndex(currentPoint, ghostPoints, checkStart, checkEnd, 1);
        }
        else {
            // iterate all intervals in checkIntervals
            for (int interval = 0; interval < checkIntervals.Length; interval++) {
                // gets the min idx from the start to the end in intervals of interval
                minIdx = GetMinDistIndex(currentPoint, ghostPoints, checkStart, checkEnd, checkIntervals[interval]);

                // set the check start and check end for the next loop using the current interval
                // EXAMPLE: we currently iterate each 20, we need to check 20 each side next time
                checkStart = minIdx - checkIntervals[interval];
                checkEnd = minIdx + checkIntervals[interval];
            }
        }
        
        // -----------------------------------------------------------------------------------

        // set the last index to the index we found the min value
        // SET THIS ANYWAY EVEN IF NOT USED INCASE SWITCHING BETWEEN ALGORITHMS
        // THIS WILL FIX ISSUES OF SWITCHING FROM FULL TO ESTIMATION
        miscPtr.lastIdx = minIdx;

        // set the gap based on the timestamps
        miscPtr.relGap = PointsToGap(currentPoint, ghostPoints[minIdx]);
    }

    // need the misc array, current position and array of points
    void Estimation(Point @currentPoint, Point[]@ ghostPoints, Miscellaneous @miscPtr, bool useLinear = false) {
        // if array not complete don't calculate gap
        // unless overridden
        if (!arrayComplete) {
            return;
        }
            
        // ------------------------------------------------------------------------------------
        // get min index

        // define some variables to start
        int minIdx = 0;
        // get the start and end of our estimated search
        int checkStart = miscPtr.lastIdx - searchRadius;
        int checkEnd = miscPtr.lastIdx + searchRadius;

        if (useLinear) {
            minIdx = GetMinDistIndex(currentPoint, ghostPoints, checkStart, checkEnd, 1);
        }
        else {
            // iterate all intervals in checkIntervals
            for (int interval = 0; interval < checkIntervals.Length; interval++) {
                // gets the min idx from the start to the end in intervals of interval
                minIdx = GetMinDistIndex(currentPoint, ghostPoints, checkStart, checkEnd, checkIntervals[interval]);

                // set the check start and check end for the next loop using the current interval
                // EXAMPLE: we currently iterate each 20, we need to check 20 each side next time
                checkStart = minIdx - checkIntervals[interval];
                checkEnd = minIdx + checkIntervals[interval];
            }
        }

        // -----------------------------------------------------------------------------------

        // set the last index to the index we found the min value
        miscPtr.lastIdx = minIdx;

        // set the gap based on the timestamps
        miscPtr.relGap = PointsToGap(currentPoint, ghostPoints[minIdx]);
    }
}