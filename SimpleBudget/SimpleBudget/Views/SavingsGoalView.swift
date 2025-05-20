// SimpleBudget/SimpleBudget/Views/SavingsGoalView.swift
import SwiftUI

struct SavingsGoalView: View {
    var goal: SavingsGoal? = nil
    @Environment(\.managedObjectContext) private var viewContext
    @State private var name: String = ""
    @State private var targetAmount: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            if let goal = goal {
                Text(goal.name ?? "Savings Goal")
                    .font(.title)
                    .fontWeight(.bold)
                // Add more details/edit UI for the goal here
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
                    let newGoal = SavingsGoal(context: viewContext)
                    newGoal.name = name
                    if let amount = Decimal(string: targetAmount) {
                        newGoal.targetAmount = amount as NSDecimalNumber
                    }
                  
                    newGoal.createdAt = Date()

                    // Save to CoreData in background
                    Task { @MainActor in
                        do {
                            try await viewContext.perform {
                                try viewContext.save()
                            }
                         
                        } catch {
                            print("Error saving goal: \(error)")
                        }
                     dismiss()
                    }
                }
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        // Remove alert
        // .alert(isPresented: $showingAlert) {
        //     Alert(title: Text("Goal Saved"), message: Text("Your savings goal has been saved."), dismissButton: .default(Text("OK")))
        // }
    }
}

#Preview {
    SavingsGoalView()
}
