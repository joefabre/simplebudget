// SimpleBudget/SimpleBudget/Views/SavingsGoalView.swift
import SwiftUI

struct SavingsGoalView: View {
    // For editing mode
    let goal: SavingsGoal?
    @Environment(\.managedObjectContext) private var viewContext
    @State private var name: String = ""
    @State private var targetAmount: String = ""
    @State private var currentAmount: String = ""
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @Environment(\.dismiss) var dismiss
    
    init(goal: SavingsGoal? = nil) {
        self.goal = goal
    }

    var body: some View {
        VStack(spacing: 20) {
            if let goal = goal {
                Text(goal.name ?? "Savings Goal")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    // Target Amount Display
                    HStack {
                        Text("Target Amount:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "$%.2f", (goal.targetAmount as? Decimal).map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0))
                            .fontWeight(.semibold)
                    }
                    
                    // Current Amount Input
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Current Amount")
                            .foregroundColor(.secondary)
                        TextField("Current Amount", text: $currentAmount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: currentAmount) { newValue in
                                validateCurrentAmount(newValue)
                            }
                            .submitLabel(.done)
                    }
                    
                    if showingError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Progress View
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Progress")
                            .foregroundColor(.secondary)
                        ProgressView(value: {
                            let targetDouble = (goal.targetAmount as? Decimal).map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0
                            return targetDouble > 0 ? goal.currentAmount / targetDouble : 0
                        }())
                            .tint({
                                let targetDouble = (goal.targetAmount as? Decimal).map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0
                                return goal.currentAmount >= targetDouble ? .green : .blue
                            }())
                        HStack {
                            Text(String(format: "$%.2f / $%.2f", goal.currentAmount,
                                      (goal.targetAmount as? Decimal).map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0))
                                .font(.caption)
                            Spacer()
                            Text(String(format: "$%.2f remaining", {
                                let targetDouble = (goal.targetAmount as? Decimal).map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0
                                return max(0, targetDouble - goal.currentAmount)
                            }()))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Update Button
                    Button(action: updateCurrentAmount) {
                        Text("Update Amount")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(showingError || currentAmount.isEmpty)
                }
                .padding()
            } else {
                Text("New Savings Goal")
                    .font(.title)
                    .fontWeight(.bold)

                TextField("Goal Name", text: $name)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                TextField("Target Amount", text: $targetAmount)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                Button("Save") {
                    guard !name.isEmpty else {
                        showingError = true
                        errorMessage = "Please enter a goal name"
                        return
                    }
                    
                    guard let targetDecimal = Decimal(string: targetAmount),
                          targetDecimal > 0 else {
                        showingError = true
                        errorMessage = "Please enter a valid target amount"
                        return
                    }
                    
                    do {
                        let newGoal = SavingsGoal(context: viewContext)
                        // Set required properties in order, ID first
                        newGoal.id = UUID()
                        newGoal.name = name
                        newGoal.targetAmount = NSDecimalNumber(decimal: targetDecimal)
                        newGoal.currentAmount = 0.0 // Double type
                        newGoal.createdAt = Date()
                        
                        // Save the context
                        try viewContext.save()
                        dismiss()
                    } catch {
                        showingError = true
                        errorMessage = "Failed to save goal: \(error.localizedDescription)"
                    }
                }
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            if let goal = goal {
                // Load the current amount
                currentAmount = String(format: "%.2f", goal.currentAmount)
            }
        }
        .onDisappear {
            // Refresh parent view when this view disappears
            NotificationCenter.default.post(name: NSNotification.Name("RefreshSavingsGoals"), object: nil)
        }
        // .alert(isPresented: $showingAlert) {
        //     Alert(title: Text("Goal Saved"), message: Text("Your savings goal has been saved."), dismissButton: .default(Text("OK")))
        // }
    }
    
    private func validateCurrentAmount(_ amount: String) {
        // Clear previous error
        showingError = false
        errorMessage = ""
        
        // Check if amount is a valid decimal
        guard let currentValue = Double(amount) else {
            showingError = true
            errorMessage = "Please enter a valid amount"
            return
        }
        
        // Check if amount is positive
        guard currentValue >= 0 else {
            showingError = true
            errorMessage = "Amount must be positive"
            return
        }
        
        // Check if amount exceeds target (if editing existing goal)
        if let goal = goal {
            // Convert target amount to Double for comparison
            if let targetDecimal = goal.targetAmount as? Decimal {
                let targetDouble = NSDecimalNumber(decimal: targetDecimal).doubleValue
                if currentValue > targetDouble {
                    showingError = true
                    errorMessage = "Amount cannot exceed target"
                }
            }
        }
    }
    
    private func updateCurrentAmount() {
        // Basic input validation
        guard let amount = Double(currentAmount) else {
            showingError = true
            errorMessage = "Please enter a valid amount"
            return
        }
        
        guard let goalToUpdate = goal else {
            showingError = true
            errorMessage = "No goal to update"
            return
        }
        
        // Validate against target amount
        guard let targetDecimal = goalToUpdate.targetAmount as? Decimal else {
            showingError = true
            errorMessage = "Invalid target amount"
            return
        }
        
        let targetDouble = NSDecimalNumber(decimal: targetDecimal).doubleValue
        guard amount <= targetDouble else {
            showingError = true
            errorMessage = "Amount cannot exceed target of $\(String(format: "%.2f", targetDouble))"
            return
        }
        
        do {
            // Update the amount
            goalToUpdate.currentAmount = amount
            
            // Save the context
            try viewContext.save()
            
            // Dismiss the view
            dismiss()
        } catch {
            showingError = true
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SavingsGoalView()
}
