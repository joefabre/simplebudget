// SavingsGoal+Extensions.swift

import Foundation
import CoreData

extension SavingsGoal {
    // MARK: - Helper Computed Properties

    var isComplete: Bool {
        return currentAmount >= targetAmount
    }

    var progressRatio: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    var progressPercentage: Double {
        return progressRatio * 100
    }

    var remainingAmount: Double {
        return max(0, targetAmount - currentAmount)
    }

    var daysRemaining: Int? {
        guard let deadline = deadline else { return nil }
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.day], from: today, to: deadline)
        return components.day
    }

    var isPastDeadline: Bool {
        guard let days = daysRemaining else { return false }
        return days < 0
    }

    func formattedDeadline() -> String? {
        guard let deadline = deadline else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: deadline)
    }

    var requiredMonthlyContribution: Double? {
        guard let deadline = deadline, !isComplete, deadline > Date() else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: Date(), to: deadline)
        guard let months = components.month, months > 0 else { return nil }
        return remainingAmount / Double(months)
    }

    var formattedProgress: String {
        return String(format: "%.1f%%", progressPercentage)
    }

    var formattedRemaining: String {
        return String(format: "$%.2f", remainingAmount)
    }
}
