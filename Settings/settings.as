// ---------------------------------------------------------
// gap settings

// show gap even if not array complete (for long maps)
// WILL NOT SHOW GAP IF YOU ARE AHEAD
[Setting hidden]
bool getGapOverride = false;

[Setting hidden]
uint searchRangeSeconds = 1;

// ---------------------------------------------------------
// main settings

// hard limit on the array size
[Setting hidden]
uint32 arrayMaxSize = 1000000;  // 1,000,000

[Setting hidden]
// max number of ghost cars 
uint8 numCars = 3;

// --------------------------------------------------------
// other settings

[Setting hidden]
bool isEnabled = true;

// --------------------------------------------------------
// UI settings

[Setting hidden]
int FONT_SIZE = 100;

[Setting hidden]
int TEXT_SPACING = 10;

[Setting hidden]
int FRAME_PADDING = 10;

[Setting hidden]
// each setting is represented as one bit shifted by some amount
int enabledRenderingOptions = 0;

// --------------------------------------------------------
// specialised gapAlg scripts

// which algorithm to use for the gap
GapAlgorithm gapAlg;

// the chosen algorthim as an int
[Setting hidden]
int algorithmChoice = 0;

void SetGapAlg(GapAlgorithm newAlgorithm) {
    // set both to new algorithm
    gapAlg = newAlgorithm;
    // automatically converted to int
    algorithmChoice = newAlgorithm;
}


// function to load the desynced values
void LoadAlg() {
    gapAlg = intToEnum(algorithmChoice);
}

// --------------------------------------------------------
// specialised method of setting these to prevent desync

// hidden settings that store the value in the class
[Setting hidden]
uint framesBetweenLogValue = 1;
[Setting hidden]
uint framesBetweenGapValue = 1;

// optimisation settings to change rate of variety of things
RotatingCounter framesBetweenLog(1);
RotatingCounter framesBetweenGap(1);


// two functions below to prevent the desync
void SetLogValue(uint value) {
    framesBetweenLog.SetCount(value);
    framesBetweenLogValue = value;
}

void SetGapValue(uint value) {
    framesBetweenGap.SetCount(value);
    framesBetweenGapValue = value;
}

// function to load the desynced values
void LoadCounters() {
    framesBetweenLog.SetCount(framesBetweenLogValue);
    framesBetweenGap.SetCount(framesBetweenGapValue);
}