int SavePointsV1(const string&in id) {
    // only save is array is complete
    if (!arrayComplete) {
        return 1;
    }

    string filePath = IO::FromStorageFolder(id);
    IO::File saveFile(filePath, IO::FileMode::Write);

    // write the number of points
    saveFile.Write(ghostPoints.Length);

    // write each point
    for (int i = 0; i < ghostPoints.Length; i++) {
        saveFile.Write(ghostPoints[i].timeStamp);
        saveFile.Write(ghostPoints[i].x);
        saveFile.Write(ghostPoints[i].y);
        saveFile.Write(ghostPoints[i].z);
    }

    // DONT FORGET TO CLOSE THE FILE
    saveFile.Close();

    print("Saved data to file: " + filePath);

    return 0;
}

int LoadPointsV1(const string&in id) {
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

    print("Found " + points + " ghost points.");

    ResizeArrays(0);

    MemoryBuffer @data = saveFile.Read(points * (4 + 8 + 8 + 8));

    for (int i = 0; i < points; i++) {
        Point newPoint;

        newPoint.timeStamp = data.ReadUInt32();

        newPoint.x = data.ReadDouble();
        newPoint.y = data.ReadDouble();
        newPoint.z = data.ReadDouble();

        ghostPoints.InsertLast(newPoint);
    }

    // need to close the file if opened
    saveFile.Close();

    // when loaded, the array must be complete
    arrayComplete = true;
    return 0;
}