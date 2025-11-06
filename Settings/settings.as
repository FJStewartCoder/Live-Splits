// ---------------------------------------------------------
// save settings

[Setting hidden]
bool useSave = true;

// ---------------------------------------------------------
// gap settings

// show gap even if not array complete (for long maps)
// WILL NOT SHOW GAP IF YOU ARE AHEAD
[Setting hidden]
bool getGapOverride = false;

[Setting hidden]
uint searchRangeSeconds = 1;

// bool to use linear gap or not
[Setting hidden]
bool useLinearGap = false;

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

// ------------------------------------------------------
// other render settings

[Setting hidden]
// each setting is represented as one bit shifted by some amount
int enabledRenderingOptions = 2;  // by default is bar

// the maximum gap each side the bar will accept
[Setting hidden]
float barGapRange = 4000;  // 4 seconds in milliseconds

[Setting hidden]
float barTransparency = 0.7;  // transparency of the bar

// the offsets of the bar
[Setting hidden]
int xOffset = 0;

[Setting hidden]
int yOffset = 0;

// --------------------------------------------------------
// cache settings

// toggle for if you want to use the cache or not
// will allow for support of multiplayer
[Setting hidden]
bool useCache = true;

// the max size of the cache per cache list
[Setting hidden]
uint maxCacheSize = 10000;

// used to increase the likelihood of cache hits with a smaller cache size my guessing the gap
[Setting hidden]
bool useCacheApproximation = false;

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

// number of points per second to check when using modified linear alg
[Setting hidden]
uint modLinResolution = 10;

// function to load the desynced values
void LoadAlg() {
    gapAlg = intToEnum(algorithmChoice);
}

// --------------------------------------------------------
// specialised method of setting these to prevent desync

// hidden settings that store the value in the class
[Setting hidden]
uint framesBetweenGapValue = 1;

// optimisation settings to change rate of variety of things
RotatingCounter framesBetweenGap(1);


void SetGapValue(uint value) {
    // fixes a bug where gap doesn't update in settings
    if (value == framesBetweenGapValue) { return; }

    framesBetweenGap.SetCount(value);
    framesBetweenGapValue = value;
}

// function to load the desynced values
void LoadCounters() {
    framesBetweenGap.SetCount(framesBetweenGapValue);
}