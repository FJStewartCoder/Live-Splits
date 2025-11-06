// TAKEN FROM https://github.com/XertroV/tm-ghosts-plus-plus/blob/master/src/ReadEntRecordData.as

uint16 GetOffset(const string &in className, const string &in memberName) {
    // throw exception when something goes wrong.
    auto ty = Reflection::GetType(className);
    auto memberTy = ty.GetMember(memberName);
    return memberTy.Offset;
}

uint16 GetOffset(CMwNod@ nod, const string &in memberName) {
    // throw exception when something goes wrong.
    auto ty = Reflection::TypeOf(nod);
    auto memberTy = ty.GetMember(memberName);
    return memberTy.Offset;
}

const uint16 O_CTN_GHOST_ENT_RECORD_DATA = GetOffset("CGameCtnGhost", "Validate_ExtraTool_Info") + (0x2E0 - 0x220);

CSceneVehicleVis::EntRecordDelta@[]@ GetSamplesFromGhost(CGameCtnGhost@ ghost) {
    auto entRecordData = cast<CPlugEntRecordData>(Dev::GetOffsetNod(ghost, O_CTN_GHOST_ENT_RECORD_DATA));
    auto samplesAllPtr = Dev::GetOffsetUint64(ghost, O_CTN_GHOST_ENT_RECORD_DATA + 0x8);
    auto samplesAllBufLen = Dev::GetOffsetUint32(ghost, O_CTN_GHOST_ENT_RECORD_DATA + 0x10);
    auto samples1PtrAlt = ReadUint64PtrSafe(samplesAllPtr, 0);

    if (entRecordData is null) {
        //NotifyWarning("Null ent record data");
        return {};
    }
    auto visSampleDataPtr = Dev::GetOffsetUint64(entRecordData, 0x40);
    while (visSampleDataPtr != 0 && Dev::ReadUInt8(visSampleDataPtr + 0x8) != 0x2) {
        trace("found samples of type: " + Dev::ReadUInt8(visSampleDataPtr + 0x8) + " at " + Text::FormatPointer(visSampleDataPtr));
        visSampleDataPtr = ReadUint64PtrSafe(visSampleDataPtr, 0);
    }
    if (visSampleDataPtr == 0 || Dev::ReadUInt8(visSampleDataPtr + 0x8) != 0x2) {
        //NotifyWarning("Failed to find samples of type 0x2 (vehicle); next ptr: " + Text::FormatPointer(visSampleDataPtr));
        return {};
    }

    if (visSampleDataPtr + 0x8 != samples1PtrAlt) {
        //NotifyWarning("Alt ptr: " + Text::FormatPointer(samples1PtrAlt) + "\nGot Ptr: " + Text::FormatPointer(visSampleDataPtr + 0x8));
    }

    // auto nextSamplePtr = ReadUint64PtrSafe(visSampleDataPtr, 0x18);
    auto nextSamplePtr = ReadUint64PtrSafe(samples1PtrAlt, 0x10);

    CSceneVehicleVis::EntRecordDelta@[] data;

    while (nextSamplePtr > 0) {
        auto time = Dev::ReadUInt32(nextSamplePtr + 0x8);
        auto dataPtr = ReadUint64PtrSafe(nextSamplePtr, 0x10);
        auto dataLen = Dev::ReadUInt32(nextSamplePtr + 0x18);
        data.InsertLast(CSceneVehicleVis::EntRecordDelta(time, dataPtr, dataLen));
        // TODO: I DON'T KNOW WHAT COMMENTING THIS DOES BUT IT GOES FASTER
        // yield();
        nextSamplePtr = ReadUint64PtrSafe(nextSamplePtr, 0);
    }

    return data;
}

uint64 ReadUint64PtrSafe(uint64 ptr, uint16 offset) {
    if (ptr == 0) { trace('ptr == 0'); return 0; }
    if (ptr & 0x7 != 0) { trace('ptr & 0x7 != 0'); return 0; }
    if (ptr <= 0xFFFFFFFF) { trace('ptr <= 0xFFFFFFFF'); return 0; }
    if (ptr > 0xF0F0FFFFFFFF) { trace('ptr > 0xF0F0FFFFFFFF'); return 0; }
    return Dev::ReadUInt64(ptr + offset);
}

namespace CSceneVehicleVis {
    // conveniently the same format as in gbx files
    class EntRecordDelta {
        protected uint64 ptr;
        protected uint len;
        uint time;

        EntRecordDelta(uint time, uint64 ptr, uint len) {
            this.ptr = ptr;
            this.len = len;
            this.time = time;
            ReadFromPtr();
            // trace('Instantiated EntRecordDelta @ ' + Text::FormatPointer(ptr) + ' // time: ' + time + ' // pos: ' + position.ToString());
        }

