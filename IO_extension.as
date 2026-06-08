// IOX is IO eXtension
namespace IOX {
    enum Type {
        File,
        Directory
    }

    const string PathConcat(
        const string[] parts
    ) {
#if WINDOWS
        const string slashSymbol = "\\";
#else
        const string slashSymbol = "/";
#endif

        string res = "";

        for (uint i = 0; i < parts.Length; i++) {
            // add the file path part
            res += parts[i];

            // if the part is not the last, add a slash symbol
            const bool isLastPart = i == parts.Length - 1;
            
            if (!isLastPart) {
                res += slashSymbol;
            }

        }

        // return the result
        return res;
    }

    class Entry {
        string root;

        string name;
        string fileType;

        Type type;

        const string Path() {
            if (type == Type::Directory) {
                return PathConcat({root, name});
            }

            return PathConcat({root, name}) + "." + fileType;
        };

        bool Exists() {
            if (type == Type::File) {
                return IO::FileExists(Path());
            }
            else {
                return IO::FolderExists(Path());
            }
        }

        // returns true if created
        // returns false if not
        bool Create(
            bool createOverride = false  // will be overwritten if exists
        ) {
            if (type == Type::Directory) {
                // create the folder
                IO::CreateFolder(Path());
                return true;
            }

            // if we are not overriding existing files and it already exists, do nothing
            if (!createOverride && Exists()) {
                return false;
            }

            // type is file
            IO::File file(Path(), IO::FileMode::Write);

            // the file seems to be already open???
            // then, empty it, then close the file
            file.Write("");
            file.Close();

            // was successfully created so return true
            return true;
        }

        Entry(
            const string&in name,
            const string&in root,
            const string&in fileType = "txt",
            Type type = Type::File
        ) {
            this.name = name;
            this.fileType = fileType;
            this.type = type;
            this.root = root;
        }
        
        Entry() {}
    }
}