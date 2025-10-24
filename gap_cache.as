class CacheEntry {
    // the gap
    int gap;
    // the timeStamp that the gap was observed
    uint timeStamp;
}

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
            break;
        }
        else if (cacheArray[idx][mid].timeStamp < value) {
            r = mid - 1;
        }
        else {
            l = mid + 1;
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

int GetCacheItem(uint timeStamp, uint id) {
    // get the index of the array based on id
    uint cacheArrayIndex = GetArray(id);

    // if not found, return 0
    if (cacheArrayIndex == uint(-1)) {
        return 0;
    }

    // if there are no entries then return 0 as well
    if (cacheArray[cacheArrayIndex].Length == 1) {
        return 0;
    }

    // binary search the cache array to find the closest timestamp
    uint closestIdx = BinarySearch(cacheArrayIndex, timeStamp);

    // TODO: add some approximation based on how much between the points the time stamp is
    // e.g 12, 14!, 20
    // because 14 is 2/8 between the surrounding points get the time diff between 12 and 20 and multiply by 2/8
    // add this to the time at 12 to get the approximate time gap

    uint curGap = cacheArray[cacheArrayIndex][closestIdx].gap;

    // checks for if the closest time stamp is within a sensible range (e.g 0.5s away)
    // this is 1 second deviation allowed
    if (Math::Abs(curGap - timeStamp) > 1000) {
        return 0;
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
    }

    uint insertIdx = uint(-1);

    // insert the item into the correct position
    for (int i = 1; i < arrayPtr.Length; i++) {
        // if the same timeStamp is already present then return
        if (arrayPtr[i].timeStamp == timeStamp) {
            return;
        }
        // iterate until the first item larger
        else if (arrayPtr[i].timeStamp > timeStamp) {
            insertIdx = i;
        }
    }

    // insert the item
    if (insertIdx == uint(-1)) {
        arrayPtr.InsertLast(MakeCacheEntry(gap, timeStamp));
    }
    else {
        arrayPtr.InsertAt(insertIdx, MakeCacheEntry(gap, timeStamp));
    }
}
