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

class SubSamples {
    array<Point> samples;

    uint lap;
    uint checkpoint;

    void Reset() {
        samples.Resize(0);
    }

    SubSamples(uint lap, uint checkpoint) {
        this.lap = lap;
        this.checkpoint = checkpoint;
    }

    SubSamples() {}
}

class SampleArray {
    // a list of subsamples
    array<SubSamples> samples;
    // a list of all of the samples in order 
    array<Point@> fullSamples;

    // the size of the samples
    bool isComplete = false;

    // the default size of the samples array
    uint defaultSize = 0;


    void SetComplete(bool value) {
        // set array complete to true or false based on the input
        isComplete = value;

        if (value) {
            GenerateFullSamples();
        }
    }

    void Reset() {
        fullSamples.Resize(0);
        samples.Resize(defaultSize);
        SetComplete(false);
    }

    SubSamples@ FindLapAndCP(uint lap, uint cp) {
        for (int i = 0; i < samples.Length; i++) {
            SubSamples@ subSample = samples[i];

            if (subSample.lap == lap && subSample.checkpoint == cp) {
                return subSample;
            }
        }

        return null;
    }

    SubSamples@ GetLapAndCP(uint lap, uint cp) {
        const bool exists = FindLapAndCP(lap, cp) !is null;

        if (exists) { return FindLapAndCP(lap, cp); }

        SubSamples subSamples(lap, cp);
        samples.InsertLast(subSamples);

        return subSamples;
    }

    void SortSubSamples() {
        while (true) {
            bool swapped = false;

            for (int i = 0; i < samples.Length - 1; i++) {
                bool sameLapGreaterCP = (samples[i].lap == samples[i + 1].lap) && (samples[i].checkpoint > samples[i + 1].checkpoint);
                bool greaterLap = (samples[i].lap > samples[i + 1].lap);

                bool shouldSwap = greaterLap || sameLapGreaterCP;
                
                if (shouldSwap) {
                    SubSamples temp = samples[i];
                    samples[i] = samples[i + 1];
                    samples[i + 1] = temp;
                }
            }

            if (!swapped) { break; }
        }
    }

    void GenerateFullSamples() {
        SortSubSamples();
        
        // iterate all of the sub samples
        for (uint i = 0; i < samples.Length; i++) {
            SubSamples@ subSamples = samples[i];

            fullSamples.Reserve(subSamples.samples.Length);

            for (uint j = 0; j < subSamples.samples.Length; j++) {
                Point@ p = subSamples.samples[j];
                fullSamples.InsertLast(p);
            }
        }
    }

    ArrayRange GetSampleRange(PointLocation start, PointLocation end) {
        // SortSubSamples();

        ArrayRange range;
        bool startSet = false;

        for (uint i = 0; i < samples.Length; i++) {
            SubSamples@ subSamples = samples[i];
            
            range.max += subSamples.samples.Length;

            if (!MeetsCheckLocationCriteria(subSamples, start, end)) {
                // if not met criteria and not start set, we are before start so continue
                if (!startSet) { continue; }
                
                // if not, we are beyond the end. so, break
                break;
            }
            
            if (!startSet) { range.min = range.max; }
            startSet = true;

            for (uint j = 0; j < subSamples.samples.Length; j++) {
                Point@ p = subSamples.samples[j];
                fullSamples.InsertLast(p);
            }
        }

        return range;
    }

    SampleArray() {
        samples.Reserve(defaultSize);
    }
}