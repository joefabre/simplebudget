import SwiftUI
import CoreData

@main
struct SimpleBudgetApp: App {
    // Create persistence controller
    let persistenceController = PersistenceController.shared
    
    // Scene phase monitoring
    @Environment(\.scenePhase) private var scenePhase
    
    // State to track if splash screen is showing
    @State private var showSplash = true
    
    init() {
        // Check if accounts need to be created
        let context = persistenceController.container.viewContext
        if !accountsExist(in: context) {
            // No accounts exist, create them
            if UserDefaults.standard.object(forKey: "hasInitializedAccounts") == nil {
                print("First launch detected - creating initial accounts")
            } else {
                print("No accounts found - creating initial accounts")
            }
            
            createSpecificAccounts()
            UserDefaults.standard.set(true, forKey: "hasInitializedAccounts")
        } else {
            print("Accounts already exist - skipping initial account creation")
        }
    }
    
    // Check if any accounts already exist in the database
    private func accountsExist(in context: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        fetchRequest.fetchLimit = 1 // We only need to know if at least one exists
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking for existing accounts: \(error)")
            return false
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                        .onAppear {
                            // Dismiss splash screen after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(.easeOut(duration: 0.7)) {
                                    showSplash = false
                                }
                            }
                        }
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive {
                persistenceController.save()
            }
        }
    }
    
    // Function to reset data for a fresh start (for use with debug options or user-initiated reset)
    private func resetDataForFreshStart() {
        // This function is now kept for potential future use, but not called automatically on app launch
        print("Resetting data for fresh start")
        
        // Reset all data
        persistenceController.resetStore()
        
        // Create specific accounts
        createSpecificAccounts()
        
        // Reset first launch flag to ensure accounts get created after reset
        UserDefaults.standard.set(true, forKey: "hasInitializedAccounts")
        
        // NOTE: For production use, you might want to implement:
        // 1. A first-launch-only reset using UserDefaults (now implemented)
        // 2. Sample data creation
        // 3. Data migration between app versions
    }
    
    // Optional function for clearing first launch flag (useful for testing)
    private func resetFirstLaunchFlag() {
        UserDefaults.standard.removeObject(forKey: "hasInitializedAccounts")
        print("First launch flag reset - next launch will create initial accounts")
    }
    
    // Create specific accounts as requested
    private func createSpecificAccounts() {
        let context = persistenceController.container.viewContext
        
        // Define accounts to create
        let accountsToCreate = [
            (name: "My Savings", type: "savings", icon: "banknote.fill"),
            (name: "My Investments", type: "investment", icon: "chart.line.uptrend.xyaxis")
        ]
        
        var createdCount = 0
        
        for accountInfo in accountsToCreate {
            // Check if this account already exists
            if !accountExists(withName: accountInfo.name, in: context) {
                // Create new account
                let newAccount = Account(context: context)
                newAccount.id = UUID()
                newAccount.name = accountInfo.name
                newAccount.type = accountInfo.type
                newAccount.balance = 0.0  // User will enter actual balance
                newAccount.icon = accountInfo.icon
                createdCount += 1
                print("Created account: \(accountInfo.name)")
            } else {
                print("Account already exists: \(accountInfo.name) - skipping creation")
            }
        }
        
        // Save the changes if any accounts were created
        if createdCount > 0 {
            do {
                try context.save()
                print("Successfully created \(createdCount) accounts")
            } catch {
                print("Error saving accounts: \(error.localizedDescription)")
                
                // Additional error information for debugging
                if let nsError = error as NSError? {
                    print("Error domain: \(nsError.domain), code: \(nsError.code)")
                    print("Error details: \(nsError.userInfo)")
                }
            }
        } else {
            print("No new accounts needed to be created")
        }
    }
    
    // Check if an account with the given name already exists
    private func accountExists(withName name: String, in context: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@", name)
        fetchRequest.fetchLimit = 1
        
        do {
            let matchingAccounts = try context.fetch(fetchRequest)
            return !matchingAccounts.isEmpty
        } catch {
            print("Error checking for existing account '\(name)': \(error)")
            return false
        }
    }
}

