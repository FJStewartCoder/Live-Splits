class Miscellaneous {
    // name is the string name
    // id is a numeric identifier
    wstring name;
    uint id;

    // as milliseconds
    int gap;
    // gap relative to ghost points
    int relGap; 

    // index of the previous gap
    uint lastIdx;
}


bool isMiscArraySet = false;


// reset the misc array to blank values
// reset and add an extra space for the player
void ResetMiscArray(array<Miscellaneous> @miscArray) {
    isMiscArraySet = false;

    for (uint i = 0; i < miscArray.Length; i++) {
        miscArray[i].id = 0;

        miscArray[i].gap = 0;
        miscArray[i].relGap = 0;

        // reset last index
        miscArray[i].lastIdx = 0;
    }
}


// function that creates the misc array
// must be called once the race has started once
void MakeMiscArray(CGameCtnGhost@[] @allCurrentCars, array<Miscellaneous> @miscArray) {
    // don't try to make it if it already exists
    if (isMiscArraySet) {
        return;
    }

    miscArray.Resize(allCurrentCars.Length + 1);

    // gets the id for all of the cars
    for (int i = 0; i < allCurrentCars.Length; i++) {
        // place at one less than the i because i starts at 1
        miscArray[i].name = allCurrentCars[i].GhostNickname;
        miscArray[i].id = i + 1;

        print("Current Car ID: " + miscArray[i].id);
    }

    isMiscArraySet = true;
}


void ResetMiscItem(Miscellaneous @miscPtr) {
    miscPtr.name = "";

    // reset the last idx
    miscPtr.lastIdx = 0;

    // reset gaps
    miscPtr.gap = 0;
    miscPtr.relGap = 0;
}
