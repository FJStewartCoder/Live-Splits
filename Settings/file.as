// save the settings as JSON rather than the in-built system

IOX::Entry@[] GetSettingsFS() {
    return {
        SaveLocations::directory,
        SaveLocations::Base::file,
        SaveLocations::Performance::file,
        SaveLocations::UI::directory,
        SaveLocations::UI::baseFile,
        SaveLocations::UI::normalFile,
        SaveLocations::UI::barFile
    };
}

// returns true if the file stucture is good
// returns false if the file stucture is bad
bool VerifySettingFileStructure() {
    auto entries = GetSettingsFS();

    for (uint i = 0; i < entries.Length; i++) {
        // create a copy of the entry
        IOX::Entry@ entry = entries[i];

        if (!entry.Exists()) { return false; }
    }

    return true;
}

// creates the file structure
void CreateSettingFileStructure() {
    auto entries = GetSettingsFS();

    for (uint i = 0; i < entries.Length; i++) {
        // create a copy of the entry
        IOX::Entry@ entry = entries[i];

        // create the entry
        entry.Create();
    }
}

void HandleFS() {
    if (!VerifySettingFileStructure()) {
        CreateSettingFileStructure();
    }
}

namespace SaveSettings {
    dictionary Cache() {
        dictionary settingsDict = {
            {"enabled", Settings::Cache::enabled},
            {"maxSize", Settings::Cache::maxSize},
            {"useApproximation", Settings::Cache::useApproximation}
        };

        return settingsDict;
    }

    dictionary Gap() {
        dictionary settingsDict = {
            {"numCars", Settings::Gap::numCars},
            {"getGapOverride", Settings::Gap::getGapOverride},
            {"searchRangeSeconds", Settings::Gap::searchRangeSeconds},
            {"useLinearGap", Settings::Gap::useLinearGap},
            {"modLinResolution", Settings::Gap::modLinResolution},
            {"algorithm", Settings::Gap::algorithm}
        };

        return settingsDict;
    }

    dictionary General() {
        dictionary settingsDict = {
            {"pluginEnabled", Settings::General::pluginEnabled}
        };

        return settingsDict;
    }

    dictionary Logger() {
        dictionary settingsDict = {
            {"arrayMaxSize", Settings::Logger::arrayMaxSize}
        };

        return settingsDict;
    }

    dictionary Save() {
        dictionary settingsDict = {
            {"enabled", Settings::Save::enabled}
        };

        return settingsDict;
    }

    void Base() {
        HandleFS();

        dictionary settingsDict = {
            {"cache", Cache()},
            {"gap", Gap()},
            {"general", General()},
            {"logger", Logger()},
            {"save", Save()}
        };

        Json::Value jsonSettings(settingsDict);

        print(Json::Write(jsonSettings, true));

        Json::ToFile(SaveLocations::Base::file.Path(), jsonSettings);
    }

    void BarSettings() {
        // get the settings
        Render::BarSettings@ settings = Settings::UI::barSettings;

        dictionary settingsDict = {
            {"width", settings.width},
            {"height", settings.height},
            {"xPos", settings.xPos},
            {"yPos", settings.yPos},
            {"transparency", settings.transparency},
            {"backgroundColour", Cerealise(settings.backgroundColour)},
            {"outlineColour", Cerealise(settings.outlineColour)},
            {"lineColour", Cerealise(settings.lineColour)},
            {"positiveColour", Cerealise(settings.positiveColour)},
            {"negativeColour", Cerealise(settings.negativeColour)},
            {"textColour", Cerealise(settings.textColour)},
            {"cornerRounding", settings.cornerRounding},
            {"outlineThickness", settings.outlineThickness},
            {"lineThickness", settings.lineThickness},
            {"fontSize", settings.fontSize},
            {"maxPositiveGap", settings.maxPositiveGap},
            {"maxNegativeGap", settings.maxNegativeGap}
        };

        Json::Value settingsJson(settingsDict);

        // write the output to the barFile
        Json::ToFile(SaveLocations::UI::barFile.Path(), settingsJson);
    }

