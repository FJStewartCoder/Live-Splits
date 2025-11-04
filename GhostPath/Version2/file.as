class SaveData {
    uint8 version = 0;
    uint numPoints = 0;

    // 10 ^ this given multiplier for float conversion
    uint8 pow10Multiplier = 2;

    // needed for processing
    int minX, minY, minZ = 0;
    int maxX, maxY, maxZ = 0;

    uint minTStamp = 0;
    uint maxTStamp = 0;

    // the number of bytes needed to store the maximum value
    uint8 xBytes, yBytes, zBytes, tBytes;

    string Get() {
        return "min x = " + minX + ", max x = " + maxX + ", min y = " + minY + ", max y = " + maxY + ", min z = " + minZ + ", max z = " + maxZ + ", min t = " + minTStamp + ", max t = " + maxTStamp;
    }
};

class NewPoint {
    // stores the x, y, z coordinates
    int x, y, z;
    // stores the timeStamp of these coordinates
    // used to calculate the split
    // int but miliseconds
    uint timeStamp;

    string Get() {
        return "x = " + x + ", y = " + y + ", z = " + z + ", time = " + timeStamp;
    }
}

void ToNewPoints(NewPoint[]@ newPoints, uint multiplier = 1) {
    for (int i = 0; i < ghostPoints.Length; i++) {
        // convert ghostPoints coordinates and convert to int
        newPoints[i].x = ghostPoints[i].x * Math::Pow(10, multiplier);
        newPoints[i].y = ghostPoints[i].y * Math::Pow(10, multiplier);
        newPoints[i].z = ghostPoints[i].z * Math::Pow(10, multiplier);

        // timestamp is the same
        newPoints[i].timeStamp = ghostPoints[i].timeStamp;
    }
}

void ConvertToDiff(NewPoint[]@ newPoints) {
    // iterate until one before the end (because we i - 1)
    // have to go in reverse order so that we don't overwrite data we need
    // iterate all but i == 0
    for (int i = ghostPoints.Length - 1; i != 0; i--) {
        // the current point is the difference between the same point in ghosts - the previous point
        newPoints[i].x = newPoints[i].x - newPoints[i - 1].x;
        newPoints[i].y = newPoints[i].y - newPoints[i - 1].y;
        newPoints[i].z = newPoints[i].z - newPoints[i - 1].z;

        // timestamp
        newPoints[i].timeStamp = newPoints[i].timeStamp - newPoints[i - 1].timeStamp;
    }
}

void GetMinMax(NewPoint[]@ newPoints, SaveData @data) {
    for (int i = 1; i < newPoints.Length; i++) {
        // if first iteration all min and max should be these values
        if (i == 1) {
            data.minX = newPoints[i].x;
            data.minY = newPoints[i].y;
            data.minZ = newPoints[i].z;

            data.maxX = newPoints[i].x;
            data.maxY = newPoints[i].y;
            data.maxZ = newPoints[i].z;

            data.minTStamp = newPoints[i].timeStamp;
            data.minTStamp = newPoints[i].timeStamp;

            continue;
        }

        // min max
        if (newPoints[i].x < data.minX) { data.minX = newPoints[i].x; }
        else if (newPoints[i].x > data.maxX) { data.maxX = newPoints[i].x; }

        // min max
        if (newPoints[i].y < data.minY) { data.minY = newPoints[i].y; }
        else if (newPoints[i].y > data.maxY) { data.maxY = newPoints[i].y; }

        // min max
        if (newPoints[i].z < data.minZ) { data.minZ = newPoints[i].z; }
        else if (newPoints[i].z > data.maxZ) { data.maxZ = newPoints[i].z; }

        // min max
        if (newPoints[i].timeStamp < data.minTStamp) { data.minTStamp = newPoints[i].timeStamp; }
        else if (newPoints[i].timeStamp > data.maxTStamp) { data.maxTStamp = newPoints[i].timeStamp; }
    }

}

// remove all negatives by adding an offset of min to all if less than 0
// then if no negatives, subtract the minimum value for all
// if min == 0 then do nothing

