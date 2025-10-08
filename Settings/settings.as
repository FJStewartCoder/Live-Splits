// basically just a struct
class Settings {
    // ---------------------------------------------------------
    // gap settings

    // intervals in which the MODIFIED LINEAR algorithm will check
    // intervals between distance checks (reduces overall number of checks)
    // increasing this will improve efficiency but decrease accuracy
    // ACCURACY refers to how accurate the selection of closest point is
    // however, greater can help to filter out brief periods of crossing over the track
    array<uint> checkIntervals = {30, 8, 1};

    // how far either side of the last index will we search
    uint searchRadius = 500;

    // intervals in which the ESTIMATION algorithm will check
    array<uint> checkIntervalsEst = {20, 4, 1};

    // show gap even if not array complete (for long maps)
    // WILL NOT SHOW GAP IF YOU ARE AHEAD
    bool getGapOverride = false;

    // ---------------------------------------------------------
    // main settings

    // hard limit on the array size
    uint32 arrayMaxSize = 1000000;  // 1,000,000
    // max number of ghost cars 
    uint8 numCars = 3;

    // optimisation settings to change rate of variety of things
    RotatingCounter framesBetweenLog(1);
    RotatingCounter framesBetweenGap(10);

    // which algorithm to use for the gap
    GapAlgorithm gapAlg = GapAlgorithm::ModifiedLinear;

    // --------------------------------------------------------
};

Settings currentSettings;