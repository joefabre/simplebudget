import CoreData
import CloudKit

struct PersistenceController {
    // Shared instance for the app
    static let shared = PersistenceController()
    
    // Core Data container
    let container: NSPersistentContainer
    
    // For SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Create preview data
        let viewContext = controller.container.viewContext
        
        // Create a sample budget for current month
        let currentBudget = Budget(context: viewContext)
        currentBudget.id = UUID()
        currentBudget.amount = 1500.00
        
        // Set to current month
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let year = calendar.component(.year, from: Date())
        currentBudget.month = String(format: "%02d", month)
        currentBudget.year = Int16(year)
        currentBudget.notes = "Budget for \(calendar.monthSymbols[month-1]) \(year)"
        
        // Create a sample budget for previous month
        let prevDate = calendar.date(byAdding: .month, value: -1, to: Date())!
        let prevMonth = calendar.component(.month, from: prevDate)
        let prevYear = calendar.component(.year, from: prevDate)
        
        let previousBudget = Budget(context: viewContext)
        previousBudget.id = UUID()
        previousBudget.amount = 1400.00
        previousBudget.month = String(format: "%02d", prevMonth)
        previousBudget.year = Int16(prevYear)
        previousBudget.notes = "Budget for \(calendar.monthSymbols[prevMonth-1]) \(prevYear)"
        
        // Create sample transactions
        let categories = ["Food", "Transportation", "Housing", "Entertainment", "Shopping", "Healthcare", "Utilities"]
        let titles = [
            "Grocery shopping", "Uber ride", "Monthly rent", "Movie tickets", 
            "New clothes", "Pharmacy", "Electric bill", "Restaurant", "Gas",
            "Internet bill", "Coffee", "Gym membership", "Birthday gift"
        ]
        
        // Transaction amounts
        let amounts = [45.67, 12.50, 900.00, 32.99, 78.50, 25.75, 110.25, 58.30, 40.00, 75.00, 5.25, 55.00, 35.00]
        
        // Create transactions for current month
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        for i in 0..<10 {
            let transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            
            // Get random date within current month
            let maxDays = (calendar.range(of: .day, in: .month, for: today)?.count ?? 30) - 1
            let daysToAdd = Double.random(in: 0.0...(Double(maxDays)))
            let transactionDate = calendar.date(byAdding: .day, value: Int(daysToAdd), to: startOfMonth)!
            
            // Set transaction properties
            transaction.title = titles[i % titles.count]
            transaction.amount = amounts[i % amounts.count]
            transaction.category = categories[i % categories.count]
            transaction.date = transactionDate
            transaction.createdAt = Date()
            transaction.type = "expense"
            transaction.notes = "Sample transaction #\(i+1)"
        }
        
        // Create income transaction
        let income = Transaction(context: viewContext)
        income.id = UUID()
        income.title = "Salary"
        income.amount = 2500.00
        income.category = "Income"
        income.date = calendar.date(byAdding: .day, value: 1, to: startOfMonth)!
        income.createdAt = Date()
        income.type = "income"
        income.notes = "Monthly salary"
        
        // Create sample savings goals
        let savings = Account(context: viewContext)
        savings.id = UUID()
        savings.name = "My Savings"
        savings.type = "savings"
        savings.balance = 15000.0
        savings.icon = "banknote.fill"
        
        let investment = Account(context: viewContext)
        investment.id = UUID()
        investment.name = "My Investments"
        investment.type = "investment"
        investment.balance = 10000.0
        investment.icon = "chart.line.uptrend.xyaxis"
        
        // Create sample goals
        let goal1 = SavingsGoal(context: viewContext)
        goal1.id = UUID()
        goal1.name = "New Car"
        goal1.targetAmount = 25000
        goal1.currentAmount = 15000
        goal1.createdAt = Date()
        goal1.deadline = calendar.date(byAdding: .month, value: 6, to: Date())
        goal1.notes = "Saving for a new electric vehicle"
        goal1.account = savings
        
        let goal2 = SavingsGoal(context: viewContext)
        goal2.id = UUID()
        goal2.name = "Emergency Fund"
        goal2.targetAmount = 10000
        goal2.currentAmount = 10000
        goal2.createdAt = calendar.date(byAdding: .month, value: -2, to: Date())
        goal2.notes = "6 months of expenses"
        goal2.account = savings
        
        let goal3 = SavingsGoal(context: viewContext)
        goal3.id = UUID()
        goal3.name = "Investment Portfolio"
        goal3.targetAmount = 50000
        goal3.currentAmount = 10000
        goal3.createdAt = calendar.date(byAdding: .month, value: -1, to: Date())
        goal3.deadline = calendar.date(byAdding: .year, value: 2, to: Date())
        goal3.notes = "Long-term investment goal"
        goal3.account = investment
        
