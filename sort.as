funcdef int COMPARE(int, int);
funcdef int TRANSFORM(uint64);

// TODO: IMPLEMENT LIKE QUICK SORT OR SOMETHING
void Sort(array<uint64>@ arr, COMPARE@ compFunc, TRANSFORM@ transFunc) {
    while (true) {
        bool swapped = false;

        for (uint i = 0; i < arr.Length - 1; i++) {
            uint64 temp;
            uint64 cur = arr[i];
            uint64 next = arr[i + 1];

            int compRes = compFunc( transFunc(cur), transFunc(next) );

            if (compRes > 0) {
                temp = cur;

                arr[i] = next;
                arr[i + 1] = temp;

                swapped = true;
            }
        }

        if (!swapped) { break; }
    }
}