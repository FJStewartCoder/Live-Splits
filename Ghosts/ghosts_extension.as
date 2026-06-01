class GhostExtraInfo {
    uint lap;
    uint checkpoint;
    bool isFinished;
}

GhostExtraInfo GetExtraGhostInfo(MLFeed::GhostInfo_V2@ ghost) {
    // the return item
    GhostExtraInfo info;

    auto currentTime = timer.GetTime();

    // ghost is finished if the time is after the ghost's finish time
    info.isFinished = currentTime >= ghost.Result_Time;

    auto ghostCPs = ghost.get_Checkpoints();

    uint ghostCompletedCPs = 0;

    // iterate each checkpoint time
    // check if each cp time is greater than the current time
    // this is therefore the checkpoint that the ghost is on
    for (uint i = 0; i < ghostCPs.Length; i++) {
        auto cpTime = ghostCPs[i];

        if (cpTime > currentTime) {
            ghostCompletedCPs = i;
            break;
        }
    }

    auto raceData = MLFeed::GetRaceData_V4();
    // the cpCount is the number of checkpoints on the track
    auto cpCount = raceData.CpCount + 1;

    // calculate the cp and lap based on the number of checkpoints taken
    info.checkpoint = ghostCompletedCPs % cpCount;
    info.lap = ghostCompletedCPs / cpCount;

    return info;
}