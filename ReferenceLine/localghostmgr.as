class LocalGhostMgr {
    SampleArray@ sampleArray;
    bool isSaved = false;


    void LoadPoints(const string&in id) {
        string filePath = IO::FromStorageFolder(id);

        // don't try open the file if it doesn't exist
        if (!IO::FileExists(filePath)) { 
            isSaved = false;
            return;
        }

        IO::File saveFile(filePath, IO::FileMode::Read);

        MemoryBuffer @version = saveFile.Read(1);
        uint8 vNum = version.ReadUInt8();

        // close the save file once the necessary data is read
        saveFile.Close();

        int loadRes = 1;

        // determine version and read based on version
        if (vNum == 3) {
            // loadRes = V3::LoadPoints(id, sampleArray);
        }
        else if (vNum == 2) {
            print("Version 2 files are not supported due to bugs.");
        }
        else {
            loadRes = V1::LoadPoints(id, sampleArray);
        }

        isSaved = loadRes == 0;
    }

    void SavePoints(const string&in id) {
        // TODO: replace this with V3 once V3 is fixed
        int res = V1::SavePoints(id, sampleArray);
        isSaved = res == 0;
    }

    void DeleteAll() {
        string filePath = IO::FromStorageFolder("");

        // just delete the whole folder and its contents
        IO::DeleteFolder(filePath, true);

        // do this in case you are in a race
        sampleArray.Reset();
        isSaved = false;
    }

    void DeleteById(const string&in id, bool clearPoints = true) {
        string filePath = IO::FromStorageFolder(id);

        // don't try open the file if it doesn't exist
        if (!IO::FileExists(filePath)) { return; }

        // delete the file if it exists
        IO::Delete(filePath);

        // if clear points, clear the points
        if (clearPoints) {
            sampleArray.Reset();
            isSaved = false;
        }
    }

    LocalGhostMgr(SampleArray @sampleArray) {
        @this.sampleArray = sampleArray;
    }

    LocalGhostMgr() {}
}