        vec3 position;
        quat rotation;
        float speed;
        vec3 velocity;

        float gas, brake;

        protected void ReadFromPtr() {
            // read pos, speed, rotation, velocity
            Seek(47);
            position = ReadVec3();
            auto angle = ReadUInt16ToFloat(Math::PI, 0xFFFF);
            auto axisHeading = ReadInt16ToFloat(Math::PI, 0x7FFF);
            auto axisPitch = ReadInt16ToFloat(Math::PI / 2., 0x7FFF);
            speed = Math::Exp(ReadInt16ToFloat(1., 1000));
            auto velHeading = ReadInt8ToFloat(Math::PI, 0x7F);
            auto velPitch = ReadInt8ToFloat(Math::PI / 2., 0x7F);
            auto axis = vec3(
                Math::Sin(angle) * Math::Cos(axisPitch) * Math::Cos(axisHeading),
                Math::Sin(angle) * Math::Cos(axisPitch) * Math::Sin(axisHeading),
                Math::Sin(angle) * Math::Sin(axisPitch)
            );
            rotation = quat(axis, Math::Cos(angle));
            velocity = vec3(
                Math::Cos(velPitch) * Math::Cos(velHeading),
                Math::Cos(velPitch) * Math::Sin(velHeading),
                Math::Sin(velPitch)
            ) * speed;

            // read braking and gas
            Seek(15);
            gas = ReadUInt8ToFloat(1.0, 255);
            Seek(18);
            brake = ReadUInt8ToFloat(1.0, 255);
            gas += brake;
        }

        protected uint currOffset = 0;
        void Seek(uint offset) {
            // should only be 107 long
            if (offset >= 120) throw('offset too large');
            currOffset = offset;
        }

        vec3 ReadVec3() {
            auto v = Dev::ReadVec3(ptr + currOffset);
            currOffset += 0xC;
            return v;
        }

        float ReadUInt16ToFloat(float coef, int divisor) {
            auto v = Dev::ReadUInt16(ptr + currOffset);
            currOffset += 0x2;
            return float(v) * coef / float(divisor);
        }

        float ReadInt16ToFloat(float coef, int divisor) {
            auto v = Dev::ReadInt16(ptr + currOffset);
            currOffset += 0x2;
            return float(v) * coef / float(divisor);
        }

        float ReadInt8ToFloat(float coef, int divisor) {
            auto v = Dev::ReadInt8(ptr + currOffset);
            currOffset += 0x1;
            return float(v) * coef / float(divisor);
        }

        float ReadUInt8ToFloat(float coef, int divisor) {
            auto v = Dev::ReadUInt8(ptr + currOffset);
            currOffset += 0x1;
            return float(v) * coef / float(divisor);
        }
    }
}

NGameGhostClips_SMgr@ GetGhostClipsMgr(CGameCtnApp@ app) {
    if (app.GameScene is null) return null;
    auto nod = Dev::GetOffsetNod(app.GameScene, 0x120);
    if (nod is null) return null;
    return Dev::ForceCast<NGameGhostClips_SMgr@>(nod).Get();
}

array<CGameCtnGhost@>@ GetCurrentGhosts(CGameCtnApp@ app) {
    auto mgr = GetGhostClipsMgr(app);
    if (mgr is null) return null;
    array<CGameCtnGhost@> ghosts;
    for (uint i = 0; i < mgr.Ghosts.Length; i++) {
        ghosts.InsertLast(mgr.Ghosts[i].GhostModel);
    }
    return ghosts;
}

CSceneVehicleVis::EntRecordDelta@[]@[] GetAllGhosts() {
    auto app = GetApp();
    if (app.RootMap !is null && app.RootMap.ModPackDesc !is null) {
        Fids::Preload(app.RootMap.ModPackDesc.Fid);
    }

    // sleep(250);
    // removed yield() from the brackets (I hope it doesn't break anything)
    while (app.PlaygroundScript is null) {}
    while (app.PlaygroundScript !is null && GetCurrentGhosts(app) is null) {}
    while (app.PlaygroundScript !is null && GetCurrentGhosts(app).Length == 0) {}

    array<CSceneVehicleVis::EntRecordDelta@[]@> allGhosts;

    if (app.PlaygroundScript !is null) {
        auto ghosts = GetCurrentGhosts(app);

        for (uint i = 0; i < ghosts.Length; i++) {
            // get the data for every ghost and save in the list
            allGhosts.InsertLast(GetSamplesFromGhost(ghosts[i]));

            print("Read ghost " + i);
        }
    }

    return allGhosts;
}