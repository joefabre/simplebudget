
// SavingsGoal+Extensions.swift

import Foundation
import CoreData

extension SavingsGoal {
    // MARK: - Helper Computed Properties

    var isComplete: Bool {
        guard let currentAmount = currentAmount as? NSDecimalNumber,
              let targetAmount = targetAmount as? NSDecimalNumber else { return false }
        return currentAmount.doubleValue >= targetAmount.doubleValue
    }

    var progressRatio: Double {
        guard let targetAmount = targetAmount as? NSDecimalNumber,
              let currentAmount = currentAmount as? NSDecimalNumber,
              targetAmount.doubleValue != 0 else { return 0 }
        let ratio = currentAmount.doubleValue / targetAmount.doubleValue
        return min(ratio, 1.0)
    }

    var progressPercentage: Double {
        return progressRatio * 100
    }

    var remainingAmount: Double {
        guard let targetAmount = targetAmount as? NSDecimalNumber,
              let currentAmount = currentAmount as? NSDecimalNumber else { return 0 }
        return max(0, targetAmount.doubleValue - currentAmount.doubleValue)
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
        guard let deadline = deadline,
              !isComplete,
              deadline > Date(),
              let targetAmount = targetAmount as? NSDecimalNumber,
              let currentAmount = currentAmount as? NSDecimalNumber else { return nil }
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.month], from: today, to: deadline)
        guard let months = components.month, months > 0 else { return nil }
        let remainingAmount = targetAmount.doubleValue - currentAmount.doubleValue
        return remainingAmount / Double(months)
    }

    var formattedProgress: String {
        return String(format: "%.1f%%", progressPercentage)
    }

    var formattedRemaining: String {
        return String(format: "$%.2f", remainingAmount)
    }
}
