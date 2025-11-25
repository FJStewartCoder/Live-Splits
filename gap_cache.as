class CacheEntry {
    // the gap
    int gap;
    // the timeStamp that the gap was observed
    uint timeStamp;
    // the index of the lastIdx (fixes issue with reseting whilst caching using estimation)
    uint idx = 0;
}

// this is returned to the user when they request a cached gap
// gap can be error val if error
class CacheReturnItem {
    bool isError = false;
    // code for the error for easier diagnosis of errors
    uint errorCode = 0;

    int gap = 0;
    uint idx = 0;

    string GetErrorName() {
        string errorDesc = "";

        switch (errorCode) {
            case 1:
                errorDesc = "This ID was not found";
                break;
            case 2:
                errorDesc = "There are no points";
                break;
            case 3:
                errorDesc = "The timestamp is after the end of the array";
                break;
            case 4:
                errorDesc = "Approximation error";
                break;
            default:
                errorDesc = "Unknown Error";
                break;
        }

        return errorDesc;
    }

    string Get() {
        if (isError) {
            return "Error Code " + errorCode + ": " + GetErrorName();
        }

        return "Gap: " + gap + " Index: " + idx;
    }
};

const int errorVal = uint(-1) >> 1;

// 2d array of cache entries

// ARRAY IS STRUCTED AS BELOW
// item 0 is gap = 0, timeStamp = id of the relevant car
// all subsequent items are actual cache entries
array<array<CacheEntry>> cacheArray(0, array<CacheEntry>(0));

// reset all array lengths to 0
void ResetCacheArray() {
    // iterate each array and resize to 0
    for (int i = 0; i < cacheArray.Length; i++) {
        cacheArray[i].Resize(0);
    }

    // resize main array to 0
    cacheArray.Resize(0);
}

// ----------------------------------------------------------

CacheEntry MakeCacheEntry(int gap, uint timeStamp, uint idx = 0) {
    CacheEntry newEntry;

    newEntry.gap = gap;
    newEntry.timeStamp = timeStamp;
    newEntry.idx = idx;

    return newEntry;
}

// ----------------------------------------------------------

// idx is the cacheArray index of the array to search
// value is the timestamp to search for
// returns index of closest value
uint BinarySearch(uint idx, uint value) {
    // begin at 1 because 0 is id
    uint l = 1;
    // length -1 to get the last index
    uint r = cacheArray[idx].Length - 1;

    // index of the midpoint
    uint mid;

    while (l <= r) {
        mid = (l + r) / 2;

        if (cacheArray[idx][mid].timeStamp == value) {
            // if got value, return value
            return mid;
        }
        else if (value > cacheArray[idx][mid].timeStamp) {
            l = mid + 1;
        }
        else {
            r = mid - 1;
        }
    }

    return mid;
}

// returns uint(-1) if not found
// returns index if found
uint GetArray(uint id) {
    // linear search to find the relevant cache array
    for (uint i = 0; i < cacheArray.Length; i++) {
        // based on the array specification, timestamp of the first item is the id
        if (cacheArray[i][0].timeStamp == id) {
            // return index if found
            return i;
        }
    }

    // if not found return error
    return uint(-1);
}

uint CalculateApproximation(CacheEntry @prevCache, CacheEntry @nextCache, uint timeStamp, uint tolerance = 5000) {
    // the total time difference between current and other cache's timestamps
    // get the timestamp difference from the bigger - smaller
    float timeDiff = nextCache.timeStamp - prevCache.timeStamp;

    // if timediff is too great, then return failure
    if (timeDiff > float(tolerance)) {
        return uint(-1);
    }

    // the time difference from the timeStamp to the previous cache's timeStamp
    // gets the gap between the timestamp and the previous cache
    float myDiff = timeStamp - prevCache.timeStamp;

    // get the difference between the gaps
    float gapDiff = nextCache.gap - prevCache.gap;

    // the percentage of the gap that we need to get
    float gapMultiplier = myDiff / timeDiff;

    // calculate the actual gap number using the multiplier
    int approximateGapDiff = gapDiff * gapMultiplier;

    // DEBUG PRINTS
    // print("pts " + prevCache.timeStamp + " nts " + nextCache.timeStamp + " cts " + timeStamp);
    // print("pg " + prevCache.gap + " ng " + nextCache.gap + " cts " + approximateGapDiff);

    // return the gap approximation + the previous gap
    return prevCache.gap + approximateGapDiff;
}