// this means all scenarios subtract minX from everything then nothing else
void FinalCompression(NewPoint[]@ newPoints, SaveData @data) {
    // transform max to the max subtract the min which is subtracted from all
    data.maxTStamp -= data.minTStamp;
    
    // convert all timestamps to be subtract the min value
    for (int i = 1; i < newPoints.Length; i++) {
        newPoints[i].timeStamp -= data.minTStamp;
    }

    // first iteration of compression
    if (data.minX != 0) {
        // subtract min from all (equivalent of adding the positive to all)
        data.maxX -= data.minX;

        for (int i = 1; i < newPoints.Length; i++) {
            newPoints[i].x -= data.minX;
        }
    }

    // first iteration of compression
    if (data.minY != 0) {
        // subtract min from all (equivalent of adding the positive to all)
        data.maxY -= data.minY;

        for (int i = 1; i < newPoints.Length; i++) {
            newPoints[i].y -= data.minY;
        }
    }

    // first iteration of compression
    if (data.minZ != 0) {
        // subtract min from all (equivalent of adding the positive to all)
        data.maxZ -= data.minZ;

        for (int i = 1; i < newPoints.Length; i++) {
            newPoints[i].z -= data.minZ;
        }
    }
}

uint8 GetNumBytes(int num) {
    // uint8
    if (num < 256) {
        return 2;
    }
    // uint16
    if (num < 256 << 8) {
        return 4;
    }
    // uint32
    if (num < 256 << 24) {
        return 8;
    }
    
    // just no
    return 0;
}

// get all of the byte amounts with above helper function
void GetByteAmounts(SaveData @data) {
    data.xBytes = GetNumBytes(data.maxX);
    data.yBytes = GetNumBytes(data.maxY);
    data.zBytes = GetNumBytes(data.maxZ);
    data.tBytes = GetNumBytes(data.maxTStamp);
}

void ProcessPoints(NewPoint[]@ newPoints, SaveData @data) {
    // if not the right size, resize
    if (newPoints.Length != ghostPoints.Length) {
        newPoints.Resize(ghostPoints.Length);
    }

    // convert ghost points to new points
    ToNewPoints(newPoints, data.pow10Multiplier);

    // convert each point to diff
    ConvertToDiff(newPoints);

    // get all min and max values
    GetMinMax(newPoints, data);

    // final process of compression
    FinalCompression(newPoints, data);

    // gets byte amounts
    GetByteAmounts(data);

    for (int i = 0; i < newPoints.Length; i++) { print(newPoints[i].Get()); }
    print(data.Get());
}

MemoryBuffer WriteBytes(int num, uint8 numBytes) {
    MemoryBuffer buf;

    switch (numBytes) {
        case 2:
            buf.Write(uint8(num));
            break;
        case 4:
            buf.Write(uint16(num));
            break;
        case 8:
            buf.Write(uint32(num));
            break;
        default:
            break;
    }

    return buf;
}

int SavePointsV2(const string&in id) {
    // only save is array is complete
    if (!arrayComplete) {
        return 1;
    }

    string filePath = IO::FromStorageFolder(id);
    IO::File saveFile(filePath, IO::FileMode::Write);

    SaveData data;

    // set some basic variables
    data.version = 2;
    data.numPoints = ghostPoints.Length;

    // create a new array of size of the previous array
    array<NewPoint> newPoints(ghostPoints.Length);

    // process the ghosts points to this array
    ProcessPoints(newPoints, data);

    // ---------------------------------------------------
    // writing process

    // write the version number as uint8
    saveFile.Write(data.version);

    // write the number of points
    saveFile.Write(data.numPoints);

    // write all byte amounts
    saveFile.Write(data.tBytes);
    saveFile.Write(data.xBytes);
    saveFile.Write(data.yBytes);
    saveFile.Write(data.zBytes);

    // write all mins at the byte sizes
    // these define the offsets
    saveFile.Write(data.minTStamp);
    saveFile.Write(data.minX);
    saveFile.Write(data.minY);
    saveFile.Write(data.minZ);

    // write the pow10Multipler to interpret the data
    saveFile.Write(data.pow10Multiplier);

    // write the first point for a reference
    saveFile.Write(newPoints[0].timeStamp);
    saveFile.Write(newPoints[0].x);
    saveFile.Write(newPoints[0].y);
    saveFile.Write(newPoints[0].z);

    // write each point
    for (int i = 1; i < newPoints.Length; i++) {
        saveFile.Write(WriteBytes(newPoints[i].timeStamp, data.tBytes));
        saveFile.Write(WriteBytes(newPoints[i].x, data.xBytes));
        saveFile.Write(WriteBytes(newPoints[i].y, data.yBytes));
        saveFile.Write(WriteBytes(newPoints[i].z, data.zBytes));
    }

    // ---------------------------------------------------

    // DONT FORGET TO CLOSE THE FILE
    saveFile.Close();

    print("Saved data to file: " + filePath);

    return 0;
}

int LoadPointsV2(const string&in id) {
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