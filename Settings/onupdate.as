void AssignCacheSettings() {
    // TODO: add these in the gap manager
    /*
    print("Cache.maxSize: " + tostring(tmp.maxSize));
    print("Cache.useApproximation: " + tostring(tmp.useApproximation));
    */

    gapMgr.cacheEnabled = Settings::Cache::enabled;
}

void AssignGapSettings() {
    // TODO: allow these to be updated
    /*
    print("Gap.numCars: " + tostring(tmp.numCars));
    print("Gap.getGapOverride: " + tostring(tmp.getGapOverride));
    print("Gap.searchRangeSeconds: " + tostring(tmp.searchRangeSeconds));
    */

    gapMgr.algorithm = Settings::Gap::algorithm;
    gapMgr.useLinear = Settings::Gap::useLinearGap;
}

void AssignLoggerSettings() {
    reference.sampleArray.maxSize = Settings::Logger::arrayMaxSize;
}

void AssignPerformanceSettings() {
    reference.logMgr.framesBetweenLog.SetCount(
        Settings::Performance::framesBetweenLogValue);
    
    gapMgr.framesBetweenGap.SetCount(
        Settings::Performance::framesBetweenGapValue);
}

void AssignSaveSettings() {
    // TODO: make this update-able
    // print("Save.enabled: " + tostring(tmp.enabled));
}

void AssignSettings() {
    AssignCacheSettings();
    AssignGapSettings();
    AssignLoggerSettings();
    AssignPerformanceSettings();
    AssignSaveSettings();
}