// TODO: improve gap algorithm

class GapInfo {
    // the point closest to the desired point
    Point@ point = null;
    // the distance from point to player/ghost point
    float distance = 0;
    // the index that the point was found
    uint index = 0;

    // the evaluated gap
    int gap = 0;

    string ToString() {
        return "DIST: " + distance + ", IDX: " + index + ", GAP: " + gap;
    }
}


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
    ArrayRange range,
    uint interval = 1
) {
    // dont allow min idx less than 0
    if (range.min < 0) {
        range.min = 0;
    }

    // dont let max greater than length
    if (range.max > points.Length) {
        range.max = points.Length;
    }

    float curDist = 0;
    float minDist = 0;
    float minIdx = range.min;

    for (int p = range.min; p < range.max; p += interval) {
        curDist = GetDist(points[p], currentPoint);

        // if the current distance is less or at the start of loop
        if (curDist < minDist || p == range.min) {
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
        // TODO: reimplement
        // searchRadius = logsPerSecond * searchRangeSeconds;
    }

    // current position and array of points
    GapInfo Full(
        Point @currentPoint,
        SampleArray@ reference,
        uint startIdx = -1,
        uint endIdx = -1,
        bool useLinear = false
    ) {
        // if array not complete don't calculate gap
        // unless overridden
        // if (!arrayComplete && !getGapOverride) { return; }
            
        // ------------------------------------------------------------------------------------
        // get min index

        array<Point>@ samples = reference.samples;

        // define some variables to start
        int minIdx = 0;

        ArrayRange checkRange;

        // the check start is the startIdx or 0 if startIdx > length
        checkRange.min = (startIdx > samples.Length) ? 0 : startIdx;
        // the end index is the sample.length if endIdx is greater than length else it is endIdx
        checkRange.max = (startIdx > samples.Length) ? samples.Length : endIdx;

        // if linear, do a linear search
        if (useLinear) {
            minIdx = GetMinDistIndex(currentPoint, samples, checkRange);
        }
        else {
            // iterate all intervals in checkIntervals
            for (int interval = 0; interval < checkIntervals.Length; interval++) {
                // gets the min idx from the start to the end in intervals of interval
                minIdx = GetMinDistIndex(currentPoint, samples, checkRange, checkIntervals[interval]);

                // set the check start and check end for the next loop using the current interval
                // EXAMPLE: we currently iterate each 20, we need to check 20 each side next time
                checkRange.min = minIdx - checkIntervals[interval];
                checkRange.max = minIdx + checkIntervals[interval];
            }
        }

        // create a new return item
        GapInfo returnItem;

        // save the point
        @returnItem.point = samples[minIdx];
        // save the min index
        returnItem.index = minIdx;

        return returnItem;
    }

    // need the misc array, current position and array of points
    GapInfo Estimation(
        Point @currentPoint,
        SampleArray@ reference,
        uint estimatedIdx,
        uint searchRange = 75,

        // TODO: integrate these later
        uint startIdx = -1,
        uint endIdx = -1,
        bool useLinear = false
    ) {
        // get the list of samples
        array<Point>@ samples = reference.samples;

        // define some variables to start
        int minIdx = 0;

        ArrayRange checkRange;

        // the check start is the startIdx or 0 if startIdx > length
        checkRange.min = (startIdx > samples.Length) ? 0 : startIdx;
        // the end index is the sample.length if endIdx is greater than length else it is endIdx
        checkRange.max = (startIdx > samples.Length) ? samples.Length : endIdx;

        // if the estimated index is in the range, ensure that bounds are bound by the min and max entered by the user
        // if the estimated index is not in the range, trust the range
        if ( checkRange.IsBetween(estimatedIdx) ) {
            int min = estimatedIdx - searchRange;
            int max = estimatedIdx + searchRange;

            if (checkRange.IsBetween(min)) { checkRange.min = min; }
            if (checkRange.IsBetween(max)) { checkRange.min = min; }
        }

        if (useLinear) {
            minIdx = GetMinDistIndex(currentPoint, samples, checkRange, 1);
        }
        else {
            // iterate all intervals in checkIntervals
            for (int interval = 0; interval < checkIntervals.Length; interval++) {
                // gets the min idx from the start to the end in intervals of interval
                minIdx = GetMinDistIndex(currentPoint, samples, checkRange, checkIntervals[interval]);

                // set the check start and check end for the next loop using the current interval
                // EXAMPLE: we currently iterate each 20, we need to check 20 each side next time
                checkRange.min = minIdx - checkIntervals[interval];
                checkRange.max = minIdx + checkIntervals[interval];
            }
        }

        // create a new return item
        GapInfo returnItem;

        // save the point
        @returnItem.point = samples[minIdx];
        // save the min index
        returnItem.index = minIdx;

        return returnItem;
    }
}