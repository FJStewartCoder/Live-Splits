// array of the main ghost's points
array<Point> ghostPoints(0);
bool arrayComplete = false;


void ResizeArrays(uint runLength) {
    // resize the main array
    ghostPoints.Resize(runLength);
}


// function to log the points
void LogPoints(ISceneVis@ scene) {
    // only log points if not complete
    if (arrayComplete) {
        return;
    }

    // check for size greater or equal to the hard limit
    if (currentLogIndex >= arrayMaxSize) {
        // print("Max array size hit");

        // if at limit the array must be complete
        arrayComplete = true;
        return;
    }

    // gets id from misc array
    uint currentId = miscArray[1].id;

    // not a valid id
    if (currentId == 0) {
        return;
    }

    // gets current car based on entity ID with native functions
    CSceneVehicleVis@ currentCar = VehicleState::GetVisFromId(scene, currentId);

    // if is null, must have finished or is gone
    if (currentCar is null) {
        // if current log index is greater than the size + 2, the array must have stopped tracking so must have finished
        // + 2 simply for safety
        if (ghostPoints.Length + 2 < currentLogIndex) {
            print("Logging finished");
            arrayComplete = true;
        }

        // if null must return
        return;
    }

    Point currentPoint = MakePoint(currentCar);

    // reassign a point if there is space for it else insert at the end the new point
    if (currentLogIndex >= ghostPoints.Length) {
        // set last point
        ghostPoints.InsertLast(currentPoint);
    }
    else {
        ghostPoints[currentLogIndex] = currentPoint;
    }

    // debug print
    // print(car + " " + currentPoint.Get());
}