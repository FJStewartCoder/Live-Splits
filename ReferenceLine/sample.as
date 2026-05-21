class Point {
    // stores the x, y, z coordinates
    double x = 0;
    double y = 0;
    double z = 0;
    // stores the timeStamp of these coordinates
    // used to calculate the split
    // int but miliseconds
    uint timeStamp = 0;

    string Get() {
        return "x = " + x + ", y = " + y + ", z = " + z + ", time = " + timeStamp;
    }

    void LoadFromState(CSceneVehicleVisState@ car = null) {
        if (car is null) { return; }

        // get the point data
        y = car.Position.y;
        x = car.Position.x;
        z = car.Position.z;

        // gets time stamp
        timeStamp = timer.GetTime();
    }
}

class ArrayRange {
    uint min = 0;
    uint max = 0;
}

// TODO: update sample array to store seperate samples per checkpoint and lap
// should fix issue with respawns and stuff

class SubSampleDefinition {
    uint lap = 0;
    uint checkpoint = 0;

    uint startIdx = 0;
    uint length = 0;
}

class SampleArray {
    // a list of subsamples
    array<Point> samples;
    // defines how the samples is layed out relative to the laps and checkpoints
    array<SubSampleDefinition> definitions;

    // the size of the samples
    bool isComplete = false;

    // the default size of the samples array
    uint defaultSize = 0;


    // appends a sample to the end of a region
    void AppendSample(
        Point@ point,
        uint lap = -1,
        uint cp = -1
    ) {

    }

    // delete samples in this range
    void DeleteSamples(ArrayRange range) {

    }


    void SetComplete(bool value) {
        // set array complete to true or false based on the input
        isComplete = value;
    }

    void Reset() {
        samples.RemoveRange(0, samples.Length);
        definitions.RemoveRange(0, definitions.Length);

        SetComplete(false);

        samples.Reserve(defaultSize);
    }

    ArrayRange GetSampleRange(PointLocation start, PointLocation end) {
        // SortSubSamples();

        ArrayRange range;
        bool startSet = false;

        for (uint i = 0; i < definitions.Length; i++) {
            SubSampleDefinition@ subSamples = definitions[i];

            if (!MeetsCheckLocationCriteria(subSamples, start, end)) {
                // if not met criteria and not start set, we are before start so continue
                if (!startSet) { continue; }
                
                // if not, we are beyond the end. so, break
                break;
            }

            // if the start is not set, set the min and max to the startIdx
            if (!startSet) {
                range.min = subSamples.startIdx;
                range.max = range.min;
            }

            // add the length to the max
            range.max += subSamples.length;
        }

        // TODO: figure out if length is one index too great
        return range;
    }

    SampleArray() {
        Reset();
    }
}