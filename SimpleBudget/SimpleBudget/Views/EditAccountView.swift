import SwiftUI

struct EditAccountView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let account: Account
    
    @State private var name: String
    @State private var type: String
    @State private var balance: String
    @State private var icon: String
    @State private var notes: String
    @State private var showingDeleteConfirmation = false
    @State private var showingSuccessToast = false
    
    private let assetTypes = ["Checking", "Savings", "Investment", "Other"]
    
    init(account: Account) {
        self.account = account
        _name = State(initialValue: account.name ?? "")
        _type = State(initialValue: account.type ?? "checking")
        _balance = State(initialValue: String(format: "%.2f", account.balance))
        _icon = State(initialValue: account.icon ?? "")
        _notes = State(initialValue: account.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Account Information
                Section("Account Information") {
                    TextField("Account Name", text: $name)
                    
                    Picker("Account Type", selection: $type) {
                        ForEach(assetTypes, id: \.self) { type in
                            Text(type)
                                .tag(type.lowercased())
                        }
                    }
                    
                    HStack {
                        Text("$")
                        TextField("Balance", text: $balance)
                            .keyboardType(.decimalPad)
                    }
                }
                
                // Additional Details
                Section("Additional Details") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                
                // Delete Account
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Account")
                        }
                    }
                }
            }
            .navigationTitle("Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty || balance.isEmpty)
                }
            }
            .overlay {
                if showingSuccessToast {
                    successToast
                }
            }
            .confirmationDialog(
                "Delete Account",
                isPresented: $showingDeleteConfirmation
            ) {
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this account? This action cannot be undone.")
            }
        }
    }
    
    private func saveChanges() {
        guard let balanceValue = Double(balance) else { return }
        
        account.name = name
        account.type = type
        account.balance = balanceValue
        account.icon = icon
        account.notes = notes
        
        do {
            try viewContext.save()
            
            // Show success message
            withAnimation {
                showingSuccessToast = true
            }
            
            // Dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            print("Error saving account: \(error)")
        }
    }
    
    private func deleteAccount() {
        viewContext.delete(account)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting account: \(error)")
        }
    }
    
    private var successToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Account updated")
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(20)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    let previewContext = PersistenceController.preview.container.viewContext
    let account = Account(context: previewContext)
    account.id = UUID()
    account.name = "Preview Account"
    account.type = "savings"
    account.balance = 1000.0
    
    return EditAccountView(account: account)
        .environment(\.managedObjectContext, previewContext)
}

