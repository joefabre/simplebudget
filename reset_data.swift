#!/usr/bin/swift

import Foundation

print("SimpleBudget Data Reset Utility")
print("===============================")
print("This script will reset all data in the SimpleBudget app to 0.")

// Find Core Data store files
let fileManager = FileManager.default
let appGroupID = "SimpleBudget" // May need to be adjusted if app uses a different identifier

// Check common locations for Core Data store files
let libraryDirs = [
    // App sandbox location for MacOS app
    "\(NSHomeDirectory())/Library/Containers/com.yourcompany.SimpleBudget/Data/Library/Application Support/SimpleBudget",
    // Local development location
    "\(NSHomeDirectory())/Library/Developer/CoreSimulator/Devices",
    // Direct location if running as Mac app
    "\(NSHomeDirectory())/Library/Application Support/SimpleBudget"
]

var foundFiles = false
var foundDBFiles: [URL] = []

for baseDir in libraryDirs {
    if fileManager.fileExists(atPath: baseDir) {
        // Look for SQLite files
        let searchPaths: [String]
        
        if baseDir.contains("CoreSimulator") {
            // Need to search through simulator directories
            do {
                let deviceDirs = try fileManager.contentsOfDirectory(atPath: baseDir)
                var searchDirs: [String] = []
                
                for deviceDir in deviceDirs {
                    let fullDevicePath = "\(baseDir)/\(deviceDir)/data/Containers/Data/Application"
                    if fileManager.fileExists(atPath: fullDevicePath) {
                        searchDirs.append(fullDevicePath)
                    }
                }
                
                searchPaths = searchDirs
            } catch {
                print("Error searching simulator directories: \(error)")
                searchPaths = []
            }
        } else {
            searchPaths = [baseDir]
        }
        
        for searchPath in searchPaths {
            do {
                // Recursively search for SimpleBudget.sqlite files
                let command = "find \"\(searchPath)\" -name \"SimpleBudget.sqlite\" -type f 2>/dev/null"
                let process = Process()
                process.launchPath = "/bin/bash"
                process.arguments = ["-c", command]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                
                try process.run()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                
                if let output = String(data: data, encoding: .utf8) {
                    let files = output.components(separatedBy: "\n").filter { !$0.isEmpty }
                    
                    for file in files {
                        print("Found database file: \(file)")
                        foundFiles = true
                        foundDBFiles.append(URL(fileURLWithPath: file))
                        
                        // Also add related files
                        let shmFile = "\(file)-shm"
                        let walFile = "\(file)-wal"
                        
                        if fileManager.fileExists(atPath: shmFile) {
                            foundDBFiles.append(URL(fileURLWithPath: shmFile))
                        }
                        
                        if fileManager.fileExists(atPath: walFile) {
                            foundDBFiles.append(URL(fileURLWithPath: walFile))
                        }
                    }
                }
                
            } catch {
                print("Error searching in \(searchPath): \(error)")
            }
        }
    }
}

if !foundFiles {
    print("No SimpleBudget database files found.")
    print("The app may not have been launched yet, or the database may be stored elsewhere.")
    exit(1)
}

// Confirm with user
print("\nFound \(foundDBFiles.count) database-related files.")
print("Deleting these files will reset all data to 0 the next time you launch the app.")
print("The app will recreate default accounts with zero balances.")
print("\nDo you want to proceed? (y/n): ", terminator: "")

if let response = readLine()?.lowercased(), response == "y" || response == "yes" {
    // Delete the files
    for fileURL in foundDBFiles {
        do {
            try fileManager.removeItem(at: fileURL)
            print("Deleted: \(fileURL.path)")
        } catch {
            print("Failed to delete \(fileURL.path): \(error)")
        }
    }
    
    print("\nAll data has been reset.")
    print("The next time you launch SimpleBudget, it will create fresh data with all values set to 0.")
} else {
    print("\nOperation cancelled. No files were deleted.")
}

