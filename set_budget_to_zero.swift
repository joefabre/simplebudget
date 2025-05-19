#!/usr/bin/swift

import Foundation
import CoreData

print("SimpleBudget - Reset Budget to Zero Utility")
print("===========================================")
print("This script will set the current month's budget amount to 0.")

// Find the CoreData database
let fileManager = FileManager.default
let searchPaths = [
    "\(NSHomeDirectory())/Library/Developer/CoreSimulator/Devices",
    "\(NSHomeDirectory())/Library/Containers/com.yourcompany.SimpleBudget/Data/Library/Application Support",
    "\(NSHomeDirectory())/Library/Application Support/SimpleBudget"
]

var dbPath: String? = nil

// Search for the database file
for searchPath in searchPaths {
    if fileManager.fileExists(atPath: searchPath) {
        let command = "find \"\(searchPath)\" -name \"SimpleBudget.sqlite\" -type f 2>/dev/null"
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8) {
                let files = output.components(separatedBy: "\n").filter { !$0.isEmpty }
                if let firstFile = files.first {
                    dbPath = firstFile
                    print("Found database at: \(firstFile)")
                    break
                }
            }
        } catch {
            print("Error searching in \(searchPath): \(error)")
        }
    }
}

guard let databasePath = dbPath else {
    print("Error: Could not find SimpleBudget database file.")
    exit(1)
}

// Set up Core Data stack
let modelURL = URL(fileURLWithPath: "\(NSHomeDirectory())/Desktop/SimpleBudget/SimpleBudget/SimpleBudget/Models/SimpleBudget.xcdatamodeld")
guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
    print("Error: Could not create managed object model.")
    print("Please make sure the SimpleBudget.xcdatamodeld file is accessible.")
    print("Alternative method: Open the app and set the budget to 0 manually.")
    exit(1)
}

let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
let storeURL = URL(fileURLWithPath: databasePath)

do {
    try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
} catch {
    print("Error: Could not add persistent store: \(error)")
    print("Try launching the app and setting the budget to 0 manually.")
    exit(1)
}

let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
context.persistentStoreCoordinator = psc

// Get current month and year
let calendar = Calendar.current
let currentDate = Date()
let month = calendar.component(.month, from: currentDate)
let year = calendar.component(.year, from: currentDate)
let monthString = String(format: "%02d", month)

// Find current month's budget
let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Budget")
fetchRequest.predicate = NSPredicate(format: "month == %@ AND year == %d", monthString, year)

do {
    let budgets = try context.fetch(fetchRequest)
    
    if budgets.isEmpty {
        print("No budget found for \(calendar.monthSymbols[month-1]) \(year).")
        print("No changes were made.")
        exit(0)
    }
    
    for budget in budgets {
        let oldAmount = budget.value(forKey: "amount") as? Double ?? 0
        
        // Set budget amount to 0
        budget.setValue(0.0, forKey: "amount")
        
        // Add note that budget was reset
        let existingNotes = budget.value(forKey: "notes") as? String ?? ""
        let updatedNotes = existingNotes + "\n\nBudget reset to 0 on \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
        budget.setValue(updatedNotes, forKey: "notes")
        
        print("Updated budget from $\(String(format: "%.2f", oldAmount)) to $0.00")
    }
    
    try context.save()
    print("Budget successfully set to zero.")
    print("You'll see this change next time you open the app.")
    
} catch {
    print("Error updating budget: \(error)")
    print("Try launching the app and setting the budget to 0 manually.")
    exit(1)
}

