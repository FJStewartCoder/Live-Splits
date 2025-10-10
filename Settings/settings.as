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

// optimisation settings to change rate of variety of things
RotatingCounter framesBetweenLog(1);
RotatingCounter framesBetweenGap(10);

// --------------------------------------------------------
// other settings

[Setting hidden]
bool isEnabled = true;

// --------------------------------------------------------
// UI settings

[Setting name="Font Size" category="UI"]
int FONT_SIZE = 100;

[Setting name="Text Spacing" category="UI"]
int TEXT_SPACING = 10;

[Setting name="Frame Padding" category="UI"]
int FRAME_PADDING = 10;

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