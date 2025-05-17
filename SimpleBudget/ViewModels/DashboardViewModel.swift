import Foundation
import CoreData
import SwiftUI

class DashboardViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var currentBudget: Budget?
    @Published var recentTransactions: [Transaction] = []
    @Published var totalSpent: Double = 0
    @Published var categorySpending: [CategorySpending] = []
    @Published var dailyAverage: Double = 0
    @Published var topCategory: String = "None"
    @Published var transactionCount: Int = 0
    @Published var monthProgress: Int = 0
    
    // Core Data context
    private var viewContext: NSManage

import Foundation
import CoreData
import SwiftUI

class DashboardViewModel: ObservableObject {
    // Published properties
    @Published var currentBudget: Budget?
    @Published var recentTransactions: [Transaction] = []
    @Published var totalSpent: Double = 0
    @Published var categorySpending: [CategorySpending] = []
    @Published var dailyAverage: Double = 0
    @Published var topCategory: String = "-"
    @Published var transactionCount: Int = 0
    @Published var monthProgress: Int = 0
    
    // Formatters
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // This could come from user settings
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // Initialize the view model
    init() {
        calculateMonthProgress()
    }
    
    // Load data from Core Data
    func loadData(context: NSManagedObjectContext? = nil) {
        let viewContext = context ?? PersistenceController.shared.container.viewContext
        
        fetchCurrentBudget(context: viewContext)
        fetchRecentTransactions(context: viewContext)
        calculateTotalSpent()
        calculateCategorySpending()
        calculateDailyAverage()
        findTopCategory()
        transactionCount = recentTransactions.count
    }
    
    // Format currency values
    func formatCurrency(_ value: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    // Calculate color for progress bars
    func progressColor(spent: Double, budget: Double) -> Color {
        let percentage = spent / budget
        if percentage >= 1.0 {
            return .red
        } else if percentage >= 0.75 {
            return .orange
        } else {
            return .green
        }
    }
    
    // Estimated category budget (proportional to total budget)
    func getCategoryBudget(for category: String, totalBudget: Double) -> Double? {
        // This is a simplified approach - in a real app, you might have specific category budgets
        
        // Get historical percentage of spending in this category
        let totalCategorySpending = categorySpending.reduce(0) { $0 + $1.amount }
        if totalCategorySpending == 0 { return nil }
        
        let categoryAmount = categorySpending.first(where: { $0.category == category })?.amount ?? 0
        let categoryPercentage = categoryAmount / totalCategorySpending
        
        // Allocate budget proportionally
        return totalBudget * categoryPercentage
    }
    
    // MARK: - Private Methods
    
    private func fetchCurrentBudget(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let year = calendar.component(.year, from: Date())
        let monthString = String(format: "%02d", month)
        
        let request: NSFetchRequest<Budget> = Budget.fetchRequest()
        request.predicate = NSPredicate(format: "month == %@ AND year == %d", monthString, year)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            self.currentBudget = results.first
        } catch {
            print("Error fetching current budget: \(error)")
        }
    }
    
    private func fetchRecentTransactions(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let startOfMonth = getStartOfMonth()
        let endOfMonth = getEndOfMonth()
        
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startOfMonth as NSDate, endOfMonth as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        
        do {
            self.recentTransactions = try context.fetch(request)
        } catch {
            print("Error fetching recent transactions: \(error)")
            self.recentTransactions = []
        }
    }
    
    private func calculateTotalSpent() {
        self.totalSpent = recentTransactions.reduce(0) { total, transaction in
            // Only count expense transactions
            if transaction.type == "expense" {
                return total + transaction.amount
            } else if transaction.type == "income" {
                // Income transactions have negative amount in our model
                return total
            }
            return total
        }
    }
    
