/*
CSmPlayer@ a = cast<CSmPlayer@>(GetApp().CurrentPlayground.GameTerminals[0].GUIPlayer);
CSmScriptPlayer@ b = cast<CSmScriptPlayer>(a.ScriptAPI);
auto c = a.Score;

print(a.CurrentStoppedRespawnLandmarkIndex + " " + a.CurrentStoppedRespawnLandmarkIndex);

// counts the number of respawns
c.NbRespawnsRequested;
*/


namespace PlayerData {
    uint lap;
    uint cp;
    
    uint lastRespawnCount;

    bool hasRespawned;

    void Update() {
        auto raceData = MLFeed::GetRaceData_V4();
        auto player = raceData.GetPlayer_V4(MLFeed::LocalPlayersName);

        auto lapCount = raceData.LapCount;
        auto cpCount = raceData.CpCount + 1;
        auto playerCompletedCPs = player.CpCount;

        cp = playerCompletedCPs % cpCount;
        lap = playerCompletedCPs / cpCount;

        hasRespawned = lastRespawnCount != player.NbRespawnsRequested;

        lastRespawnCount = player.NbRespawnsRequested;
    }

    void Reset() {
        lap = 0;
        cp = 0;
        lastRespawnCount = 0;
        hasRespawned = false;
    }
}