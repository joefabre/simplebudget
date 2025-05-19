import SwiftUI
import CoreData

public struct AddBudgetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // Store the budget being edited, if any
    private let existingBudget: Budget?
    
    // Default initializer for creating a new budget
    public init() {
        self.existingBudget = nil
    }
    
    // Initializer for editing an existing budget
    public init(budget: Budget) {
        self.existingBudget = budget
        _amount = State(initialValue: String(format: "%.2f", budget.amount))
        _month = State(initialValue: AddBudgetView.dateFromBudget(budget))
        _notes = State(initialValue: budget.notes ?? "")
        _incomeSources = State(initialValue: budget.incomeSources)
    }
    
    // Helper function to convert budget month/year to Date
    private static func dateFromBudget(_ budget: Budget) -> Date {
        let calendar = Calendar.current
        let monthInt = Int(budget.month ?? "01") ?? 1
        let yearInt = Int(budget.year)
        if let date = calendar.date(from: DateComponents(year: yearInt, month: monthInt, day: 1)) {
            return date
        } else {
            return Date()
        }
    }
    
    @State private var amount: String = ""
    @State private var month: Date = Date()
    @State private var notes: String = ""
    @State private var incomeSources: [Budget.IncomeSource] = []
    @State private var showAddIncomeSheet = false
    @State private var newIncomeName = ""
    @State private var newIncomeAmount = ""
    @State private var newIncomeFrequency = Budget.IncomeSource.IncomeFrequency.monthly
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    
    public var body: some View {
        NavigationStack {
            Form {
                // Income sources
                Section {
                    ForEach(incomeSources) { incomeSource in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(incomeSource.name)
                                    .font(.headline)
                                Text(incomeSource.frequency.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("$\(String(format: "%.2f", incomeSource.amount))")
                                Text("$\(String(format: "%.2f", incomeSource.monthlyValue)) /mo")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteIncomeSource)
                    
                    Button(action: {
                        showAddIncomeSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Income Source")
                        }
                    }
                    
                    if !incomeSources.isEmpty {
                        HStack {
                            Text("Total Monthly Income:")
                                .font(.headline)
                            Spacer()
                            Text("$\(String(format: "%.2f", totalMonthlyIncome))")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding(.top, 10)
                    }
                } header: {
                    Text("Income Sources")
                } footer: {
                    Text("Add all sources of income to calculate your total budget.")
                }
                
                // Budget amount
                Section {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    if !incomeSources.isEmpty {
                        HStack {
                            Text("Remaining:")
                            Spacer()
                            Text("$\(String(format: "%.2f", remainingBudget))")
                                .foregroundColor(remainingBudget >= 0 ? .green : .red)
                        }
                    }
                } header: {
                    Text("Monthly Expense Budget")
                } footer: {
                    Text(incomeSources.isEmpty ? 
                         "Enter the total amount you want to budget for expenses this month." :
                         "Your expense budget should not exceed your total income.")
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
            .navigationTitle(existingBudget != nil ? "Edit Budget" : "Set Monthly Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if validateBudget() {
                            saveBudget()
                        }
                    }
                    .disabled(amount.isEmpty)
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
        .sheet(isPresented: $showAddIncomeSheet) {
            NavigationStack {
                Form {
                    Section {
                        TextField("Income Source Name", text: $newIncomeName)
                    } header: {
                        Text("Income Source")
                    }
                    
                    Section {
                        HStack {
                            Text("$")
                            TextField("0.00", text: $newIncomeAmount)
                                .keyboardType(.decimalPad)
                        }
                    } header: {
                        Text("Amount")
                    }
                    
                    Section {
                        Picker("Frequency", selection: $newIncomeFrequency) {
                            ForEach(Budget.IncomeSource.IncomeFrequency.allCases) { frequency in
                                Text(frequency.rawValue).tag(frequency)
                            }
                        }
                    } header: {
                        Text("Payment Frequency")
                    }
                }
                .navigationTitle("Add Income Source")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            resetNewIncomeForm()
                            showAddIncomeSheet = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addIncomeSource()
                        }
                        .disabled(newIncomeName.isEmpty || newIncomeAmount.isEmpty || Double(newIncomeAmount) == nil)
                    }
                }
            }
        }
        .alert(validationMessage, isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    // Calculate total monthly income from all sources
    private var totalMonthlyIncome: Double {
        incomeSources.reduce(0) { $0 + $1.monthlyValue }
    }
    
    // Calculate remaining budget
    private var remainingBudget: Double {
        let expenseBudget = Double(amount) ?? 0
        return totalMonthlyIncome - expenseBudget
    }
    
    // Add a new income source
    private func addIncomeSource() {
        guard let amountValue = Double(newIncomeAmount) else { return }
        
        let newSource = Budget.IncomeSource(
            name: newIncomeName,
            amount: amountValue,
            frequency: newIncomeFrequency
        )
        
        incomeSources.append(newSource)
        resetNewIncomeForm()
        showAddIncomeSheet = false
    }
    
    // Reset new income form
    private func resetNewIncomeForm() {
        newIncomeName = ""
        newIncomeAmount = ""
        newIncomeFrequency = .monthly
    }
    
    // Delete income source
    private func deleteIncomeSource(at offsets: IndexSet) {
        incomeSources.remove(atOffsets: offsets)
    }
    
    // Validate budget amount
    private func validateBudget() -> Bool {
        // Always valid if there's no income sources
        if incomeSources.isEmpty {
            return true
        }
        
        guard let budgetAmount = Double(amount) else { return false }
        
        // Check if budget exceeds income
        if budgetAmount > totalMonthlyIncome {
            validationMessage = "Your expense budget exceeds your total income. Please adjust your budget or add more income sources."
            showValidationAlert = true
            return false
        }
        
        return true
    }
    
    private func saveBudget() {
        guard let amountValue = Double(amount) else { return }
        
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self.month)
        let year = calendar.component(.year, from: self.month)
        
        // We'll use the Budget extension to handle serialization of income sources
        
        // Prepare notes with income information
        var updatedNotes = notes
        if !incomeSources.isEmpty {
            updatedNotes += "\n\nTotal Monthly Income: $\(String(format: "%.2f", totalMonthlyIncome))"
            for source in incomeSources {
                updatedNotes += "\n- \(source.name): $\(String(format: "%.2f", source.amount)) (\(source.frequency.rawValue))"
            }
        }
        
        // If we're editing an existing budget, update it directly
        if let budgetToEdit = existingBudget {
            // Update the budget being edited
            budgetToEdit.amount = amountValue
            budgetToEdit.month = String(format: "%02d", month)
            budgetToEdit.year = Int16(year)
            budgetToEdit.notes = updatedNotes
            budgetToEdit.incomeSources = incomeSources
            
            try? viewContext.save()
            dismiss()
            return
        }
        
        // Check if budget already exists for this month
        let fetchRequest = Budget.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "month == %@ AND year == %d", String(format: "%02d", month), year)
        
        do {
            let existingBudgets = try viewContext.fetch(fetchRequest)
            
            if let existingBudget = existingBudgets.first {
                // Update existing budget
                existingBudget.amount = amountValue
                existingBudget.notes = updatedNotes
                
                // Store income sources using the extension
                existingBudget.incomeSources = incomeSources
            } else {
                // Create new budget
                let newBudget = Budget(context: viewContext)
                newBudget.id = UUID()
                newBudget.amount = amountValue
                newBudget.month = String(format: "%02d", month)
                newBudget.year = Int16(year)
                newBudget.notes = updatedNotes
                
                // Store income sources using the extension
                newBudget.incomeSources = incomeSources
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

