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
        return LoadPointsV3(id);
    }
    else if (vNum == 2) {
        saveFile.Close();
        print("Version 2 files are no supported due to bugs.");
    }
    else {
        saveFile.Close();
        return LoadPointsV1(id);
    }

    // no determined version
    saveFile.Close();
    return 1;
}