        // Create transactions for previous month
        let prevMonthStart = calendar.date(from: DateComponents(year: prevYear, month: prevMonth, day: 1))!
        
        for i in 0..<5 {
            let transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            
            // Get random date within previous month
            let maxDays = (calendar.range(of: .day, in: .month, for: prevDate)?.count ?? 30) - 1
            let daysToAdd = Double.random(in: 0.0...(Double(maxDays)))
            let transactionDate = calendar.date(byAdding: .day, value: Int(daysToAdd), to: prevMonthStart)!
            
            // Set transaction properties
            transaction.title = titles[(i+5) % titles.count]
            transaction.amount = amounts[(i+5) % amounts.count]
            transaction.category = categories[(i+5) % categories.count]
            transaction.date = transactionDate
            transaction.createdAt = transactionDate
            transaction.type = "expense"
            transaction.notes = "Previous month transaction #\(i+1)"
        }
        
        // Save the context
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error creating preview data: \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
    
    // MARK: - Initialization
    
    /// Initialize with standard persistent container
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SimpleBudget")
        
        if inMemory {
            // Use in-memory store for previews and testing
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure for CloudKit if needed
        if !inMemory {
            // Set up for potential CloudKit integration
            if let description = container.persistentStoreDescriptions.first {
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            }
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Handle error appropriately for production code
                fatalError("Unresolved error loading persistent stores: \(error), \(error.userInfo)")
            }
        }
        
        // Enable automatic merging
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Configure merge policy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Core Data Operations
    
    /// Save changes to the persistent store
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Handle error appropriately in production
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    /// Delete all records of a specific entity type
    func deleteAllRecords(of entityName: String) {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(batchDeleteRequest)
            save()
        } catch {
            let nsError = error as NSError
            print("Error deleting all records: \(nsError), \(nsError.userInfo)")
        }
    }
    
    /// Reset the entire store
    func resetStore() {
        // Delete all entities
        deleteAllRecords(of: "Transaction")
        deleteAllRecords(of: "Budget")
        deleteAllRecords(of: "SavingsGoal")
        deleteAllRecords(of: "Account")
        
        // Reset all relevant UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasInitializedAccounts")
        defaults.removeObject(forKey: "selectedTransactionFilter")
        defaults.removeObject(forKey: "lastBudgetUpdate")
        defaults.removeObject(forKey: "selectedTab")
        
        // Create default accounts with zero balance
        let context = container.viewContext
        
        // Create checking account
        let checking = Account(context: context)
        checking.id = UUID()
        checking.name = "My Checking"
        checking.type = "checking"
        checking.balance = 0.0
        checking.icon = "creditcard.fill"
        checking.notes = "Primary checking account"
        
        // Create savings account
        let savings = Account(context: context)
        savings.id = UUID()
        savings.name = "My Savings"
        savings.type = "savings"
        savings.balance = 0.0
        savings.icon = "banknote.fill"
        savings.notes = "Savings account"
        
        // Create investment account
        let investment = Account(context: context)
        investment.id = UUID()
        investment.name = "My Investments"
        investment.type = "investment"
        investment.balance = 0.0
        investment.icon = "chart.line.uptrend.xyaxis"
        investment.notes = "Investment portfolio"
        
        // Save changes
        save()
    }
    
    /// Create a backup of the store
    func createBackup() -> URL? {
        guard let sourceURL = container.persistentStoreDescriptions.first?.url else {
            return nil
        }
        
        let fileManager = FileManager.default
        let backupURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("SimpleBudgetBackup-\(Date().timeIntervalSince1970).sqlite")
        
        do {
            if fileManager.fileExists(atPath: sourceURL.path) {
                try fileManager.copyItem(at: sourceURL, to: backupURL)
                return backupURL
            }
        } catch {
            print("Error creating backup: \(error)")
        }
        
        return nil
    }
    
    /// Restore from a backup
    func restoreFromBackup(at url: URL) -> Bool {
        guard let targetURL = container.persistentStoreDescriptions.first?.url else {
            return false
        }
        
        let fileManager = FileManager.default
        
        do {
            // Remove existing store
            try container.persistentStoreCoordinator.destroyPersistentStore(at: targetURL, type: .sqlite)
            
            // Copy backup to store location
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.copyItem(at: url, to: targetURL)
                
                // Reload stores
                try container.persistentStoreCoordinator.addPersistentStore(type: .sqlite, at: targetURL)
                return true
            }
        } catch {
            print("Error restoring from backup: \(error)")
        }
        
        return false
    }
}
