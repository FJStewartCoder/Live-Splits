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

    // used for when the type can not be determined
    UNKNOWN,

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

class GapEntry {
    int gap = 0;
    uint tstamp = 0;

    GapEntry(int gap, uint tstamp) {
        this.gap = gap; this.tstamp = tstamp;
    }

    GapEntry() {}
}

class GapData {
    // TODO: add a setting for this
    uint maxGaps = 10;
    GapEntry[] gaps;

    int GapRate() {
        // TODO: add a setting for this
        // number of entries that will be used to calculate the rate
        const uint numEntriesForCalc = 5;

        // if there are no enough entries, return 0
        if (gaps.Length <= numEntriesForCalc) { return 0; }

        GapEntry@ now = GetGapEntry();
        GapEntry@ last = GetGapEntry(numEntriesForCalc);

        // last = -1.2, now = -1.1, so rate should be +0.1 per frame
        // to achieve this now - last
        const int ratePerPeriod = now.gap - last.gap;
        // for example, time since last frame is 0.1s, gap needs to be perFrame / time
        const int period = now.tstamp - last.tstamp;

        // calculate the time since last frame as seconds rather than millis
        const double periodMultiplier = double(period) / 1000;

        return double(ratePerPeriod) / periodMultiplier;
    }

    void SetGap(int val) {
        GapEntry entry(val, timer.GetTime());
        gaps.InsertLast(entry);

        // remove index 0 if there are too many gaps
        if (gaps.Length > maxGaps) { gaps.RemoveAt(0); }
    }

    GapEntry@ GetGapEntry(
        uint offset = 0  // number of records to search backwards for the value (easier to get last item)
    ) {
        // return 0 if empty or the last value if not empty
        if (gaps.Length <= offset) { return null; }
        return gaps[gaps.Length - (offset + 1)];
    }

    int GetGap(
        uint offset = 0  // number of records to search backwards for the value (easier to get last item)
    ) {
        if (gaps.Length <= offset) { return 0; }
        return gaps[gaps.Length - (offset + 1)].gap;
    }


    void Reset() {
        gaps.Resize(0);
    }

    GapData() {
        Reset();
    }
}

class GhostGapData {
    GhostData ghostInfo;

    // gap relative to the player
    GapData gap;
    // gap relative to the reference
    GapData rel;

    // location in which the previous point was found
    // used by estimate gap
    uint lastPointIdx;

    void ResetGaps() {
        gap.Reset();
        rel.Reset();

        lastPointIdx = 0;
    }

    void ApplyGapInfo(GhostGapData@ data) {
        // calculate the gap relative to the data passed in
        int gapToSet = data.rel.GetGap() - this.rel.GetGap();
        // set this as the new gap
        gap.SetGap(gapToSet);
    }

    void ApplyRelGapInfo(GapInfo@ gapInfo) {
        rel.SetGap(gapInfo.gap);
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

    GhostData[] GetVehicleVisAsGhosts() {
        // ghost array to retun
        GhostData[] ghosts;

        // check that the scene is available
        auto app = GetApp();
        if (app is null) { return ghosts; }

        auto scene = app.GameScene;
        if (scene is null) { return ghosts; }

        CSceneVehicleVis@[] visStates = VehicleState::GetAllVis(scene);

        // skip the first entry since that is always the local player
        for (uint i = 1; i < visStates.Length; i++) {
            CSceneVehicleVis@ vis = visStates[i];
            GhostData ghostData;

            ghostData.entityId = GetEntityId(vis);
            @ghostData.entityVis = vis;

            ghostData.ghostId = 0;
            @ghostData.ghostData = null;

            ghostData.name = "Unknown";
            ghostData.type = GhostType::UNKNOWN;

            ghosts.InsertLast(ghostData);
        }

        return ghosts;
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

        // if there are not the same number of ghosts as states as mlghosts, just use unnamed ghosts
        if (visStates.Length - 1 != mlGhosts.Length) {
            warn("Number of ML Ghosts does not match number of Vehicle States");
            return GetVehicleVisAsGhosts();
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

    // TODO: improve the hash function
    uint GetGhostHash() {
        uint hash = 0;

        // check that the scene is available
        auto app = GetApp();
        if (app is null) { return hash; }

        auto scene = app.GameScene;
        if (scene is null) { return hash; }

        // get the vehicle vis states
        CSceneVehicleVis@[] visStates = VehicleState::GetAllVis(scene);

        for (uint i = 0; i < visStates.Length; i++) {
            hash += GetEntityId(visStates[i]);
        }

        return hash;
    }
}