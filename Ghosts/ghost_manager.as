enum GhostType {
    // the current player
    // is live, can not be cached
    LOCAL_PLAYER,

    // another player. e.g player in ranked
    // is live, can not be cached
    PLAYER,
    
    // is a ghost but is the personal best
    // should not be cached as it may change
    PERSONAL_BEST,

    // a ghost that has been recorded
    // is not live, can be cached
    GHOST,

    // used for when the type can not be determined
    UNKNOWN,

    // none of them. should be the default value
    NONE
}

const string GhostTypeToString(GhostType t) {
    string res = "How did you do this?";

    switch (t) {
        case (GhostType::LOCAL_PLAYER):
            res = "Local Player";
            break;
        case (GhostType::PLAYER):
            res = "Player";
            break;
        case (GhostType::PERSONAL_BEST):
            res = "Personal Best";
            break;
        case (GhostType::GHOST):
            res = "Ghost";
            break;
        case (GhostType::UNKNOWN):
            res = "Unknown";
            break;
        case (GhostType::NONE):
            res = "None";
            break;
    }

    return res;
}

class LapAndCp {
    uint lap;
    uint checkpoint;
}

class GhostData {
    // the name of the ghost
    string name;

    // ptr to the entity vis
    CSceneVehicleVis@ entityVis = null;

    // the actual ghost data
    MLFeed::GhostInfo_V2@ ghostData = null;

    // this is the data related to a player
    MLFeed::PlayerCpInfo_V2@ playerData = null;

    // the type of ghost
    GhostType type = GhostType::NONE;

    // used to determine whether or not the ghost has finished    
    private uint timeAtLastCheck = 0;
    private float lastWorldVel = 99999.9;
    private vec3 lastPos = vec3(123, 456, 789);
    private float lastFrontSpeed = 12345.67;
    private bool lastFinishDecision = false;


    void CalcType() {
        /*
        RESEARCH:

        LOCAL_PLAYER
            - Entity ID designation is 0x02000000
            - Can be found in MLFeed Race Feed

        PLAYER
            - Entity ID designation is unknown but presumed to be 0x03000000
            - Can be found in MLFeed Race Feed

        PERSONAL_BEST
            - Entity ID designation is same as ghost 
            - MLFeed has a variable for isPB which is true

        GHOST
            - Entity ID designation is 0x04000000
            - It is found in MLFeed and nothing else applies

        UNKNOWN
            - Nothing above applies
        NONE
            - Has been assigned nothing

        */

        // if there ghost data, it must be a ghost
        if (ghostData !is null) {
            // if it is personal best, it is personal best
            // if the name is the same as the player's name it is also the player
            if (ghostData.IsPersonalBest || ghostData.Nickname == GetApp().LocalPlayerInfo.Name) {
                type = GhostType::PERSONAL_BEST;
            }
            // otherwise it is just a ghost
            else {
                type = GhostType::GHOST;
            }

            return;
        }

        // if there is player data, it must be a player
        if (playerData !is null) {
            // if local player, then it is a local player
            if (playerData.IsLocalPlayer) {
                type = GhostType::LOCAL_PLAYER;
            }
            // otherwise it is just a normal player
            else {
                type = GhostType::PLAYER;
            }

            return;
        }

        // if there is entity vis data, we can probably calculate the type
        if (entityVis !is null) {
            uint entityId = GetEntityId(entityVis);

            // if greater than 0x04, then it is a ghost
            if (entityId >= 0x04000000) {
                type = GhostType::GHOST;
            }
            // presumably greater than or equal to 0x03 is just a player
            else if (entityId >= 0x03000000) {
                type = GhostType::PLAYER;
            }
            // if greater than 0x02 but less than above, must be local player
            else if (entityId >= 0x02000000) {
                type = GhostType::LOCAL_PLAYER;
            }

            return;
        }

        // if all data points are null, there is no way of determining the type
        type = GhostType::UNKNOWN;
    }

