// taken from VehicleState source code
uint GetEntityId(CSceneVehicleVis@ vis) {
    return Dev::GetOffsetUint32(vis, 0);
}