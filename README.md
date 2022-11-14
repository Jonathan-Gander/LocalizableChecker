# LocalizableChecker
A Swift CLI to check if keys from a Localizable.strings file are unused in your project.

When you're building a translated app, you create a lot of translation keys and values. Sometimes you remove some code but you forget to remove matched translation keys. Your translation file is getting longer and you lose time to translate keys that are not yet used in your app.

This tool is for you! It will print every key from a `Localizable.strings`  file (or any `.strings` file) that are not used in your app.

And, it can also log if a key has an empty value, such as `"mv.help.text" = "";`.

## Usage 

### Installation
```
$ git clone https://github.com/Jonathan-Gander/LocalizableChecker
$ cd LocalizableChecker
```

### Arguments and options

There are 3 mandatory arguments:

- `source-file-path`: The path to your `Localizable.strings` file where are the keys to check (including filename and its extension).
- `project-path`: The path to your project or directory in which each key will be check. Note that your `Localizable.strings` file can be in this directory also.
- `allow-nb-times`: Number of times each key will be found at least. For example, if you search in all files and your project directory contains two `Localizable.strings` files (one for each language), this value should be 2. Because you are sure all keys will be found at least two times. That means, if a key is found two times (or less), it is unused in your project because it only appears in your two `Localizable.strings` files.  
If you set 'extensions' option (see below) to only search in .swift files for example, you can set this argument to 0.

And 3 options:

- `--extensions` or `--allowed-files-extensions`: You can choose to only search in files with specific extensions. For example, if you want to check only in Swift files, you can set this option to `swift` (do not add the dot). If you want to specify many extensions, write them spearated by a comma: `swift,m`.    
Setting specific extensions will make faster search.
- `--log-empty-values`: Add this option to also log if a key has an empty value. For example `"mv.help.text" = "";` would log the key because its value is an empty string.
- `--anxious-mode`: Add this option to print each time a key is found in project. It will add more log and reduce your anxiety of seeing nothing printed. ;)

### Run

Examples:

```
# Search in all files. And have probably 2 Localizable.strings files.
$ swift run LocalizableChecker "/Users/user/Projects/myproject/myproject/Resources/en.lproj/Localizable.strings" "/Users/user/Projects/myproject" 2

# Search in files with .swift extensions only.
$ swift run LocalizableChecker "/Users/user/Projects/myproject/myproject/Resources/en.lproj/Localizable.strings" "/Users/user/Projects/myproject" 0 --extensions swift

# Search in files with .swift extensions only. Also log empty values.
$ swift run LocalizableChecker "/Users/user/Projects/myproject/myproject/Resources/en.lproj/Localizable.strings" "/Users/user/Projects/myproject" 0 --extensions swift --log-empty-values
```

### Output

Typical output log: 

```
👋 Welcome in LocalizableChecker
This tool will check if keys from a Localizable.strings file are unused in your project.
Created by Jonathan Gander
--------------------------------------------------------

Will check keys from file...
    /Users/user/Projects/myproject/myproject/Resources/en.lproj/Localizable.strings
in files with extension swift from directory...
    /Users/user/Projects/myproject

ℹ️ Empty values will be logged.

🚀 running ...
(It may take quite long! If you see nothing and it makes you anxious, try setting anxiousMode to true.)

🛑 key '"mpv.position"' is unused (found 0 time).
⚠️ warning, key '"mv.help.text"' has an empty value.
🛑 key '"wv.title"' is unused (found 0 time).

🎉 finished!
```

## Licence

Be free to use my `LocalizableChecker`. Licence is available [here](https://github.com/Jonathan-Gander/LocalizableChecker/blob/main/LICENSE).
