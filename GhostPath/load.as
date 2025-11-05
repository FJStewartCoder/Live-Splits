int LoadPoints(const string&in id) {
    string filePath = IO::FromStorageFolder(id);

    // don't try open the file if it doesn't exist
    if (!IO::FileExists(filePath)) { return 1; }

    IO::File saveFile(filePath, IO::FileMode::Read);

    MemoryBuffer @version = saveFile.Read(1);
    uint8 vNum = version.ReadUInt8();

    // determine version and read based on version
    if (vNum == 3) {
        saveFile.Close();
        return V3::LoadPoints(id);
    }
    else if (vNum == 2) {
        saveFile.Close();
        print("Version 2 files are no supported due to bugs.");
    }
    else {
        saveFile.Close();
        return V1::LoadPoints(id);
    }

    // no determined version
    saveFile.Close();
    return 1;
}

int DeleteAll() {
    string filePath = IO::FromStorageFolder("");

    // just delete the whole folder and its contents
    IO::DeleteFolder(filePath, true);

    // do this in case you are in a race
    ResizeArrays(0);
    arrayComplete = false;
    isSaved = false;

    return 0;
}

int DeleteById(const string&in id, bool clearPoints = true) {
    string filePath = IO::FromStorageFolder(id);

    // don't try open the file if it doesn't exist
    if (!IO::FileExists(filePath)) { return 1; }

    // delete the file if it exists
    IO::Delete(filePath);

    // if clear points, clear the points
    if (clearPoints) {
        ResizeArrays(0);
        arrayComplete = false;
        isSaved = false;
    }

    return 0;
}