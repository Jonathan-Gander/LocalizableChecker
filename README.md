# LocalizableChecker
A Swift CLI to check if a key from a Localizable.strings file is unused in your project.

When you're building a translated app, you create a lot of translation keys and values. Sometimes you remove some code but you forget to remove matched translation keys. Your translation file is getting longer and you lose time to translate keys that are not yet used in your app.

This tool is for you! It will print every key from a `Localizable.strings` file that are not used in your app.

## Usage 

### Installation

Git clone project and open it.

### Settings

Before running this tool, you have to modify 3 variables:

- `sourceFilePath`: It's the path to your `Localizable.strings` in which it will check keys. Include the file name and its extension.
- `projectPath`: It's the path of your project in which each key will be checked. (The file set in `sourceFilePath` could be in this directory.)
- `expectedMinimalNbTimes`: It's the number of time you expect each key to be in files at least. For example, if you have two Localizable.strings files (for two languages), set this value to 2, because you're sure it will appear at least 2 times in browsed files. If it appears only 2 times (or less), that means it is unused in your project.

### Run

Then run the tool ... and wait.  
As it will open each file for each key, it may take long. If you are impatient, you can add a `else` after `if nbFound <= expectedMinimalNbTimes { ... }` to log when a key is used. ;)

## Licence

Be free to use my `LocalizableChecker`. Licence is available [here](https://github.com/Jonathan-Gander/LocalizableChecker/blob/main/LICENSE).
