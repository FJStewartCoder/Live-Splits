funcdef int COMPARE(ref@, ref@);

// TODO: IMPLEMENT LIKE QUICK SORT OR SOMETHING
void Sort(array<ref@>@ arr, COMPARE@ compFunc) {
    print(arr.Length);
    if (arr.IsEmpty()) { return; }

    while (true) {
        bool swapped = false;

        for (uint i = 0; i < arr.Length - 1; i++) {
            trace("Init variables");
            ref@ temp = null;
            ref@ cur = arr[i];
            ref@ next = arr[i + 1];

            trace("Comparing");
            int compRes = compFunc( cur, next );

            trace("Compare res: " + compRes);

            if (compRes > 0) {
                trace("Swapping");
                @temp = cur;

                @arr[i] = next;
                @arr[i + 1] = temp;

                swapped = true;
            }
        }

        if (!swapped) { break; }
    }
}