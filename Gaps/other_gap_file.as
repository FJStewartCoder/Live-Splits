class GhostGapData {
    string ghostName;

    uint entityId;
    CSceneVehicleVis@ entityVis = null;

    uint ghostId;
    MLFeed::GhostInfo_V2@ ghostData = null;

    // as milliseconds
    int gap;
    // gap relative to ghost points
    int relGap; 

    // index of the previous gap
    uint lastIdx;
}