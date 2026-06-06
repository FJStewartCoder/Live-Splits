namespace Settings {
    namespace General {
        bool pluginEnabled = true;
    }

    namespace Save {
        bool enabled = true;
    }

    namespace Logger {
        // hard limit on the array size
        uint arrayMaxSize = 1000000;  // 1,000,000
    }

    namespace Gap {
        // max number of ghost cars 
        uint8 numCars = 3;

        // show gap even if not array complete (for long maps)
        // WILL NOT SHOW GAP IF YOU ARE AHEAD
        bool getGapOverride = false;

        uint searchRangeSeconds = 1;

        // bool to use linear gap or not
        bool useLinearGap = false;

        // number of points per second to check when using modified linear alg
        uint modLinResolution = 10;

        // which gap algorithm to use
        GapAlgorithm algorithm;
    }

    namespace Cache {
        // toggle for if you want to use the cache or not
        // will allow for support of multiplayer
        bool enabled = true;

        // the max size of the cache per cache list
        uint maxSize = 10000;

        // used to increase the likelihood of cache hits with a smaller cache size my guessing the gap
        bool useApproximation = false;
    }

    namespace UI {
        // each setting is represented as one bit shifted by some amount
        int enabledRenderingOptions = 2;  // by default is bar

        Render::BarSettings barSettings;
        Render::NormalSettings normalSettings;
    }

    namespace Performance {
        uint framesBetweenLogValue = 1;
        uint framesBetweenGapValue = 1;
    }
}