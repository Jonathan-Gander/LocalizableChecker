//
//  main.swift
//  LocalizableChecker
//
//  Created by Jonathan Gander on 12.11.22.
//

import Foundation

@main
struct LocalizableChecker {
    
    // Path to file where are the keys (including file name and its extension)
    // For example, your Localizable.strings file.
    static let sourceFilePath = "/Users/user/Projects/myproject/myproject/Resources/en.lproj/Localizable.strings"
    
    // Path to your project or directory in which each key will be check.
    static let projectPath = "/Users/user/Projects/myproject"
    
    // Set extensions of files in which you want to find keys. If you let this array empty, will check in all files. Do not add a dot.
    // For example: ["swift"] to only check in Swift files.
    static let allowedFilesExtensions: [String] = ["swift"]
    
    // How many times you know each key will appear at least in your projectPath directory (in files with allowed extensions) so it is considered unused.
    // Note: For example, if you have two Localizable.strings files (for two languages), set this to 2.
    //       Because you're sure each key will appear at least 2 times in browsed files.
    // If you have allowed only .swift files (in allowedFilesExtensions variable), you can set this value to 0.
    static let expectedMinimalNbTimes: Int = 0
    
    // Set this to true to also check if a key has an empty value. For example, this line would be logged: "mv.help.text" = "";
    // This will add a message in log when an empty value is found.
    static let logEmptyValues = true
    
    // Set this to true to print when a key is found in project. It will add more log and reduce your anxiety of seeing nothing printed. ;)
    static let anxiousMode = false
    
    // MARK: - Main
    static func main() async throws {
        
        print("👋 Welcome in LocalizableChecker")
        print("This tool will check if keys from a Localizable.strings file are unused in your project.")
        print("Created by Jonathan Gander")
        print("--------------------------------------------------------\n")

        print("Will check keys from file...\n\t\(sourceFilePath)\nin files from directory...\n\t\(projectPath)\n")
        
        if allowedFilesExtensions.count > 0 {
            print("ℹ️ Will only check in files with extensions: \(allowedFilesExtensions.joined(separator: ", ")).\n")
        }
        
        if logEmptyValues {
            print("ℹ️ Empty values will be logged.\n")
        }
        
        if anxiousMode {
            print("ℹ️ Anxious mode is enabled. It will print a lot of text. Set anxiousMode variable to false to only log unused keys.\n")
        }
        
        print("Ready? Tap any key to start.")
        let _ = readLine()
        print("🚀 running ...\n(It may take quite long! If you see nothing and it makes you anxious, try setting anxiousMode to true.)\n")
        
        foreachLine(inFile: sourceFilePath, apply: { line in
            checkUnusedKey(fromLine: line, inFilesInDirectory: projectPath, expectedMinimalNbTimes: expectedMinimalNbTimes)
        })
        
        print("\n🎉 finished!")
    }
    
    /// Check if current line is used in all files from directory.
    /// - Parameters:
    ///   - line: line to check
    ///   - directory: root directory where to check files
    ///   - expectedMinimalNbTimes: number of times the key is at least and can be considered like unused if less or equal to this value
    static func checkUnusedKey(fromLine line: String, inFilesInDirectory directory: String, expectedMinimalNbTimes: Int) {
        
        guard let key = getKey(line) else { return }
        
        var nbFound = 0
        foreachFile(inDirectory: directory, recursive: true, apply: { filePath in
            foreachLine(inFile: filePath, apply: { line in
                if line.contains(key) {
                    nbFound += 1
                }
            })
        })
        
        if nbFound <= expectedMinimalNbTimes {
            print("🛑 key '\(key)' is unused (found \(nbFound) \(nbFound > 1 ? "times" : "time")).")
        }
        else if anxiousMode {
            print("✅ key '\(key)' is used \(nbFound) \(nbFound > 1 ? "times" : "time").")
        }
    }
    
    
    /// Browse each line of a file and apply a function on each
    /// - Parameters:
    ///   - filePath: file path
    ///   - apply: function to apply to each line. Takes a line as parameter.
    static func foreachLine(inFile filePath: String, apply: (String) -> Void) {
        guard let contents = try? String(contentsOfFile: filePath) else { return }
        let lines = contents.split(separator:"\n")
        for line in lines {
            apply(String(line))
        }
    }
    
    
    /// Browse each file of a directory and apply a function on each
    /// - Parameters:
    ///   - directory: root directory
    ///   - recursive: set to true to browse subdirectories
    ///   - apply: function to apply to each file. Takes file path as parameters
    static func foreachFile(inDirectory directory: String, recursive: Bool = false, apply: (String) -> Void) {
        
        let fileManager = FileManager.default
        
        guard let directoryContent = try? fileManager.contentsOfDirectory(atPath: directory) else {
            fatalError("Could not open directory \(directory).")
        }
        
        for item in directoryContent {
            let itemURL = URL(fileURLWithPath: directory).appendingPathComponent(item)
            if isDirectory(itemURL) {
                
                if recursive {
                    foreachFile(inDirectory: itemURL.path, recursive: recursive, apply: apply)
                }
            }
            else {
                if allowedFilesExtensions.count == 0 || allowedFilesExtensions.contains(itemURL.pathExtension.lowercased()) {
                    apply(itemURL.path)
                }
            }
        }
    }
    
    // MARK: - Helper functions
    
    /// Check if URL is a directory
    /// - Parameter url: url to check
    /// - Returns: true if directory
    static func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    
    /// Check if a line is a key and value line
    /// Example: "key" = "value";
    /// - Parameter line: line to check
    /// - Returns: true if line is a key and value
    static func isKeyValueLine(_ line: String) -> Bool {
        let line = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Starts with " and finish with ;
        guard line.hasPrefix("\"") && line.hasSuffix(";") else { return false }
        
        // And contains exaclty one =
        guard line.split(separator: "=").count == 2 else { return false }
        
        return true
    }
    
    
    /// Returns key from a line. nil if line is not a key and value line.
    /// - Parameter line: line to get key from
    /// - Returns: key or nil
    static func getKey(_ line: String) -> String? {
        guard isKeyValueLine(line) else { return nil }
        
        let components = line.split(separator: "=")
        guard components.count == 2 else { return nil }
        
        var key = String(components.first!)
        key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard key.hasPrefix("\"") && key.hasSuffix("\"") else { return nil }
        
        if logEmptyValues && components[1].trimmingCharacters(in: .whitespacesAndNewlines) == "\"\";" {
            print("⚠️ warning, key '\(key)' has an empty value.")
        }
        
        return key
    }
}