    void TableSettings() {
        Render::NormalSettings@ settings = Settings::UI::normalSettings;

        dictionary settingsDict = {
            {"summary", settings.summary},
            {"numCarsInSummary", settings.numCarsInSummary},
            {"positionSettings", Cerealise(settings.positionSettings)},
            {"positionEnabled", settings.positionEnabled},
            {"nameSettings", Cerealise(settings.nameSettings)},
            {"nameEnabled", settings.nameEnabled},
            {"gapSettings", Cerealise(settings.gapSettings)},
            {"gapEnabled", settings.gapEnabled},
            {"rateSettings", Cerealise(settings.rateSettings)},
            {"rateEnabled", settings.rateEnabled},
            {"sectionHeight", settings.sectionHeight},
            {"playerSectionYMargin", settings.playerSectionYMargin},
            {"position", Cerealise(settings.position)},
            {"neutralColour", Cerealise(settings.neutralColour)},
            {"positiveColour", Cerealise(settings.positiveColour)},
            {"negativeColour", Cerealise(settings.negativeColour)}
        };

        Json::Value settingsJson(settingsDict);

        // write the output to the normalFile
        Json::ToFile(SaveLocations::UI::normalFile.Path(), settingsJson);
    }

    void UI() {
        HandleFS();

        BarSettings();
        TableSettings();

        // save the base settings
        dictionary settingsDict = {
            {"enabledRenderingOptions", Settings::UI::enabledRenderingOptions}
        };

        Json::ToFile(SaveLocations::UI::baseFile.Path(), settingsDict);
    }

    void Performance() {
        HandleFS();

        dictionary settingsDict = {
            {"framesBetweenLogValue", Settings::Performance::framesBetweenLogValue},
            {"framesBetweenGapValue", Settings::Performance::framesBetweenGapValue},
            {"expectedFrameRate", Settings::Performance::expectedFrameRate}
        };

        Json::Value jsonSettings(settingsDict);

        Json::ToFile(SaveLocations::Performance::file.Path(), jsonSettings);
    }

    // just calls every thing else
    void All() {
        Base();
        UI();
        Performance();
    }
}

namespace LoadSettings {
    void Cache(Json::Value@ settings) {
        Settings::Cache::enabled = settings.Get("enabled");
        Settings::Cache::maxSize = settings.Get("maxSize");
        Settings::Cache::useApproximation = settings.Get("useApproximation");
    }

    void Gap(Json::Value@ settings) {
        Settings::Gap::numCars = settings.Get("numCars");
        Settings::Gap::getGapOverride = settings.Get("getGapOverride");
        Settings::Gap::searchRangeSeconds = settings.Get("searchRangeSeconds");
        Settings::Gap::useLinearGap = settings.Get("useLinearGap");
        Settings::Gap::modLinResolution = settings.Get("modLinResolution");
        Settings::Gap::algorithm = intToEnum(settings.Get("algorithm"));
    }

    void General(Json::Value@ settings) {
        Settings::General::pluginEnabled = settings.Get("pluginEnabled");
    }

    void Logger(Json::Value@ settings) {
        Settings::Logger::arrayMaxSize = settings.Get("arrayMaxSize");
    }

    void Save(Json::Value@ settings) {
        Settings::Save::enabled = settings.Get("enabled");
    }

    void Base() {
        HandleFS();

        Json::Value jsonSettings = Json::FromFile(SaveLocations::Base::file.Path());

        Cache(jsonSettings.Get("cache"));
        Gap(jsonSettings.Get("gap"));
        General(jsonSettings.Get("general"));
        Logger(jsonSettings.Get("logger"));
        Save(jsonSettings.Get("save"));
    }

