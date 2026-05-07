class Point {
    // stores the x, y, z coordinates
    double x = 0;
    double y = 0;
    double z = 0;
    // stores the timeStamp of these coordinates
    // used to calculate the split
    // int but miliseconds
    uint timeStamp = 0;

    string Get() {
        return "x = " + x + ", y = " + y + ", z = " + z + ", time = " + timeStamp;
    }

    void LoadFromState(CSceneVehicleVisState@ car = null) {
        if (car is null) { return; }

        // get the point data
        y = car.Position.y;
        x = car.Position.x;
        z = car.Position.z;

        // gets time stamp
        timeStamp = timer.GetTime();
    }
}