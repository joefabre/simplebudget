import SwiftUI
import UIKit

public struct SettingsView: View {
    // Environment
    @Environment(\.managedObjectContext) private var viewContext
    
    // App Settings
    @AppStorage("currencyCode") private var currencyCode: String = "USD"
    @AppStorage("startDayOfMonth") private var startDayOfMonth: Int = 1
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled: Bool = false
    @AppStorage("useBiometricAuth") private var useBiometricAuth: Bool = false
    
    // UI State
    private let currencyOptions = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD"]
    @State private var showingExportSheet = false
    @State private var managingCategories = false
    @State private var appVersion = "1.0.0"
    @State private var showingResetConfirmation = false
    @State private var showingResetSuccess = false
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(UIColor.systemGray5)
                    .ignoresSafeArea()
                
                Form {
                // Currency settings
                Section(header: Text("Currency")) {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencyOptions, id: \.self) { code in
                            Text(currencyName(for: code))
                                .tag(code)
                        }
                    }
                }
                
                // Budget settings
                Section(header: Text("Budget")) {
                    Stepper(value: $startDayOfMonth, in: 1...28) {
                        HStack {
                            Text("Budget start day")
                            Spacer()
                            Text("\(startDayOfMonth)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink("Manage Categories") {
                        Text("Category management would go here")
                    }
                }
                
                // App settings
                Section(header: Text("App Settings")) {
                    Toggle("Dark Mode", isOn: $isDarkModeEnabled)
                    
                    Toggle("Use Face ID/Touch ID", isOn: $useBiometricAuth)
                }
                
                // Data management
                Section(header: Text("Data Management")) {
                    Button("Export Data") {
                        showingExportSheet = true
                    }
                    
                    Button {
                        showingResetConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Reset All Data")
                        }
                    }
                    .foregroundColor(.red)
                }
                
                // About
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .scrollContentBackground(.hidden)  // Hide default Form background
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset All Data",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your data including transactions, budgets, and accounts. This action cannot be undone.")
            }
            .overlay {
                if showingResetSuccess {
                    successToast
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut, value: showingResetSuccess)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showingResetSuccess = false
                                }
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var successToast: some View {
        VStack {
            Spacer()
            Text("All data has been reset")
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.bottom, 20)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Reset all data in the app including Core Data and relevant UserDefaults
    private func resetAllData() {
        // Reset Core Data
        PersistenceController.shared.resetStore()
        
        // Reset UserDefaults that should be reset (preserving basic settings)
        UserDefaults.standard.removeObject(forKey: "hasInitializedAccounts")
        UserDefaults.standard.removeObject(forKey: "selectedTransactionFilter")
        UserDefaults.standard.removeObject(forKey: "lastBudgetUpdate")
        
        // Reset selected tab to Dashboard
        UserDefaults.standard.set(0, forKey: "selectedTab")
        
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show success message
        withAnimation(.spring()) {
            showingResetSuccess = true
        }
        
        // Schedule re-initialization of default accounts (without direct app delegate reference)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Create initial accounts
            let context = PersistenceController.shared.container.viewContext
            
            // Define default accounts
            let savingsAccount = Account(context: context)
            savingsAccount.id = UUID()
            savingsAccount.name = "My Savings"
            savingsAccount.type = "savings"
            savingsAccount.balance = 0.0
            savingsAccount.icon = "banknote.fill"
            
            // Create investment account
            let investmentAccount = Account(context: context)
            investmentAccount.id = UUID()
            investmentAccount.name = "My Investments"
            investmentAccount.type = "investment"
            investmentAccount.balance = 0.0
            investmentAccount.icon = "chart.line.uptrend.xyaxis"
            
            // Save the context
            do {
                try context.save()
                print("Default accounts created after reset")
            } catch {
                print("Error creating default accounts after reset: \(error.localizedDescription)")
            }
        }
    }
    
    private func currencyName(for code: String) -> String {
        let locale = Locale(identifier: "en_US")
        if let currencyName = locale.localizedString(forCurrencyCode: code) {
            return "\(code) - \(currencyName)"
        } else {
            return code
        }
    }
}

#Preview {
    SettingsView()
}