    private func calculateCategorySpending() {
        var categoryAmounts: [String: Double] = [:]
        
        for transaction in recentTransactions {
            // Only include expense transactions
            if transaction.type == "expense" {
                let category = transaction.category ?? "Uncategorized"
                categoryAmounts[category, default: 0] += transaction.amount
            }
        }
        
        self.categorySpending = categoryAmounts.map { CategorySpending(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    private func calculateDailyAverage() {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = getStartOfMonth()
        
        // Calculate days elapsed in the month
        let daysElapsed = calendar.dateComponents([.day], from: startOfMonth, to: now).day ?? 1
        
        // Ensure we don't divide by zero
        let days = max(daysElapsed, 1)
        
        // Calculate daily average
        self.dailyAverage = totalSpent / Double(days)
    }
    
    private func findTopCategory() {
        if let topCat = categorySpending.first {
            self.topCategory = topCat.category
        } else {
            self.topCategory = "None"
        }
    }
    
    private func calculateMonthProgress() {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start and end of current month
        let startOfMonth = getStartOfMonth()
        let endOfMonth = getEndOfMonth()
        
        // Calculate total days in month and days elapsed
        let daysInMonth = calendar.dateComponents([.day], from: startOfMonth, to: endOfMonth).day ?? 30
        let daysElapsed = calendar.dateComponents([.day], from: startOfMonth, to: now).day ?? 0
        
        // Calculate progress percentage
        let progress = (Double(daysElapsed) / Double(daysInMonth)) * 100
        self.monthProgress = Int(progress)
    }
    
    // Format currency for short display (e.g., on chart annotations)
    func shortCurrency(_ value: Double) -> String {
        if value >= 1000 {
            return "$\(Int(value / 1000))k"
        } else {
            return "$\(Int(value))"
        }
    }
    
    // Format date for display
    func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    // MARK: - Helper Methods
    
    private func getStartOfMonth() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        return calendar.date(from: components) ?? now
    }
    
    private func getEndOfMonth() -> Date {
        let calendar = Calendar.current
        let startOfMonth = getStartOfMonth()
        
        // Get end of month by adding one month and subtracting one day
        if let nextMonth = calendar.date(byAdding: DateComponents(month: 1), to: startOfMonth),
           let endOfMonth = calendar.date(byAdding: DateComponents(day: -1), to: nextMonth) {
            return endOfMonth
        }
        
        // Fallback to current date if calculation fails
        return Date()
    }
    
    // Filter transactions by category
    func filterTransactionsByCategory(_ category: String) -> [Transaction] {
        return recentTransactions.filter { $0.category == category }
    }
    
    // Get weekly spending data for charts
    var weeklySpendingData: [WeeklySpending] {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate dates for the past 7 days
        var result: [WeeklySpending] = []
        let daySymbols = calendar.shortWeekdaySymbols
        
        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                let dayOfWeek = calendar.component(.weekday, from: date) - 1 // 0-based index
                let day = daySymbols[dayOfWeek]
                
                // Sum transactions for this day
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                let dayTotal = recentTransactions
                    .filter { transaction in
                        guard let transactionDate = transaction.date else { return false }
                        return transactionDate >= dayStart && transactionDate < dayEnd && transaction.type == "expense"
                    }
                    .reduce(0) { $0 + $1.amount }
                
                result.append(WeeklySpending(day: day, amount: dayTotal))
            }
        }
        
        return result
    }
    
    // Get monthly spending data for charts
    var monthlySpendingData: [MonthlySpending] {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate dates for the past 6 months
        var result: [MonthlySpending] = []
        let monthSymbols = calendar.shortMonthSymbols
        
        for monthOffset in (0..<6).reversed() {
            if let date = calendar.date(byAdding: .month, value: -monthOffset, to: now) {
                let month = monthSymbols[calendar.component(.month, from: date) - 1]
                
                // Get start and end of month
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
                
                let monthTotal = recentTransactions
                    .filter { transaction in
                        guard let transactionDate = transaction.date else { return false }
                        return transactionDate >= startOfMonth && transactionDate < nextMonth && transaction.type == "expense"
                    }
                    .reduce(0) { $0 + $1.amount }
                
                result.append(MonthlySpending(month: month, amount: monthTotal))
            }
        }
        
        return result
    }
}

// Data models for charts
struct WeeklySpending {
    let day: String
    let amount: Double
}

struct MonthlySpending {
    let month: String
    let amount: Double
}
