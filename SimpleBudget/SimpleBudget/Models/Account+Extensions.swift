import Foundation
import CoreData

// Extension to the auto-generated Account entity
extension Account {
    // MARK: - Helper Computed Properties and Methods
    
    // Calculate monthly interest amount
    var monthlyInterestAmount: Double {
        guard isDebt && interestRate > 0 else { return 0.0 }
        
        // Simple monthly interest calculation
        let monthlyRate = interestRate / 100.0 / 12.0
        return balance * monthlyRate
    }
    
    // Calculate number of days until payment is due
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        
        let calendar = Calendar.current
        let today = Date()
        
        let components = calendar.dateComponents([.day], from: today, to: dueDate)
        return components.day
    }
    
    // Check if payment is past due
    var isPastDue: Bool {
        guard let daysRemaining = daysUntilDue else { return false }
        return daysRemaining < 0
    }
    
    // Format due date as string
    func formattedDueDate() -> String? {
        guard let dueDate = dueDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }
    
    // Update due date to next month
    func updateDueDateToNextMonth() {
        guard let currentDueDate = dueDate else { return }
        
        let calendar = Calendar.current
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDueDate) {
            dueDate = nextMonth
        }
    }
}

