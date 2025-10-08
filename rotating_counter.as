class RotatingCounter {
    // how many rotations before resetting
    private uint rotationCount;
    // current count
    private uint currentCount;

    // updates the current count then resets it to 0
    void UpdateRotatingCount(uint count) {
        rotationCount = count;
        currentCount = 0;
    }

    // increments then mod by rotation count
    void Increment(uint count = 1) {
        currentCount = (currentCount + count) % rotationCount;
    }

    // gets the value
    bool GetValue() {
        return currentCount == 0;
    }

    // resets current count to 0
    void Reset() {
        currentCount = 0;
    }

    RotatingCounter(uint count) {
        rotationCount = count;
        currentCount = 0;
    }
}