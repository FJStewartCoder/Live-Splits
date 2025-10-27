float GetDist(Point @p1, Point @p2) {
    return Math::Sqrt((Math::Pow((p1.x - p2.x), 2) + Math::Pow((p1.y - p2.y), 2) + Math::Pow((p1.z - p2.z), 2)));
}

// dist between the two points only on a 2D plane
float GetDist2D(Point @p1, Point @p2) {
    return Math::Sqrt((Math::Pow((p1.x - p2.x), 2) + Math::Pow((p1.y - p2.y), 2)));
}

// precision is linear in terms of accuracy increase
// 2x precision == 2x less difference
// precision at about 10,000 doesnt affect performance
float precision = 10000;
array<float> distCacheList;

// + 1 FIX IDX OUT OF RANGE ERROR
// because 0, 10 is 11 numbers so just +1
void MakeDistCacheArray() {
    for (float i = 0; i < precision + 1; i++) {
        float num = i / precision;
        
        // get the dist assuming one side is of length 1
        float dist = Math::Sqrt((num * num) + 1);
        
        distCacheList.InsertLast(dist);
    }
}

// take the biggest gap and set all variable relative to it (biggest = 1)
// use the two smaller values as indexes in an array based on predetermined precision by multiplying by precisiom and assuming an integer
// get the cached value and multiply by the originla biggest value

// FIX DIVISION BY 0
float GetDist2DFast(Point @p1, Point @p2) {
    float xGap = Math::Abs(p1.x - p2.x);
    float yGap = Math::Abs(p1.y - p2.y);

    if (xGap == 0 && yGap == 0) {
        return 0;
    }
    
    if (xGap >= yGap) {
        int idx = (yGap / xGap) * precision;
        return distCacheList[idx] * xGap;
    }
    else {
        int idx = (xGap / yGap) * precision;
        return distCacheList[idx] * yGap;
    }
}