    LapAndCp GetLapAndCP() {
        // reulst
        LapAndCp res;
        res.checkpoint = -1;
        res.lap = -1;

        const MLFeed::HookRaceStatsEventsBase_V4@ raceData = MLFeed::GetRaceData_V4();

        // if there is no race data, the cp is undeterminable
        if (raceData is null) { return res; }

        // get the total cp count
        uint cpCount = raceData.CpCount + 1;
        int completedCPs = -1;

        // if it is a type of ghost calculate the cps and laps one way
        // also requires ghost data to be not null
        if (
            (type == GhostType::GHOST || type == GhostType::PERSONAL_BEST) &&
            ghostData !is null
        ) {
            // get the current race time to calculate the number of checkpoints completed
            uint currentTime = timer.GetTime();
            auto ghostCPs = ghostData.get_Checkpoints();

            // iterate each checkpoint time
            // check if each cp time is greater than the current time
            // this is therefore the checkpoint that the ghost is on
            for (uint i = 0; i < ghostCPs.Length; i++) {
                auto cpTime = ghostCPs[i];

                if (cpTime > currentTime) {
                    completedCPs = i;
                    break;
                }
            }
        }
        // if it is a player, just grab the data
        else if (playerData !is null) {
            completedCPs = playerData.CpCount;
        }

        uint cp = completedCPs % cpCount;
        uint lap = completedCPs / cpCount;

        // calculate the final result
        res.checkpoint = cp;
        res.lap = lap;

        return res;
    }

    bool IsFinished() {
        // if we have player data, return the is finished value
        if (playerData !is null) {
            return playerData.IsFinished;
        }

        // if we have ghost data we can use it
        // if the current time is after the finish time, it must be finished
        if (ghostData !is null) {
            return timer.GetTime() >= ghostData.Result_Time;
        }

        if (entityVis !is null && entityVis.AsyncState !is null) {
            const uint currentTime = timer.GetTime();

            const uint timeSinceLastCheck = currentTime - timeAtLastCheck;

            // less than 0.03s
            if (timeSinceLastCheck < 30) {
                // return the same as last time
                return lastFinishDecision;
            }

            const float curWorldVel = 
                entityVis.AsyncState.WorldVel.Length();

            const float frontSpeed = 
                entityVis.AsyncState.FrontSpeed;
            
            const vec3 pos =
                entityVis.AsyncState.Position;

            const bool isFinished = (
                (curWorldVel == lastWorldVel) &&
                (frontSpeed == lastFrontSpeed) &&
                (pos.x == lastPos.x && pos.y == lastPos.y && pos.z == lastPos.z)
            );

            // set lasts to currents after checking if they are different
            lastWorldVel = curWorldVel;
            lastFrontSpeed = frontSpeed;
            lastPos = pos;

            // set the time at last check
            timeAtLastCheck = currentTime;

            // set the last finish decision
            lastFinishDecision = isFinished;

            return isFinished;
        }

        // there is no hope
        return false;
    }

    // will not cache if name is not availiable and 
    bool IsCacheable() {
        const bool validType = (type == GhostType::GHOST);

        const bool dataAvailable = (
            (ghostData !is null) || (playerData !is null) 
        );

        return validType && dataAvailable;
    }
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
    uint maxGaps = 20;
    GapEntry[] gaps;

    // TODO: consider taking a similar approach to std deviation
    int GapRate() {
        // if the number of gaps is not full, return 0
        if (gaps.Length != maxGaps) { return 0; }

        // get the current gap
        GapEntry@ now = GetGapEntry();
        // get the oldest gap
        GapEntry@ last = GetGapEntry(maxGaps - 1);

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

        // actually finish the sorting process by putting the resutls back into the passed in array
        for (uint i = 0; i < states.Length; i++) {
            @states[i] = cast<CSceneVehicleVis@>(toSort[i]);
        }
    }

    void SortGhostInfo(MLFeed::GhostInfo_V2@[]@ ghosts) {
        ref@[] toSort;

        for (uint i = 0; i < ghosts.Length; i++) {
            ref@ ghostRef = ghosts[i];
            toSort.InsertLast(ghostRef);
        }

        Sort(toSort, @CompareGhosts);

        // actually finish the sorting process by putting the resutls back into the passed in array
        for (uint i = 0; i < ghosts.Length; i++) {
            @ghosts[i] = cast<MLFeed::GhostInfo_V2@>(toSort[i]);
        }
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
        const bool useMLFeedData = visStates.Length - 1 == mlGhosts.Length;

        if (!useMLFeedData) {
            warn("Reduced ghost data availiable");
        }

        // iterate the vehicle visibilities and relate them to the ghost 
        for (int i = 1; i < visStates.Length; i++) {
            CSceneVehicleVis@ vis = visStates[i];

            GhostData data;

            @data.entityVis = vis;

            // if we are using ML feed data, get it
            if (useMLFeedData) {
                @data.ghostData = mlGhosts[i - 1];
                data.name = data.ghostData.Nickname;
            }

            data.CalcType();

            ghosts.InsertLast(data);
        }

        trace("Got all ghosts");

        return ghosts;
    }
    
    // TODO: implement this
    GhostData GetPlayer() {
        return GhostData();
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