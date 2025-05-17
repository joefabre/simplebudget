import SwiftUI
import CoreData

struct AccountsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    
    @State private var showingAddAccount = false
    @State private var editingAccount: Account?
    @State private var accountToDelete: Account?
    @State private var showingDeleteConfirmation = false
    @State private var showingRenameSheet = false
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // New account properties
    @State private var accountName = ""
    @State private var accountType = "checking"
    @State private var accountBalance = ""
    @State private var accountIcon = ""
    @State private var accountNotes = ""
    @State private var isDebt = false
    @State private var interestRate = ""
    @State private var dueDate: Date = Date()
    @State private var showDueDate = false
    
    let assetTypes = ["Checking", "Savings", "Investment", "Other"]
    let debtTypes = ["Credit Card", "Loan", "Mortgage", "Other Debt"]
    
    var body: some View {
        NavigationStack {
            List {
                if accounts.isEmpty {
                    ContentUnavailableView("No Accounts", systemImage: "banknote", description: Text("Add your first account to start tracking your finances"))
                } else {
                    ForEach(accounts) { account in
                        accountRow(account)
                            .contextMenu {
                                Button {
                                    prepareRename(account)
                                } label: {
                                    Label("Rename Account", systemImage: "pencil")
                                }
                                
                                Button {
                                    editAccount(account)
                                } label: {
                                    Label("Edit Details", systemImage: "slider.horizontal.3")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    accountToDelete = account
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete Account", systemImage: "trash")
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    accountToDelete = account
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    prepareRename(account)
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
            .navigationTitle("Accounts")
            .sheet(item: $editingAccount) { account in
                EditAccountView(account: account)
                    .environment(\.managedObjectContext, viewContext)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Reset form fields
                        resetFormFields()
                        editingAccount = nil
                        showingAddAccount = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                accountFormSheet
            }
            .sheet(isPresented: $showingRenameSheet) {
                renameAccountSheet
            }
            .confirmationDialog(
                "Delete Account",
                isPresented: $showingDeleteConfirmation,
                presenting: accountToDelete
            ) { account in
                Button("Delete \(account.name ?? "Account")", role: .destructive) {
                    withAnimation {
                        deleteAccount(account)
                        showSuccessMessage("Account deleted successfully")
                    }
                }
                Button("Cancel", role: .cancel) {
                    accountToDelete = nil
                }
            } message: { account in
                Text("Are you sure you want to delete \(account.name ?? "this account")? This action cannot be undone.")
            }
            .overlay(
                successToast
                    .opacity(showingSuccess ? 1 : 0)
            )
            .alert(errorMessage, isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    // Account row in the list
    private func accountRow(_ account: Account) -> some View {
        HStack(spacing: 16) {
            // Account icon
            Image(systemName: account.icon ?? accountTypeIcon(account.type ?? "other"))
                .font(.system(size: 24))
                .foregroundColor(accountTypeColor(account.type ?? "other", account.isDebt))
                .frame(width: 44, height: 44)
                .background(accountTypeColor(account.type ?? "other", account.isDebt).opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name ?? "Account")
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(account.type ?? "Account")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if account.isDebt {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Debt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            
            Spacer()
            
            // Account balance with debt formatting
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(account.isDebt ? -account.balance : account.balance))
                    .font(.headline)
                    .foregroundColor(account.isDebt ? .red : accountTypeColor(account.type ?? "other", account.isDebt))
                
                if account.isDebt && account.interestRate > 0 {
                    Text("\(String(format: "%.2f", account.interestRate))% APR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // Form for adding or editing an account
    private var accountFormSheet: some View {
        NavigationStack {
            Form {
                Section("Account Information") {
                    TextField("Account Name", text: $accountName)
                        .autocapitalization(.words)
                    
                    // Account type selector
                    Toggle("Debt Account", isOn: $isDebt)
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                    
                    Picker("Account Type", selection: $accountType) {
                        if isDebt {
                            ForEach(debtTypes, id: \.self) { type in
                                Text(type)
                                    .tag(type.lowercased().replacingOccurrences(of: " ", with: ""))
                            }
                        } else {
                            ForEach(assetTypes, id: \.self) { type in
                                Text(type)
                                    .tag(type.lowercased())
                            }
                        }
                    }
                    
                    HStack {
                        Text("$")
                        TextField("Balance", text: $accountBalance)
                            .keyboardType(.decimalPad)
                    }
                    
                    if isDebt {
                        HStack {
                            Text("Interest Rate")
                            Spacer()
                            TextField("0.0", text: $interestRate)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("%")
                        }
                        
                        Toggle("Payment Due Date", isOn: $showDueDate)
                        
                        if showDueDate {
                            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        }
                    }
                }
                
                Section("Additional Details") {
                    HStack {
                        Text("Icon")
                        
                        Spacer()
                        
                        if !accountIcon.isEmpty {
                            Image(systemName: accountIcon)
                                .foregroundColor(accountTypeColor(accountType, isDebt))
                        } else {
                            Image(systemName: accountTypeIcon(accountType))
                                .foregroundColor(accountTypeColor(accountType, isDebt))
                        }
                    }
                    
                    TextField("Notes", text: $accountNotes)
                }
                
                Section {
                    Button(editingAccount == nil ? "Add Account" : "Save Changes") {
                        saveAccount()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle(editingAccount == nil ? "New Account" : "Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddAccount = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func saveAccount() {
        let context = viewContext
        
        // Get the balance as a Double
        let balance = Double(accountBalance.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        
        // Get interest rate if provided
        let rate = Double(interestRate.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        
        if let account = editingAccount {
            // Update existing account
            account.name = accountName
            account.type = accountType
            account.balance = balance
            account.icon = accountIcon.isEmpty ? nil : accountIcon
            account.notes = accountNotes.isEmpty ? nil : accountNotes
            account.isDebt = isDebt
            account.interestRate = rate
            
            if showDueDate {
                account.dueDate = dueDate
            } else {
                account.dueDate = nil
            }
        } else {
            // Check if account with same name already exists
            if accountExists(withName: accountName) {
                showErrorAlert(message: "An account with this name already exists")
                return
            }
            
            // Create new account
            let newAccount = Account(context: context)
            newAccount.id = UUID()
            newAccount.name = accountName
            newAccount.type = accountType
            newAccount.balance = balance
            newAccount.icon = accountIcon.isEmpty ? nil : accountIcon
            newAccount.notes = accountNotes.isEmpty ? nil : accountNotes
            newAccount.isDebt = isDebt
            newAccount.interestRate = rate
            
            if showDueDate {
                newAccount.dueDate = dueDate
            }
        }
        
        // Save changes
        do {
            try context.save()
            showingAddAccount = false
        } catch {
            print("Error saving account: \(error)")
        }
    }
    
    // Check if an account with the given name already exists
    private func accountExists(withName name: String) -> Bool {
        let fetchRequest: NSFetchRequest<Account> = Account.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@", name)
        
        do {
            let matchingAccounts = try viewContext.fetch(fetchRequest)
            return !matchingAccounts.isEmpty
        } catch {
            print("Error checking for existing account: \(error)")
            return false
        }
    }
    
    private func deleteAccount(_ account: Account) {
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Delete the account
        viewContext.delete(account)
        
        do {
            try viewContext.save()
            accountToDelete = nil
        } catch {
            print("Error deleting account: \(error)")
        }
    }
    
    private func editAccount(_ account: Account) {
        // Set the account being edited to show the EditAccountView
        editingAccount = account
    }
    
    private func resetFormFields() {
        accountName = ""
        accountType = "checking"
        accountBalance = ""
        accountIcon = ""
        accountNotes = ""
        isDebt = false
        interestRate = ""
        showDueDate = false
        dueDate = Date()
    }
    
    private func accountTypeIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "checking":
            return "creditcard.fill"
        case "savings":
            return "banknote.fill"
        case "investment":
            return "chart.line.uptrend.xyaxis"
        case "creditcard":
            return "creditcard.fill"
        case "loan":
            return "dollarsign.arrow.circlepath"
        case "mortgage":
            return "house.fill"
        case "otherdebt":
            return "exclamationmark.triangle.fill"
        default:
            return "dollarsign.circle.fill"
        }
    }
    
    private func accountTypeColor(_ type: String, _ isDebt: Bool = false) -> Color {
        if isDebt {
            switch type.lowercased() {
            case "creditcard":
                return .red
            case "loan":
                return .orange
            case "mortgage":
                return .pink
            case "otherdebt":
                return .purple
            default:
                return .red
            }
        } else {
            switch type.lowercased() {
            case "checking":
                return .blue
            case "savings":
                return .green
            case "investment":
                return .purple
            default:
                return .gray
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // This could come from user settings
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    private func formatBalance(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0.00"
    }
    
    // MARK: - Rename Account
    
    private func prepareRename(_ account: Account) {
        editingAccount = account
        accountName = account.name ?? ""
        showingRenameSheet = true
    }
    
    private var renameAccountSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Account Name")
                        .font(.headline)
                    
                    TextField("Enter account name", text: $accountName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                }
                .padding(.horizontal)
                
                Button {
                    if let account = editingAccount {
                        saveAccountRename(account)
                    }
                } label: {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(accountName.isEmpty || (editingAccount?.name != accountName && accountExists(withName: accountName)))
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Rename Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingRenameSheet = false
                    }
                }
            }
        }
    }
    
    private func saveAccountRename(_ account: Account) {
        // Check if another account with the same name exists
        if account.name != accountName && accountExists(withName: accountName) {
            showErrorAlert(message: "An account with this name already exists")
            return
        }
        
        // Update account name
        account.name = accountName
        
        // Save changes
        do {
            try viewContext.save()
            showingRenameSheet = false
            showSuccessMessage("Account renamed successfully")
            
            // Provide haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Error renaming account: \(error)")
        }
    }
    
    // MARK: - Success Message
    
    private var successToast: some View {
        Text(successMessage)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding(.top, 20)
    }
    
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showingSuccess = true
        
        // Hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingSuccess = false
            }
        }
    }
    
    // Show error alert
    private func showErrorAlert(message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
}

#Preview {
    AccountsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
