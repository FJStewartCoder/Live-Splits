// dist between the two points
float GetDist(Point p1, Point p2) {
    return Math::Sqrt((Math::Pow((p1.x - p2.x), 2) + Math::Pow((p1.y - p2.y), 2) + Math::Pow((p1.z - p2.z), 2)));
}

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
    Linear,
    ModifiedLinear,
    Estimation
};

namespace SetGaps {
   // intervals in which the MODIFIED LINEAR algorithm will check
    // intervals between distance checks (reduces overall number of checks)
    // increasing this will improve efficiency but decrease accuracy
    // ACCURACY refers to how accurate the selection of closest point is
    // however, greater can help to filter out brief periods of crossing over the track
    // one universal array for this
    array<uint> checkIntervals = {30, 8, 1};

    // function to optimise the intervals arrays based on the frame rate and logs per second
    // resolution defines how many checks per second should be done
    void Optimise(uint frameRate, uint resolution) {
        // get the number of logs per seconds and use it to get more accurate and optimised results

        // +1 in case truncates
        int logsPerSecond = (frameRate / framesBetweenLog.GetCount()) + 1;
        // defines how many points are between each check (logs per second / resolution) e.g 100 per second, res = 2. So, check each 50 logs
        int gapBetweenChecks = (logsPerSecond / resolution) + 1;
        // based on the formula x/n + 2n (logs / checkInterval + 2 * checkInterval), which tells how many logs will be taken in total, we can calculate the optimal check interval for the smallest number of checks
        // THE BELOW FORMULA (DEFIINED IN OPTIMISATIONS.txt) is the least number of checks possible
        int optimalSecondGap = Math::Sqrt(gapBetweenChecks / 2);

        print(logsPerSecond + " " + gapBetweenChecks);
        
        // sets the checkIntervals
        checkIntervals = {gapBetweenChecks, optimalSecondGap, 1};

        print(checkIntervals[0] + " " + checkIntervals[1]);
    }

    // need the misc array, current position and array of points
    void Linear(Point currentPoint, array<Miscellaneous> @miscArray, array<array<Point>>@ ghostPoints) {
        // iterate all cars lists
        for (int i = 0; i < miscArray.Length; i++) {
            // end of loop because this is all of the cars
            if (miscArray[i].id == 0) {
                break;
            }

            // if array not complete don't calculate gap
            // unless overridden
            if (!miscArray[i].isArrayComplete && !getGapOverride) {
                continue;
            }

            // get min index by iterating each item in array
            int minIdx = GetMinDistIndex(currentPoint, ghostPoints[i], 0, miscArray[i].arraySize, 1);
            
            // -----------------------------------------------------------------------------------

            // FOR DEBUG
            // print(i);

            // set the gap based on the timestamps
            miscArray[i].gap = currentPoint.timeStamp - ghostPoints[i][minIdx].timeStamp;
        }
    }

    // need the misc array, current position and array of points
    void ModifiedLinear(Point currentPoint, array<Miscellaneous> @miscArray, array<array<Point>>@ ghostPoints) {
        // iterate all cars lists
        for (int i = 0; i < miscArray.Length; i++) {
            // end of loop because this is all of the cars
            if (miscArray[i].id == 0) {
                break;
            }

            // if array not complete don't calculate gap
            // unless overridden
            if (!miscArray[i].isArrayComplete && !getGapOverride) {
                continue;
            }
            
            // ------------------------------------------------------------------------------------
            // get min index

            // define some variables to start
            int minIdx = 0;
            int checkStart = 0;
            int checkEnd = miscArray[i].arraySize;

            // get the intervals array
            array<uint> intervals = checkIntervals;


            // iterate all intervals in checkIntervals
            for (int interval = 0; interval < intervals.Length; interval++) {
                // gets the min idx from the start to the end in intervals of interval
                minIdx = GetMinDistIndex(currentPoint, ghostPoints[i], checkStart, checkEnd, intervals[interval]);

                // set the check start and check end for the next loop using the current interval
                // EXAMPLE: we currently iterate each 20, we need to check 20 each side next time
                checkStart = minIdx - intervals[interval];
                checkEnd = minIdx + intervals[interval];
            }
            
            // -----------------------------------------------------------------------------------

            // FOR DEBUG
            // print(i);

            // set the gap based on the timestamps
            miscArray[i].gap = currentPoint.timeStamp - ghostPoints[i][minIdx].timeStamp;
        }
    }

    // need the misc array, current position and array of points
    void Estimation(Point currentPoint, array<Miscellaneous> @miscArray, array<array<Point>>@ ghostPoints) {
        // iterate all cars lists
        for (int i = 0; i < miscArray.Length; i++) {
            // end of loop because this is all of the cars
            if (miscArray[i].id == 0) {
                break;
            }

            // if array not complete don't calculate gap
            // unless overridden
            if (!miscArray[i].isArrayComplete && !getGapOverride) {
                continue;
            }
            
            // ------------------------------------------------------------------------------------
            // get min index

            // define some variables to start
            int minIdx = 0;
            // get the start and end of our estimated search
            int checkStart = miscArray[i].lastIdx - searchRadius;
            int checkEnd = miscArray[i].lastIdx + searchRadius;

            // get the intervals array
            array<uint> intervals = checkIntervals;

            // iterate all intervals in checkIntervals
            for (int interval = 0; interval < intervals.Length; interval++) {
                // gets the min idx from the start to the end in intervals of interval
                minIdx = GetMinDistIndex(currentPoint, ghostPoints[i], checkStart, checkEnd, intervals[interval]);

                // set the check start and check end for the next loop using the current interval
                // EXAMPLE: we currently iterate each 20, we need to check 20 each side next time
                checkStart = minIdx - intervals[interval];
                checkEnd = minIdx + intervals[interval];
            }

            // -----------------------------------------------------------------------------------

            // FOR DEBUG
            // print(i);

            // set the gap based on the timestamps
            miscArray[i].gap = currentPoint.timeStamp - ghostPoints[i][minIdx].timeStamp;
            // set the last index to the index we found the min value
            miscArray[i].lastIdx = minIdx;
        }
    }
}