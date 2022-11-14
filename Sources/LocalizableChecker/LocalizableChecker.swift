//
//  LocalizableChecker.swift
//
//  Created by Jonathan Gander on 14.11.22.
//
import Foundation
import ArgumentParser

@main
struct LocalizableChecker: ParsableCommand {
    
    // MARK: - Arguments
    @Argument(help: "Path to file where are the keys to check (including filename and its extension).")
    var sourceFilePath: String
    
    @Argument(help: "Path to your project or directory in which each key will be check.")
    var projectPath: String
    
    @Argument(help: "Number of times each key will be found at least. For example, if you search in all files and your project directory contains two Localizable.strings files (one for each language), this value should be 2. Because you are sure all keys will be found at least two times. That means, if a key is found two times (or less), it is unused in your project because it only appears in your two Localizable.strings files. If you set 'extensions' option to only search in .swift files for example, you can set this argument to 0.")
    var allowNbTimes: Int

    // MARK: - Options
    @Option(name: [.customLong("extensions"), .long],
            help: "Set extensions of files in which you want to search for keys. If you don't set this parameter, it will search in all files. Do not add a dot, only extensions, spearated by a comma.",
            transform: { str in
        if str.contains(",") {
            return str.split(separator: ",").map({ String($0) })
        }
        else {
            return [str]
        }
    })
    var allowedFilesExtensions: [String] = []
    
    @Flag(help: "Add this option to also check if a key has an empty value. For example, this line would be logged: \"mv.help.text\" = \"\";")
    var logEmptyValues: Bool = false
    
    @Flag(help: "Add this option to print each time a key is found in project. It will add more log and reduce your anxiety of seeing nothing printed. ;)")
    var anxiousMode: Bool = false
    
    // MARK: - Main
    func run() {
        
        print("👋 Welcome in LocalizableChecker")
        print("This tool will check if keys from a Localizable.strings file are unused in your project.")
        print("Created by Jonathan Gander")
        print("--------------------------------------------------------\n")

        print("Will check keys from file...\n\t\(sourceFilePath)")
        printMessageExtensions()
        
        if logEmptyValues {
            print("ℹ️ Empty values will be logged.\n")
        }
        
        if anxiousMode {
            print("ℹ️ Anxious mode is enabled. It will print a lot of text. Set anxiousMode variable to false to only log unused keys.\n")
        }
        
        print("🚀 running ...\n(It may take quite long! If you see nothing and it makes you anxious, enable anxious mode option.)\n")
        
        // Check input file and directory
        if !FileManager.default.fileExists(atPath: sourceFilePath) {
            print("⛔️ File \(sourceFilePath) does not exist. Could not start tool.")
            return
        }
        
        if !FileManager.default.fileExists(atPath: projectPath) {
            print("⛔️ Directory \(projectPath) does not exist. Could not start tool.")
            return
        }
        
        // Run
        foreachLine(inFile: sourceFilePath, apply: { line in
            checkUnusedKey(fromLine: line, inFilesInDirectory: projectPath, withExtensions: allowedFilesExtensions, expectedMinimalNbTimes: allowNbTimes)
        })
        
        print("\n🎉 finished!")
    }
    
    // MARK: -
    /// Check if current line is used in all files from directory.
    /// - Parameters:
    ///   - line: line to check
    ///   - directory: root directory where to check files
    ///   - withExtensions: if set will only search in files with those extensions. If array is empty, search in all files.
    ///   - expectedMinimalNbTimes: number of times the key is at least and can be considered like unused if less or equal to this value
    private func checkUnusedKey(fromLine line: String, inFilesInDirectory directory: String, withExtensions: [String], expectedMinimalNbTimes: Int) {
        
        guard let key = getKey(line) else { return }
        
        var nbFound = 0
        foreachFile(inDirectory: directory, withExtensions: withExtensions, recursive: true, apply: { filePath in
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
    private func foreachLine(inFile filePath: String, apply: (String) -> Void) {
        guard let contents = try? String(contentsOfFile: filePath) else { return }
        let lines = contents.split(separator:"\n")
        for line in lines {
            apply(String(line))
        }
    }
    
    /// - Parameters:
    ///   - directory: root directory
    ///   - allowedExtensions: if set will only browse files with those extensions. If array is empty, browse all files.
    ///   - recursive: set to true to browse subdirectories
    ///   - apply: function to apply to each file. Takes file path as parameters
    private func foreachFile(inDirectory directory: String, withExtensions allowedExtensions: [String], recursive: Bool = false, apply: (String) -> Void) {
        
        let fileManager = FileManager.default
        
        guard let directoryContent = try? fileManager.contentsOfDirectory(atPath: directory) else {
            fatalError("Could not open directory \(directory).")
        }
        
        for item in directoryContent {
            let itemURL = URL(fileURLWithPath: directory).appendingPathComponent(item)
            if isDirectory(itemURL) {
                
                if recursive {
                    foreachFile(inDirectory: itemURL.path, withExtensions: allowedExtensions, recursive: recursive, apply: apply)
                }
            }
            else {
                if allowedExtensions.count == 0 || allowedExtensions.contains(itemURL.pathExtension.lowercased()) {
                    apply(itemURL.path)
                }
            }
        }
    }
    
    // MARK: - Helper functions
    
    /// Check if URL is a directory
    /// - Parameter url: url to check
    /// - Returns: true if directory
    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    
    /// Check if a line is a key and value line
    /// Example: "key" = "value";
    /// - Parameter line: line to check
    /// - Returns: true if line is a key and value
    private func isKeyValueLine(_ line: String) -> Bool {
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
    private func getKey(_ line: String) -> String? {
        guard isKeyValueLine(line) else { return nil }
        
        let components = line.split(separator: "=")
        guard components.count == 2 else { return nil }
        
        var key = String(components.first!)
        key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard key.hasPrefix("\"") && key.hasSuffix("\"") else { return nil }
        
        if logEmptyValues {
            var value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            if value.hasSuffix(";") {
                value.removeLast()
                value = value.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if value == "\"\"" {
                    print("⚠️ warning, key '\(key)' has an empty value.")
                }
            }
        }
        
        return key
    }
    
    // MARK: -
    private func printMessageExtensions() {
        var str = "in"
        
        if allowedFilesExtensions.count == 0 {
            str += " all files"
        }
        else if allowedFilesExtensions.count == 1 {
            str += " files with extension \(allowedFilesExtensions.first!)"
        }
        else if allowedFilesExtensions.count > 1 {
            str += " files with extensions \(allowedFilesExtensions.joined(separator: ", "))"
        }
        
        str += " from directory...\n\t\(projectPath)\n"
        print(str)
    }
}
