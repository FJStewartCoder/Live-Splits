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

// stores and calculates the ghosts that exist
class RacingGhostManager {
    // stores the ghosts as pairs of name to data
    dictionary ghosts;
    array<GhostGapData> ghostsList;

    private void SortGhostInfo(array<MLFeed::GhostInfo_V2@>@ arr) {
        while (true) {
            bool swapped = false;

            for (uint i = 0; i < arr.Length - 1; i++) {
                MLFeed::GhostInfo_V2@ temp = null;
                MLFeed::GhostInfo_V2@ cur = arr[i];
                MLFeed::GhostInfo_V2@ next = arr[i + 1];

                if (cur.IdUint > next.IdUint) {
                    @temp = cur;

                    @arr[i] = next;
                    @arr[i + 1] = temp;

                    swapped = true;
                }
            }

            if (!swapped) { break; }
        }
    }

    void CreateGhostsArray() {
        // TODO: implement the below description with the dictionary (string: GhostData&) and the list of GhostData
        // MLFeed ghosts (loaded) is a list of all ghosts
        // this array is in the same order as the VehicleState vis list
        // duplicates can occur in ML list but only the first instance of each is the correct one

        // get the loaded ghosts
        // the ids are in the same order as the vehicle state vis
        array<MLFeed::GhostInfo_V2@> mlGhosts = MLFeed::GetGhostData().LoadedGhosts;
        SortGhostInfo(mlGhosts);

        // get those vis
        CSceneVehicleVis@[] vehicleStates = VehicleState::GetAllVis(GetApp().GameScene);

        // iterate the vehicle visibilities and relate them to the ghost 
        for (int i = 1; i < vehicleStates.Length; i++) {
            CSceneVehicleVis@ vis = vehicleStates[i];

            GhostGapData data;

            @data.entityVis = vis;
            data.entityId = GetEntityId(vis);

            @data.ghostData = mlGhosts[i - 1];
            data.ghostId = data.ghostData.IdUint;
            data.ghostName = data.ghostData.Nickname;

            // TODO: implement the corrent insertion method
            ghostsList.InsertLast(data);
        }
    }

    void Reset() {
        // reset the ghosts array and ghosts dictionary
        ghosts.DeleteAll();
        ghostsList.Resize(0);
    }

    void OnRestart() {
        for (int i = 0; i < ghostsList.Length; i++) {
            ghostsList[i].ResetGaps();
        }
    }
}