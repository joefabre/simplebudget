import SwiftUI

public struct AddTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    @State private var amount: String = ""
    @State private var category: String = "Uncategorized"
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var isExpense: Bool = true
    
    // Predefined categories
    private let categories = [
        "Food", "Transportation", "Housing", "Entertainment", 
        "Shopping", "Utilities", "Healthcare", "Education", 
        "Travel", "Personal", "Income", "Uncategorized"
    ]
    
    public var body: some View {
        NavigationStack {
            Form {
                // Transaction type
                Section {
                    Picker("Transaction Type", selection: $isExpense) {
                        Text("Expense").tag(true)
                        Text("Income").tag(false)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Transaction Type")
                }
                
                // Amount
                Section {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Amount")
                }
                
                // Category
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                } header: {
                    Text("Category")
                }
                
                // Date
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                } header: {
                    Text("Date")
                }
                
                // Notes
                Section {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(amount.isEmpty || Double(amount) == 0)
                }
            }
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let transaction = Transaction(context: viewContext)
        transaction.id = UUID()
        transaction.amount = isExpense ? amountValue : -amountValue
        transaction.category = category
        transaction.date = date
        transaction.notes = notes
        transaction.type = isExpense ? "expense" : "income"
        transaction.createdAt = Date()
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            // Handle the error
            print("Error saving transaction: \(error)")
        }
    }
}

#Preview {
    AddTransactionView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

