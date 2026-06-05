class MinMax {
    int min = 0;
    int max = 0;
}

MinMax GetMinMax(array<int>@ arr) {
    MinMax minMax;

    if (arr.IsEmpty()) { return minMax; }

    minMax.min = arr[0];
    minMax.max = arr[0];

    for (uint i = 1; i < arr.Length; i++) {
        int cur = arr[i];

        if (cur < minMax.min) { minMax.min = cur; }
        else if (cur > minMax.max) { minMax.max = cur; }
    }

    return minMax;
}