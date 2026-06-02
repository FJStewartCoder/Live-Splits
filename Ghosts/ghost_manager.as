enum GhostType {
    // the current player
    // is live, can not be cached
    LOCAL_PLAYER,

    // another player. e.g player in ranked
    // is live, can not be cached
    PLAYER,

    // a ghost that has been recorded
    // is not live, can be cached
    GHOST,

    // none of them. should be the default value
    NONE
}

class GhostData {
    // the name of the ghost
    string name;

    // the entity id for the vehiclevis
    uint entityId;
    // ptr to the entity vis
    CSceneVehicleVis@ entityVis = null;

    // the ghost's id from MLFeed
    uint ghostId;
    // the actual ghost data
    MLFeed::GhostInfo_V2@ ghostData = null;

    // the type of ghost
    GhostType type = GhostType::NONE;
}

class GhostGapData {
    GhostData ghostInfo;

    // gap, in milliseconds, relative to the player
    int gap;
    // gap, in milliseconds, relative to reference points
    int relGap; 
    int lastRelGap;

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
namespace GhostManager {
    void FilterGhostInfo(array<MLFeed::GhostInfo_V2@>@ arr) {
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

    int CompareStates(ref @a, ref @b) {
        auto a1 = cast<CSceneVehicleVis>(a);
        auto b1 = cast<CSceneVehicleVis>(b);

        return int(GetEntityId(a1)) - int(GetEntityId(b1));
    }

    int CompareGhosts(ref @a, ref @b) {
        auto a1 = cast<MLFeed::GhostInfo_V2@>(a);
        auto b1 = cast<MLFeed::GhostInfo_V2@>(b);

        return int(a1.IdUint) - int(b1.IdUint);
    }

    void SortVisStates(CSceneVehicleVis@[]@ states) {
        ref@[] toSort;

        for (uint i = 0; i < states.Length; i++) {
            ref@ stateRef = states[i];
            toSort.InsertLast(stateRef);
        }

        Sort(toSort, @CompareStates);
    }

    void SortGhostInfo(MLFeed::GhostInfo_V2@[]@ ghosts) {
        ref@[] toSort;

        for (uint i = 0; i < ghosts.Length; i++) {
            ref@ ghostRef = ghosts[i];
            toSort.InsertLast(ghostRef);
        }

        Sort(toSort, @CompareGhosts);
    }

    GhostData[] GetAllGhosts() {
        // ghost array to retun
        GhostData[] ghosts;

        // check that the scene is available
        auto app = GetApp();
        if (app is null) { return ghosts; }

        auto scene = app.GameScene;
        if (scene is null) { return ghosts; }

        // get the vehicle vis states
        CSceneVehicleVis@[] visStates = VehicleState::GetAllVis(scene);
        SortVisStates(visStates);
        
        // get the loaded ghosts
        // the ids are in the same order as the vehicle state vis
        array<MLFeed::GhostInfo_V2@> mlGhosts = MLFeed::GetGhostData().LoadedGhosts;
        FilterGhostInfo(mlGhosts);
        SortGhostInfo(mlGhosts);

        // TODO: have a better method of handling this later
        if (visStates.Length - 1 != mlGhosts.Length) {
            return ghosts;
        }

        // iterate the vehicle visibilities and relate them to the ghost 
        for (int i = 1; i < visStates.Length; i++) {
            CSceneVehicleVis@ vis = visStates[i];

            GhostData data;

            @data.entityVis = vis;
            data.entityId = GetEntityId(vis);

            @data.ghostData = mlGhosts[i - 1];
            data.ghostId = data.ghostData.IdUint;
            data.name = data.ghostData.Nickname;

            // TODO: implement the corrent insertion method
            ghosts.InsertLast(data);

            // TODO: implement enum type for ghosts
        }

        trace("Got all ghosts");

        return ghosts;
    }

    void RefreshGhosts(GhostData[]@ ghosts) {

    }
}