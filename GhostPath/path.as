// array of the main ghost's points
array<Point> ghostPoints(0);
bool arrayComplete = false;


void ResizeArrays(uint runLength) {
    // resize the main array
    ghostPoints.Resize(runLength);
}

int GetPoints() {
    auto allGhosts = GetAllGhosts();

    if (allGhosts.Length == 0) { return 1; }

    ResizeArrays(0);

    for (int i = 0; i < allGhosts[0].Length; i++) {
        Point newPoint;

        newPoint.x = allGhosts[0][i].position.x;
        newPoint.y = allGhosts[0][i].position.y;
        newPoint.z = allGhosts[0][i].position.z;

        newPoint.timeStamp = allGhosts[0][i].time;

        ghostPoints.InsertLast(newPoint);
    }

    arrayComplete = true;

    return 0;
}