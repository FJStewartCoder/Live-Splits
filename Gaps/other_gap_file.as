class GhostGapData {
    // the name of the ghost
    string ghostName;

    // the entity id for the vehiclevis
    uint entityId;
    // ptr to the entity vis
    CSceneVehicleVis@ entityVis = null;

    // the ghost's id from MLFeed
    uint ghostId;
    // the actual ghost data
    MLFeed::GhostInfo_V2@ ghostData = null;

    // gap, in milliseconds, relative to the player
    int gap;
    // gap, in milliseconds, relative to reference points
    int relGap; 

    // location in which the previous point was found
    // used by estimate gap
    PointLocation lastPointLoc;

    void ResetGaps() {
        gap = 0;
        relGap = 0;
    }
}

class PointLocation {
    uint cp;
    uint lap;
    uint idx;

    string ToString() {
        return "CP: " + cp + ", LAP: " + lap + ", IDX:" + idx;
    }
}