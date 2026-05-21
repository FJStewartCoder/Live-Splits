// TODO: improve gap algorithm

bool MeetsCheckLocationCriteria(
    SubSampleDefinition@ subSamples,
    PointLocation@ minCheckLoc,
    PointLocation@ maxCheckLoc
) {
    // check if the subsamples are from after this location
    // either greater lap or same lap greater checkpoint
    if (minCheckLoc !is null) {
        bool smallerLap = subSamples.lap < minCheckLoc.lap;
        bool sameLapSmallerCP = (subSamples.lap == minCheckLoc.lap) && (subSamples.checkpoint < minCheckLoc.cp);

        if (smallerLap || sameLapSmallerCP) { return false; }
    }

    // check if the subsamples are from before this location
    // either smaller lap or same lap smaller checkpoint
    if (maxCheckLoc !is null) {
        bool greaterLap = subSamples.lap > minCheckLoc.lap;
        bool sameLapGreaterCP = (subSamples.lap == minCheckLoc.lap) && (subSamples.checkpoint > minCheckLoc.cp);

        if (greaterLap || sameLapGreaterCP) { return false; }
    }

    return true;
}

uint GetMinDistIndex(
    Point@ currentPoint,
    array<Point>@ points,
    int minCheckIdx,
    int maxCheckIdx,
    uint interval = 1
) {
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

namespace GetGap {
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

    // function to optimise the intervals arrays based on the frame rate and logs per second
    // resolution defines how many checks per second should be done
    void Optimise(uint frameRate, uint resolution) {
        // get the number of logs per seconds and use it to get more accurate and optimised results

        // ------------------------------------------------------------------------------------------
        // +1 in case truncates
        int logsPerSecond = (frameRate / framesBetweenLog.GetCount()) + 1;
        // defines how many points are between each check (logs per second / resolution) e.g 100 per second, res = 2. So, check each 50 logs
        int gapBetweenChecks = (logsPerSecond / resolution) + 1;
        // based on the formula x/n + 2n (logs / checkInterval + 2 * checkInterval), which tells how many logs will be taken in total, we can calculate the optimal check interval for the smallest number of checks
        // THE BELOW FORMULA (DEFIINED IN OPTIMISATIONS.txt) is the least number of checks possible
        // +1 just in case
        int optimalSecondGap = Math::Sqrt(gapBetweenChecks / 2) + 1;
        
        // sets the checkIntervals
        checkIntervals = {gapBetweenChecks, optimalSecondGap, 1};
        // ------------------------------------------------------------------------------------------

        // set search radius for estimation to some number of seconds
        // currently searchs 2 seconds either side
        searchRadius = logsPerSecond * searchRangeSeconds;
    }

    // current position and array of points
    Point@ Full(Point @currentPoint, SampleArray@ reference, bool useLinear = false) {
        // if array not complete don't calculate gap
        // unless overridden
        // if (!arrayComplete && !getGapOverride) { return; }
            
        // ------------------------------------------------------------------------------------
        // get min index

        auto samples = reference.samples;

        // define some variables to start
        int minIdx = 0;
        int checkStart = 0;
        int checkEnd = samples.Length;

        // if linear, do a linear search
        if (useLinear) {
            minIdx = GetMinDistIndex(currentPoint, samples, checkStart, checkEnd);
        }
        else {
            // iterate all intervals in checkIntervals
            for (int interval = 0; interval < checkIntervals.Length; interval++) {
                // gets the min idx from the start to the end in intervals of interval
                minIdx = GetMinDistIndex(currentPoint, samples, checkStart, checkEnd, checkIntervals[interval]);

                // set the check start and check end for the next loop using the current interval
                // EXAMPLE: we currently iterate each 20, we need to check 20 each side next time
                checkStart = minIdx - checkIntervals[interval];
                checkEnd = minIdx + checkIntervals[interval];
            }
        }

        // TODO:
        // replace this with the location instead once I figure out how to do that    
        return samples[minIdx];
    }

    // need the misc array, current position and array of points
    Point@ OriginalEstimation(Point @currentPoint, SampleArray@ reference, bool useLinear = false) {
        /*
        // if array not complete don't calculate gap
        // unless overridden
        // if (!arrayComplete && !getGapOverride) { return; }
            
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
        */

        return null;
    }

    Point@ Best(Point @currentPoint, SampleArray@ reference, bool useLinear = false) {
        auto samples = reference.samples;

        PointLocation loc;
        loc.cp = PlayerData::cp;
        loc.lap = PlayerData::lap;

        ArrayRange range = reference.GetSampleRange(loc, loc);

        // define some variables to start
        int minIdx = 0;
        int checkStart = range.min;
        int checkEnd = range.max;

        // if linear, do a linear search
        if (useLinear) {
            minIdx = GetMinDistIndex(currentPoint, samples, checkStart, checkEnd);
        }
        else {
            // iterate all intervals in checkIntervals
            for (int interval = 0; interval < checkIntervals.Length; interval++) {
                // gets the min idx from the start to the end in intervals of interval
                minIdx = GetMinDistIndex(currentPoint, samples, checkStart, checkEnd, checkIntervals[interval]);

                // set the check start and check end for the next loop using the current interval
                // EXAMPLE: we currently iterate each 20, we need to check 20 each side next time
                checkStart = minIdx - checkIntervals[interval];
                checkEnd = minIdx + checkIntervals[interval];
            }
        }

        // TODO:
        // replace this with the location instead once I figure out how to do that    
        return samples[minIdx];
    }
}