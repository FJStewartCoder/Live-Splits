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
    uint lastPointIdx;

    void ResetGaps() {
        gap = 0;
        relGap = 0;
        lastPointIdx = 0;
    }

    void ApplyGapInfo(GapInfo@ gapInfo) {
        relGap = gapInfo.gap;
        lastPointIdx = gapInfo.index;
    }
}

class PointLocation {
    uint cp;
    uint lap;
    uint idx;

    string ToString() {
        return "CP: " + cp + ", LAP: " + lap + ", IDX:" + idx;
    }

    PointLocation(uint cp = 0, uint lap = 0, uint idx = 0) {
        this.cp = cp; this.lap = lap; this.idx = idx;
    }

    PointLocation() {}
}

// stores and calculates the ghosts that exist
class RacingGhostManager {
    // TODO: implement both of the below
    // both ghosts and ghostsList need to be fully implemented

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

    private void FilterGhostInfo(array<MLFeed::GhostInfo_V2@>@ arr) {
        // stores the ghost name then the most relevant ghost info
        dictionary seen;

        for (uint i = 0; i < arr.Length; i++) {
            MLFeed::GhostInfo_V2@ info = arr[i];

            const bool isValid = info.Result_Time != -1;

            if (!isValid) { continue; }

            if (seen.Exists(info.Nickname)) {
                MLFeed::GhostInfo_V2@ seen_info = cast<MLFeed::GhostInfo_V2@>(seen[info.Nickname]);
                const bool isSeenFaster = seen_info.Result_Time < info.Result_Time;

                // if the current info has a faster time, insert instead
                if (!isSeenFaster) {
                    @seen[info.Nickname] = info;
                }
            }
            else {
                // if there is no info for this name, add it to the list
                @seen[info.Nickname] = info;
            }
        }

        // clear the array
        arr.RemoveRange(0, arr.Length);

        // convert the dictionary back into an array
        auto seenNames = seen.GetKeys();

        print("Number names = " + seenNames.Length);

        // iterate all items and add them back to the array
        for (uint i = 0; i < seenNames.Length; i++) {
            const string name = seenNames[i];

            MLFeed::GhostInfo_V2@ seenData = cast<MLFeed::GhostInfo_V2@>(seen[name]);

            arr.InsertLast(seenData);
        }
    }

    void CreateGhostsArray() {
        // TODO: implement the below description with the dictionary (string: GhostData&) and the list of GhostData
        // MLFeed ghosts (loaded) is a list of all ghosts
        // this array is in the same order as the VehicleState vis list
        // duplicates can occur in ML list but only the first instance of each is the correct one
        // some ghosts have result time -1 which means incomplete
        // duplicates occur when more track is driven on a track that is never played which means that there are several ghosts with different times / checkpoint counts
        // any time a PB is set, duplicate ghosts occur
        // these need to be filtered to only show the fastest ghost per name
        
        // EXTRA CONSIDERATION: Vehicle state doesnt't show the vehciles always in the correct order (not sorted)

        // get the loaded ghosts
        // the ids are in the same order as the vehicle state vis
        array<MLFeed::GhostInfo_V2@> mlGhosts = MLFeed::GetGhostData().LoadedGhosts;
        FilterGhostInfo(mlGhosts);
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

    // TODO: implement a better refresh later
    void RefreshGhosts() {
        Reset();
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

        RefreshGhosts();
    }
}