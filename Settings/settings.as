// ---------------------------------------------------------
// gap settings

// how far either side of the last index will we search
[Setting hidden]
uint searchRadius = 500;

// show gap even if not array complete (for long maps)
// WILL NOT SHOW GAP IF YOU ARE AHEAD
[Setting hidden]
bool getGapOverride = false;

// ---------------------------------------------------------
// main settings

// hard limit on the array size
[Setting hidden]
uint32 arrayMaxSize = 1000000;  // 1,000,000

[Setting hidden]
// max number of ghost cars 
uint8 numCars = 3;

// optimisation settings to change rate of variety of things
RotatingCounter framesBetweenLog(1);
RotatingCounter framesBetweenGap(10);

// which algorithm to use for the gap
[Setting hidden]
GapAlgorithm gapAlg = GapAlgorithm::ModifiedLinear;

// --------------------------------------------------------
// other settings

[Setting hidden]
bool isEnabled = true;

// --------------------------------------------------------