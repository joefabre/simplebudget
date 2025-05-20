// SimpleBudget/SimpleBudget/Views/SavingsGoalView.swift
import SwiftUI

struct SavingsGoalView: View {
    var goal: SavingsGoal? = nil

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
                // Add form for creating a new goal here
            }
        }
        .padding()
    }
}

#Preview {
    SavingsGoalView()
}