// function to estimate the gap based on the cache entries
// can return uint(-1) if the time difference is too great
uint ApproximateGap(uint arrayIdx, uint cacheIdx, uint timeStamp) {
    // e.g 12, 14, 20
    // because 14 is 2/8 between the surrounding points get the time diff between 12 and 20 and multiply by 2/8
    // add this to the time at 12 to get the approximate time gap
    CacheEntry @curCache = cacheArray[arrayIdx][cacheIdx];

    // three scenarios:
    // same timeStamp (just return the gap)
    // timeStamp is less than the curCache timestamp (previous idx is prev, current idx is next)
    // else timeStamp is greater than the curCache timestamp (cur idx is prev, next idx is next)

    if (curCache.timeStamp == timeStamp) {
        return curCache.gap;
    }

    if (timeStamp < curCache.timeStamp) {
        // if there are no entries before, we can not continue
        if (cacheIdx == 1) {
            return curCache.gap;
        }

        // other cache is previous cache
        CacheEntry @otherCache = cacheArray[arrayIdx][cacheIdx - 1];

        return CalculateApproximation(otherCache, curCache, timeStamp, 500);
    }
    else {
        // if there are no entries after the current one
        if (cacheIdx == cacheArray[arrayIdx].Length - 1) {
            return curCache.gap;
        }

        // other cache is the next one
        CacheEntry @otherCache = cacheArray[arrayIdx][cacheIdx + 1];

        return CalculateApproximation(curCache, otherCache, timeStamp, 500);
    }
}

// tolerance is the number of milliseconds difference that the gap can be for a cache to be denied
CacheReturnItem GetCacheItem(uint timeStamp, uint id) {
    CacheReturnItem item;

    // get the index of the array based on id
    uint cacheArrayIndex = GetArray(id);

    // if not found, return 0
    if (cacheArrayIndex == uint(-1)) {
        item.isError = true;
        item.errorCode = 1;

        return item;
    }

    // if there are no entries then return 0 as well
    if (cacheArray[cacheArrayIndex].Length == 1) {
        item.isError = true;
        item.errorCode = 2;

        return item;
    }

    // binary search the cache array to find the closest timestamp
    uint closestIdx = BinarySearch(cacheArrayIndex, timeStamp);

    // --------------------------------------------------------------------------------
    // check to ensure that there are points after the current point
    // will ensure there are enough cache items
    // PREVENTS A BUG WHERE THE PREVIOUS CACHE ITEM GETS USED CAUSING NO CACHE ENTRTIES TO BE EVER CREATED

    CacheEntry[] @curArray = cacheArray[cacheArrayIndex];

    if (curArray[curArray.Length - 1].timeStamp < timeStamp) {
        item.isError = true;
        item.errorCode = 3;

        return item;
    }

    // --------------------------------------------------------------------------------

    uint curGap = cacheArray[cacheArrayIndex][closestIdx].gap;

    // fill in the data of the return item
    item.isError = false;
    item.gap = curGap;
    item.idx = cacheArray[cacheArrayIndex][closestIdx].idx;

    // return the gap
    return item;
}

void SetCacheItem(int gap, uint timeStamp, uint id, uint idx) {
    // get the index of the array based on id
    uint cacheArrayIndex = GetArray(id);

    // if not found, return 0
    if (cacheArrayIndex == uint(-1)) {
        // create a new array with a new cache entry that stores the id as timestamp
        array<CacheEntry> newArray = {MakeCacheEntry(0, id, idx)};
        // insert last the new array
        cacheArray.InsertLast(newArray);

        // set the index to the new last item
        cacheArrayIndex = cacheArray.Length - 1;
    }

    CacheEntry[]@ arrayPtr = cacheArray[cacheArrayIndex];

    // if no entries insert last the new entry
    if (arrayPtr.Length == 1) {
        arrayPtr.InsertLast(MakeCacheEntry(gap, timeStamp, idx));
        return;
    }

    uint insertIdx = uint(-1);

    // search for where to insert
    insertIdx = BinarySearch(cacheArrayIndex, timeStamp);
    
    // if timestamp is same then we don't need to add the same value again
    if (arrayPtr[insertIdx].timeStamp == timeStamp) {
        return;
    }

    // if timestamp to insert is greater than the one at the insertIdx, we need to insert after so increment insertIdx
    if (timeStamp > arrayPtr[insertIdx].timeStamp) {
        // 1, 2, 4, 5, 6, 7, 8, 9
        // we would insert 3 at index 2
        // if bin search returned idx 1, the tstamp would be 2, we want +1 idx
        // if returned idx 2, tstamp is 4 which is bigger so do nothing
        insertIdx++;
    }

    // insert the item
    arrayPtr.InsertAt(insertIdx, MakeCacheEntry(gap, timeStamp, idx));
}
