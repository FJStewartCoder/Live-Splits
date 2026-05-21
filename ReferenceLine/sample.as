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

    // is used for when a function needs it
    // it is certainly not accurate unless set after a function call
    uint startIdx = 0;

    // the number of samples in this definition
    uint length = 0;

    uint CalculateEndIndex() {
        return startIdx + length;
    }

    SubSampleDefinition(uint lap, uint cp) {
        this.lap = lap;
        this.checkpoint = cp;
    }

    SubSampleDefinition() {}
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

    SubSampleDefinition@ NewDefinition(uint lap, uint cp) {
        // create a new definition
        SubSampleDefinition newDefinition(lap, cp);

        // create a variable for the insertion index
        uint insertionIdx = -1;

        for (uint i = 0; i < definitions.Length; i++) {
            SubSampleDefinition@ curDefinition = definitions[i];

            // checks for if the insertion index should be set
            const bool greaterLap = curDefinition.lap > lap;
            const bool greaterCP = (curDefinition.lap == lap) && (curDefinition.checkpoint > cp);

            // once a checkpoint is after the current one, insert before that one
            if (greaterCP && greaterLap) {
                insertionIdx = i;
                break;
            }
        }

        // if last item, insert last
        // else insert at insertion index
        if (insertionIdx == uint(-1)) {
            definitions.InsertLast(newDefinition);
        }
        else {
            definitions.InsertAt(insertionIdx, newDefinition);
        }

        return newDefinition;
    }

    private bool DefinitionMeetsCondition(SubSampleDefinition @def, uint lap, uint cp) {
        // if laps are same and the lap is not any, it does not meet the condition
        if (def.lap != lap && lap != uint(-1)) { return false; }
        // repeat for the checkpoint
        if (def.checkpoint != cp && cp != uint(-1)) { return false; }
        // if it passes all, it must meet the condition
        return true;
    }

    void CalculateStartIndices() {
        uint startIdx = 0;

        for (uint i = 0; i < definitions.Length; i++) {
            SubSampleDefinition@ def = definitions[i];

            def.startIdx = startIdx;

            startIdx += def.length;
        }
    }

    array<SubSampleDefinition@> FindDefinitions(uint lap = -1, uint cp = -1) {
        CalculateStartIndices();

        // create an empty list of definitions
        array<SubSampleDefinition@> foundDefs;

        for (uint i = 0; i < definitions.Length; i++) {
            SubSampleDefinition@ def = definitions[i];
            if (DefinitionMeetsCondition(def, lap, cp)) { foundDefs.InsertLast(def); }
        }

        // return the list of definitions that meet the condition
        return foundDefs;
    }

    // appends a sample to the end of a region
    void AppendSample(
        Point@ point,
        uint lap = -1,
        uint cp = -1
    ) {
        SubSampleDefinition@ relevantSubSamples;

        auto foundDefs = FindDefinitions(lap, cp);

        // if there are no found definitions, create a new one
        if (foundDefs.IsEmpty()) {
            @relevantSubSamples = NewDefinition(lap, cp);
        }
        else {
            // set the relevant samples to the last samples found
            @relevantSubSamples = foundDefs[foundDefs.Length - 1];
        }

        // calculate the start indexes
        CalculateStartIndices();

        // increment the length of the sub samples
        relevantSubSamples.length++;
        // finally, insert the point
        samples.InsertAt(relevantSubSamples.startIdx, point);
    }

    // delete samples in this range
    void DeleteSubSamples(uint lap, uint cp) {
        // find the relevant definitions
        auto foundDefs = FindDefinitions(lap, cp);
        if (foundDefs.IsEmpty()) {
            error("Found no sub samples to delete where: LAP=" + lap + "CP=" + cp);
            return;
        }

        // calculate the start indices to correctly delete later
        CalculateStartIndices();

        // calculate the deleted offset
        uint deletedOffset = 0;

        for (uint i = 0; i < foundDefs.Length; i++) {
            SubSampleDefinition@ samplesToDelete = foundDefs[i];

            // TODO: figure out if length works correctly here due to indexing
            samples.RemoveRange(
                samplesToDelete.startIdx - deletedOffset,
                samplesToDelete.CalculateEndIndex() - deletedOffset
            );

            deletedOffset += samplesToDelete.length;
            samplesToDelete.length = 0;
        }

        // recalculate the start indexes
        CalculateStartIndices();
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

            // if the start is not set, set the min to the max because it stores the start idx
            if (!startSet) {
                range.min = range.max;
                startSet = true;
            }

            // add the length to the max
            // must be done after setting min to max
            range.max += subSamples.length;
        }

        // TODO: figure out if length is one index too great
        return range;
    }

    SampleArray() {
        Reset();
    }
}