    void BarSettings() {
        // get the settings
        Render::BarSettings@ settings = Settings::UI::barSettings;

        // get the json from the bar file
        Json::Value jsonSettings = Json::FromFile(SaveLocations::UI::barFile.Path());

        // TODO: add protection against null values
        settings.width = jsonSettings.Get("width");
        settings.height = jsonSettings.Get("height");
        settings.xPos = jsonSettings.Get("xPos");
        settings.yPos = jsonSettings.Get("yPos");
        settings.transparency = jsonSettings.Get("transparency");
        settings.backgroundColour = UncerealiseVec3(jsonSettings.Get("backgroundColour"));
        settings.outlineColour = UncerealiseVec3(jsonSettings.Get("outlineColour"));
        settings.lineColour = UncerealiseVec3(jsonSettings.Get("lineColour"));
        settings.positiveColour = UncerealiseVec3(jsonSettings.Get("positiveColour"));
        settings.negativeColour = UncerealiseVec3(jsonSettings.Get("negativeColour"));
        settings.textColour = UncerealiseVec3(jsonSettings.Get("textColour"));
        settings.cornerRounding = jsonSettings.Get("cornerRounding");
        settings.outlineThickness = jsonSettings.Get("outlineThickness");
        settings.lineThickness = jsonSettings.Get("lineThickness");
        settings.fontSize = jsonSettings.Get("fontSize");
        settings.maxPositiveGap = jsonSettings.Get("maxPositiveGap");
        settings.maxNegativeGap = jsonSettings.Get("maxNegativeGap");
    }

    void TableSettings() {
        Render::NormalSettings@ settings = Settings::UI::normalSettings;

        Json::Value jsonSettings = Json::FromFile(SaveLocations::UI::normalFile.Path());

        settings.summary = jsonSettings.Get("summary");
        settings.numCarsInSummary = jsonSettings.Get("numCarsInSummary");

        settings.positionSettings = 
            UncerealiseNormalSectionSettings(jsonSettings.Get("positionSettings"));
        settings.positionEnabled = jsonSettings.Get("positionEnabled");

        settings.nameSettings =
            UncerealiseNormalSectionSettings(jsonSettings.Get("nameSettings"));
        settings.nameEnabled = jsonSettings.Get("nameEnabled");

        settings.gapSettings =
            UncerealiseNormalSectionSettings(jsonSettings.Get("gapSettings"));
        settings.gapEnabled = jsonSettings.Get("gapEnabled");

        settings.rateSettings =
            UncerealiseNormalSectionSettings(jsonSettings.Get("rateSettings"));
        settings.rateEnabled = jsonSettings.Get("rateEnabled");

        settings.sectionHeight = jsonSettings.Get("sectionHeight");
        settings.playerSectionYMargin = jsonSettings.Get("playerSectionYMargin");

        settings.position = UncerealiseVec2(jsonSettings.Get("position"));

        settings.neutralColour = UncerealiseVec4(jsonSettings.Get("neutralColour"));
        settings.positiveColour = UncerealiseVec4(jsonSettings.Get("positiveColour"));
        settings.negativeColour = UncerealiseVec4(jsonSettings.Get("negativeColour"));
    }

    void UI() {
        HandleFS();

        BarSettings();
        TableSettings();

        // load the settings from the base file
        Json::Value jsonSettings = Json::FromFile(SaveLocations::UI::baseFile.Path());

        // load the settings from the json 
        Settings::UI::enabledRenderingOptions = jsonSettings.Get("enabledRenderingOptions");
    }

    void Performance() {
        HandleFS();

        Json::Value jsonSettings = Json::FromFile(SaveLocations::Performance::file.Path());

        Settings::Performance::framesBetweenLogValue = jsonSettings.Get("framesBetweenLogValue");
        Settings::Performance::framesBetweenGapValue = jsonSettings.Get("framesBetweenGapValue");
        Settings::Performance::expectedFrameRate = jsonSettings.Get("expectedFrameRate");
    }

    // calls the other functions
    void All() {
        Base();
        UI();
        Performance();
    }
}

// allows importing specific settings files
namespace ImportSettings {

}