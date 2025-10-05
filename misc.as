// TODO: FIX ALL BECAUSE ALL VARS CAN NOT BE ACCESSED


class Miscellaneous {
    uint32 arraySize = 0;
    bool isArrayComplete = false;

    uint id;
    // as milliseconds
    int gap;
}


bool isMiscArraySet = false;


// gets the ID in the misc array of the car based on the id
// return -1 if not found
int IndexFromId(MwId carId, uint8 numCars, array<Miscellaneous> @miscArray) {
    // iterate all availible cars
    for (uint8 i = 0; i < numCars; i++) {
        // return index if id matches
        if (carId == miscArray[i].id) {
            return i;
        }
    }

    // return -1 if not in the array
    return -1;
}


// reset the misc array to blank values
void ResetMiscArray(uint8 numCars, array<Miscellaneous> @miscArray) {
    isMiscArraySet = false;

    for (uint8 i = 0; i < numCars; i++) {
        miscArray[i].arraySize = 0;
        miscArray[i].isArrayComplete = false;
        miscArray[i].id = 0;
        miscArray[i].gap = 0;
    }
}


// function that creates the misc array
// must be called once the race has started once
void MakeMiscArray(CSceneVehicleVis@[] allCurrentCars, uint8 numCars, array<Miscellaneous> @miscArray) {
    // don't try to make it if it already exists
    if (isMiscArraySet) {
        return;
    }

    // get the value which is smaller
    // prevents overflowing the array and causing unnecessary processing
    int smallerNumber = (numCars < allCurrentCars.Length) ? numCars : allCurrentCars.Length;

    for (int i = 0; i < smallerNumber; i++) {
        // sets the id
        uint id = GetEntityId(allCurrentCars[i]);

        miscArray[i].id = id;
        print("Current Car ID: " + id);
    }

    isMiscArraySet = true;
}
