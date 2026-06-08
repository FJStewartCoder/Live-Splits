// a set of save file names excluding the file extension and directories

/*
a namespace denotes a section of the settings, this must have either a file or directory in it
files must be as follows

type = const string
variable name = *category*_file (only include *category*_ if there is more that one file)

the same applies to directories by directory instead of file
*/

namespace SaveLocations {
    // the main directory that the settings will be saved
    IOX::Entry directory(
        "LiveSplitsSettings",
            IO::FromStorageFolder(""),
        "", IOX::Type::Directory
    );

    // general, save, logger, gap and cache are all in this file
    namespace Base {
        IOX::Entry file(
            IOX::PathConcat({SaveLocations::directory.name, "settings"}),
            IO::FromStorageFolder(""),
            "json", IOX::Type::File
        );
    }

    namespace UI {
        IOX::Entry directory(
            IOX::PathConcat({SaveLocations::directory.name, "ui"}),
            IO::FromStorageFolder(""),
            "", IOX::Type::Directory
        );

        // stores which UI options are enabled
        IOX::Entry baseFile(
            IOX::PathConcat({UI::directory.name, "base"}),
            IO::FromStorageFolder(""),
            "json", IOX::Type::File
        );

        // stores the configuration of the bar UI
        IOX::Entry barFile(
            IOX::PathConcat({UI::directory.name, "bar"}),
            IO::FromStorageFolder(""),
            "json", IOX::Type::File
        );

        // stores the configuration of the table UI
        IOX::Entry normalFile(
            IOX::PathConcat({UI::directory.name, "normal"}),
            IO::FromStorageFolder(""),
            "json", IOX::Type::File
        );
    }

    namespace Performance {
        IOX::Entry file(
            IOX::PathConcat({directory.name, "performance"}),
            IO::FromStorageFolder(""),
            "json", IOX::Type::File
        );
    }
}