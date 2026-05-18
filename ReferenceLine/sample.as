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
    // a list of samples
    array<SubSamples> samples;
    // the size of the samples
    bool isComplete = false;

    // the default size of the samples array
    uint defaultSize = 0;


    void SetComplete(bool value) {
        // set array complete to true or false based on the input
        isComplete = value;
    }

    void Reset() {
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

    SampleArray() {
        samples.Reserve(defaultSize);
    }
}