// TODO: re-implement the max cache size
// TODO: re-implement the approximation thing





// this is returned to the user when they request a cached gap
// gap can be error val if error
class CacheReturnItem {
    bool isError = false;
    CacheEntry@ entry = null;
};

class CacheEntry {
    // the gap
    int gap;
    // the timeStamp that the gap was observed
    uint timeStamp;
    // the index of the lastIdx (fixes issue with reseting whilst caching using estimation)
    uint idx = 0;

    CacheEntry(int gap, uint tstamp, uint idx = 0) {
        this.gap = gap;
        this.timeStamp = tstamp;
        this.idx = idx;
    }

    CacheEntry() {}
}

class GapCache {
    array<CacheEntry> cacheEntries;

    uint cacheHits = 0;
    uint cacheAttempts = 0;

    // perform a binary search thing on the list
    uint CacheSearch(uint tstamp) {
        // begin at 1 because 0 is id
        int l = 0;
        // length -1 to get the last index
        int r = cacheEntries.Length - 1;

        // index of the midpoint
        int mid;

        while (l <= r) {
            mid = (l + r) / 2;

            CacheEntry@ entry = cacheEntries[mid];

            if (entry.timeStamp == tstamp) {
                // if got value, return value
                return mid;
            }
            else if (tstamp > entry.timeStamp) {
                l = mid + 1;
            }
            else {
                r = mid - 1;
            }
        }

        return mid;
    }

    CacheReturnItem GetCache(uint time, uint threshold = uint(-1)) {
        // increment the cache attempts
        cacheAttempts++;

        CacheReturnItem returnItem;

        // if there are no entries, it is not possible to get cache
        if (cacheEntries.IsEmpty()) {
            returnItem.isError = true;
            return returnItem;
        }

        // find the closest index
        uint foundIdx = CacheSearch(time);
        // get the closest item
        CacheEntry@ foundItem = cacheEntries[foundIdx];

        // calculate if the item is difference to the time is greater than threshold
        const bool greaterThanThreshold = Math::Abs(int(foundItem.timeStamp) - time) > threshold;

        // check if the foundIdx indicates that the it was the most recently added item
        // this will be true if the timestamp is less the timestamp to search for and the item is the last item
        const bool isRecentlyAdded = (foundItem.timeStamp < time) && (foundIdx == cacheEntries.Length - 1);

        // if there is an error set the error to true
        // if either we are greater than the threshold and we are using a threshold or it is the recently added item
        if ( (greaterThanThreshold && threshold != uint(-1)) || isRecentlyAdded ) {
            returnItem.isError = true;
        }
        else {
            // set the entry to the found item
            @returnItem.entry = foundItem;
            // increment the cache hits
            cacheHits++;
        }

        // return the cache item
        return returnItem;
    }

    void AddCache(int gap, uint timeStamp, uint idx) {
        // create a new entry
        CacheEntry entry(gap, timeStamp, idx);

        // if there are no current entries, insert the entry in the last position
        if (cacheEntries.IsEmpty()) {
            cacheEntries.InsertLast(entry);
            return;
        }

        // find where to insert it
        uint insertionIdx = CacheSearch(timeStamp);

        // if the timestamp is greater than the item at the insert index, insert at the index after this
        if (timeStamp > cacheEntries[insertionIdx].timeStamp) {
            insertionIdx++;
        }

        // insert the entry at the insertion index
        cacheEntries.InsertAt(insertionIdx, entry);
    }

    void Reset() {
        cacheEntries.Resize(0);
        cacheAttempts = 0;
        cacheHits = 0;
    }
}


// TODO: fix the below things


/*
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
CacheReturnItem GetCacheItem(uint timeStamp, uint id, bool useApproximation = false) {
    CacheReturnItem item;

    // get the index of the array based on id
    uint cacheArrayIndex = GetArray(id);

    // if not found, return 0
    if (cacheArrayIndex == uint(-1)) {
        item.isError = true;
        return item;
    }

    // if there are no entries then return 0 as well
    if (cacheArray[cacheArrayIndex].Length == 1) {
        item.isError = true;
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
        return item;
    }

    // --------------------------------------------------------------------------------

    uint curGap;

    // if using approx, use the approx func
    if (useApproximation) {
        curGap = ApproximateGap(cacheArrayIndex, closestIdx, timeStamp);

        if (curGap == uint(-1)) {
            item.isError = true;
            return item;
        }
    }
    // else get the gap of the closest index
    else {
        curGap = cacheArray[cacheArrayIndex][closestIdx].gap;
    }

    // fill in the data of the return item
    item.isError = false;
    item.gap = curGap;
    item.idx = cacheArray[cacheArrayIndex][closestIdx].idx;

    // return the gap
    return item;
}
*/