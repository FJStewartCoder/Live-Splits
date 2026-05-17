namespace V1 {
    int SavePoints(const string&in id, SampleArray@ sampleArray) {
        // only save is array is complete
        if (!sampleArray.isComplete) {
            return 1;
        }

        string filePath = IO::FromStorageFolder(id);
        IO::File saveFile(filePath, IO::FileMode::Write);

        // write the number of points
        saveFile.Write(sampleArray.samples.Length);

        // write each point
        for (int i = 0; i < sampleArray.samples.Length; i++) {
            // create a reference to the current point to save
            Point@ sample = sampleArray.samples[i];

            saveFile.Write(sample.timeStamp);
            saveFile.Write(sample.x);
            saveFile.Write(sample.y);
            saveFile.Write(sample.z);
        }

        // DONT FORGET TO CLOSE THE FILE
        saveFile.Close();

        print("Saved data to file: " + filePath);

        return 0;
    }

    int LoadPoints(const string&in id, SampleArray @sampleArray) {
        string filePath = IO::FromStorageFolder(id);

        // don't try open the file if it doesn't exist
        if (!IO::FileExists(filePath)) { return 1; }

        IO::File saveFile(filePath, IO::FileMode::Read);

        MemoryBuffer @sizeData = saveFile.Read(4);
        uint points = sizeData.ReadUInt32();

        // there are no points so fail
        if (points == 0) {
            saveFile.Close();
            return 1;
        }

        // if there are too many points, don't load
        if (points > arrayMaxSize) {
            saveFile.Close();
            return 1;
        }

        trace("Found " + points + " ghost points.");

        sampleArray.defaultSize = 0;
        sampleArray.Reset();

        MemoryBuffer @data = saveFile.Read(points * (4 + 8 + 8 + 8));

        for (int i = 0; i < points; i++) {
            Point newPoint;

            newPoint.timeStamp = data.ReadUInt32();

            newPoint.x = data.ReadDouble();
            newPoint.y = data.ReadDouble();
            newPoint.z = data.ReadDouble();

            sampleArray.samples.InsertLast(newPoint);
        }

        // need to close the file if opened
        saveFile.Close();

        // when loaded, the array must be complete
        sampleArray.SetComplete(true);
        return 0;
    }
}