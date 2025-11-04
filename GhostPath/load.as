int LoadPoints(const string&in id) {
    string filePath = IO::FromStorageFolder(id);

    // don't try open the file if it doesn't exist
    if (!IO::FileExists(filePath)) { return 1; }

    IO::File saveFile(filePath, IO::FileMode::Read);

    MemoryBuffer @version = saveFile.Read(1);

    // determine version and read based on version
    if (version.ReadUInt8() == 2) {
        saveFile.Close();
        return LoadPointsV2(id);
    }
    else {
        saveFile.Close();
        return LoadPointsV1(id);
    }

    // no determined version
    saveFile.Close();
    return 1;
}