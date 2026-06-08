class RotatingCounter {
    // how many rotations before resetting
    private uint rotationCount;
    // current count
    private uint currentCount;

    // --------------------------------------

    // gets the current rotation count (private so needs a function to get)
    uint GetCount() {
        return rotationCount;
    }

    // updates the current count then resets it to 0
    void SetCount(uint count) {
        rotationCount = count;
        currentCount = 0;
    }

    // --------------------------------------

    // gets the value
    bool GetValue() {
        return currentCount == 0;
    }

    // resets current count to 0
    void Reset() {
        currentCount = 0;
    }

    // --------------------------------------

    // increments then mod by rotation count
    void Increment(uint count = 1) {
        currentCount = (currentCount + count) % rotationCount;
    }

    // --------------------------------------

    RotatingCounter(uint count) {
        rotationCount = count;
        currentCount = 0;
    }
}