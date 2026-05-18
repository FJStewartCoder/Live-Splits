enum UpdateState {
    NETGHOST,  // want to or already has loaded the network ghost
    LOCALGHOST,  // wants to or currently is loading the local ghost
    LOGGING,  // is logging points
    COMPLETE,  // is complete
    NONE  // has not started any process
};

class ReferenceMgr {
    SampleArray sampleArray;

    LogMgr logMgr(sampleArray);
    LocalGhostMgr localGhostMgr(sampleArray);
    NetGhostMgr netGhostMgr(sampleArray);

    private UpdateState state;

    
    private bool DoingNothing() {
        return state == UpdateState::NONE;
    }

    private void GetNetworkGhost() {
        // the state that we need to set or be in order to do this action
        const UpdateState requiredState = UpdateState::NETGHOST;

        // if doing nothing, set the state to the state we need
        if ( DoingNothing() ) { state = requiredState; }

        // if we are now not in the state we needed to be, return
        // this means that when we checked for doing nothing, we were not already in this state
        // (would allow for processing over several gameloops)
        if ( state != requiredState ) { return; }

        // implement this later
        // netGhostMgr.LoadGhost();

        // checks to determine the new state
        if ( sampleArray.isComplete ) {
            state = UpdateState::COMPLETE;
        }
        else {
            state = UpdateState::NONE;
        }
    }

    private void GetLocalGhost() {
        // initial logic to determine what to do

        // the state that we need to set or be in order to do this action
        const UpdateState requiredState = UpdateState::LOCALGHOST;

        // if doing nothing, set the state to the state we need
        if ( DoingNothing() ) { state = requiredState; }

        // if we are now not in the state we needed to be, return
        // this means that when we checked for doing nothing, we were not already in this state
        // (would allow for processing over several gameloops)
        if ( state != requiredState ) { return; }

        // try to load a local ghost
        localGhostMgr.LoadPoints( currentMap );

        // determine the new state
        if ( sampleArray.isComplete ) {
            state = UpdateState::COMPLETE;
        }
        else {
            state = UpdateState::NONE;
        }
    }

    void LogSamples() {
        // the state that we need to set or be in order to do this action
        const UpdateState requiredState = UpdateState::LOGGING;

        // if doing nothing, set the state to the state we need
        if ( DoingNothing() ) { state = requiredState; }

        // if we are now not in the state we needed to be, return
        // this means that when we checked for doing nothing, we were not already in this state
        // (would allow for processing over several gameloops)
        if ( state != requiredState ) { return; }

        logMgr.LogPoint();

        // if complete, set state to complete, otherwise remain in the logging state
        if ( sampleArray.isComplete ) {
            state = UpdateState::COMPLETE;

            // TODO
            // once samples are fully logged, save the local ghost
        }
    }

    void OnUpdate() {
        // don't need to do anything if the array is complete
        if ( sampleArray.isComplete || state == UpdateState::COMPLETE ) {
            return;
        }

        // call the state functions
        GetNetworkGhost();
        GetLocalGhost();
        LogSamples();
    }

    void OnChangeTrack() {
        // reset states and reset the array
        state = UpdateState::NONE;
        sampleArray.Reset();
        logMgr.Reset();
    }

    void OnRestart() {
        logMgr.OnRestart();
        netGhostMgr.OnRestart();
        localGhostMgr.OnRestart();
    }
}


// every sub manager for the reference manager needs to inherit this
class SubReferenceMgr {
    SampleArray @sampleArray;

    // called when the track changes
    void OnTrackChange() {
    }

    // called when the player returns to the start of the track
    void OnRestart() {
    }

    // reset the manager to the default state
    void Reset() {
    }

    SubReferenceMgr(SampleArray @sampleArray) {
        @this.sampleArray = sampleArray;
    }
} 