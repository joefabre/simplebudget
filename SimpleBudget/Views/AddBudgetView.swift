import SwiftUI

public struct AddBudgetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    @State private var amount: String = ""
    @State private var month: Date = Date()
    @State private var notes: String = ""
    
    public var body: some View {
        NavigationStack {
            Form {
                // Budget amount
                Section {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Monthly Budget Amount")
                } footer: {
                    Text("Enter the total amount you want to budget for the month.")
                }
                
                // Month selection
                Section {
                    DatePicker("Month", selection: $month, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .onChange(of: month) { newValue in
                            // Reset to first day of selected month
                            let calendar = Calendar.current
                            if let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: newValue)) {
                                month = firstDay
                            }
                        }
                } header: {
                    Text("Budget Month")
                } footer: {
                    Text("This budget will apply to the entire month.")
                }
                
                // Notes
                Section {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("Set Monthly Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBudget()
                    }
                    .disabled(amount.isEmpty || Double(amount) == 0)
                }
            }
            .onAppear {
                // Ensure we're on the first day of the month
                let calendar = Calendar.current
                if let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) {
                    month = firstDay
                }
            }
        }
    }
    
    private func saveBudget() {
        guard let amountValue = Double(amount) else { return }
        
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self.month)
        let year = calendar.component(.year, from: self.month)
        
        // Check if budget already exists for this month
        let fetchRequest = Budget.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "month == %@ AND year == %d", String(format: "%02d", month), year)
        
        do {
            let existingBudgets = try viewContext.fetch(fetchRequest)
            
            if let existingBudget = existingBudgets.first {
                // Update existing budget
                existingBudget.amount = amountValue
                existingBudget.notes = notes
            } else {
                // Create new budget
                let newBudget = Budget(context: viewContext)
                newBudget.id = UUID()
                newBudget.amount = amountValue
                newBudget.month = String(format: "%02d", month)
                newBudget.year = Int16(year)
                newBudget.notes = notes
            }
            
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving budget: \(error)")
            // Could show an alert here
        }
    }
}

#Preview {
    AddBudgetView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

