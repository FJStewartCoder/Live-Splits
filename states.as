// is in game but not in editor
bool IsInGame() {
    CGameCtnApp @app = GetApp();
    return (app.GameScene !is null) && (app.Editor is null);
}

class Time {
    // variable to store the start time
    uint startTime = 0;
    // used to determine if paused
    uint lastTime = 0;

    uint GetTime() {
        uint time = 0;

        CGameScriptHandlerPlaygroundInterface @netScript = GetApp().Network.PlaygroundInterfaceScriptHandler;

        // if we have netScript, use that because it is more accurate
        if (netScript !is null) {
            time = netScript.GameTime - startTime;
        }
        // else use the less accurate local script
        else {
            CGamePlaygroundScript @script = GetApp().PlaygroundScript;
            // if null, return no time
            if (script !is null) { 
                time = script.Now - startTime;
            }
        }

        // this gets the current time ignoring pauses
        return time;
    }

    void SetStartTime() {
        // set to 0 to prevent removing any time
        startTime = 0;
        // set the start time to a time
        startTime = GetTime();
    }

    // is the game paused
    bool IsPaused() {
        // if the last time and current time are the same, it must be paused
        bool res = lastTime == GetTime();
        // set last time to the current time after checking this
        lastTime = GetTime();

        return res;
    }
}