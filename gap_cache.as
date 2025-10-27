class CacheEntry {
    // the gap
    int gap;
    // the timeStamp that the gap was observed
    uint timeStamp;
}

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

CacheEntry MakeCacheEntry(int gap, uint timeStamp) {
    CacheEntry newEntry;

    newEntry.gap = gap;
    newEntry.timeStamp = timeStamp;

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

// tolerance is the number of milliseconds difference that the gap can be for a cache to be denied
int GetCacheItem(uint timeStamp, uint id, uint tolerance = 1000) {
    // get the index of the array based on id
    uint cacheArrayIndex = GetArray(id);

    // if not found, return 0
    if (cacheArrayIndex == uint(-1)) {
        return errorVal;
    }

    // if there are no entries then return 0 as well
    if (cacheArray[cacheArrayIndex].Length == 1) {
        return errorVal;
    }

    // binary search the cache array to find the closest timestamp
    uint closestIdx = BinarySearch(cacheArrayIndex, timeStamp);
    CacheEntry @curCache = cacheArray[cacheArrayIndex][closestIdx];

    // TODO: add some approximation based on how much between the points the time stamp is
    // e.g 12, 14!, 20
    // because 14 is 2/8 between the surrounding points get the time diff between 12 and 20 and multiply by 2/8
    // add this to the time at 12 to get the approximate time gap

    uint curGap = curCache.gap;

    // checks for if the closest time stamp is within a sensible range (e.g 0.5s away)
    // this is 1 second deviation allowed
    float timeDiff = Math::Abs(curCache.timeStamp - timeStamp);

    if (timeDiff > tolerance) {
        return errorVal;
    }

    // return the gap
    return curGap;
}

void SetCacheItem(int gap, uint timeStamp, uint id) {
    // get the index of the array based on id
    uint cacheArrayIndex = GetArray(id);

    // if not found, return 0
    if (cacheArrayIndex == uint(-1)) {
        // create a new array with a new cache entry that stores the id as timestamp
        array<CacheEntry> newArray = {MakeCacheEntry(0, id)};
        // insert last the new array
        cacheArray.InsertLast(newArray);

        // set the index to the new last item
        cacheArrayIndex = cacheArray.Length - 1;
    }

    CacheEntry[]@ arrayPtr = cacheArray[cacheArrayIndex];

    // if no entries insert last the new entry
    if (arrayPtr.Length == 1) {
        arrayPtr.InsertLast(MakeCacheEntry(gap, timeStamp));
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
    arrayPtr.InsertAt(insertIdx, MakeCacheEntry(gap, timeStamp));
}
