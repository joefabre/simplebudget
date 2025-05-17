import Foundation
import CoreData

// Extension to the auto-generated Budget entity to handle income sources
extension Budget {
    
    // Struct to represent income sources with their properties
    struct IncomeSource: Identifiable, Codable, Hashable {
        var id = UUID()
        var name: String
        var amount: Double
        var frequency: IncomeFrequency
        
        enum IncomeFrequency: String, Codable, CaseIterable, Identifiable {
            case monthly = "Monthly"
            case biweekly = "Bi-weekly"
            case weekly = "Weekly"
            
            var id: String { self.rawValue }
            
            var multiplier: Double {
                switch self {
                case .monthly: return 1.0
                case .biweekly: return 2.17 // Approximate (26 payments / 12 months)
                case .weekly: return 4.33   // Approximate (52 payments / 12 months)
                }
            }
        }
        
        // Calculate monthly value based on frequency
        var monthlyValue: Double {
            return amount * frequency.multiplier
        }
    }
    
    // Getter and setter for income sources
    var incomeSources: [IncomeSource] {
        get {
            // Retrieve and decode income sources from JSON
            guard let jsonString = self.incomeSourcesJSON,
                  let jsonData = jsonString.data(using: .utf8) else {
                return []
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode([IncomeSource].self, from: jsonData)
            } catch {
                print("Error decoding income sources: \(error)")
                return []
            }
        }
        set {
            // Encode and store income sources as JSON
            do {
                let encoder = JSONEncoder()
                let jsonData = try encoder.encode(newValue)
                self.incomeSourcesJSON = String(data: jsonData, encoding: .utf8)
            } catch {
                print("Error encoding income sources: \(error)")
            }
        }
    }
    
    // Total monthly income from all sources
    var totalMonthlyIncome: Double {
        return incomeSources.reduce(0) { $0 + $1.monthlyValue }
    }
    
    // Calculate remaining budget after expenses
    var remainingBudget: Double {
        return totalMonthlyIncome - amount
    }
    
    // Convenience method to add a new income source
    func addIncomeSource(name: String, amount: Double, frequency: IncomeSource.IncomeFrequency) {
        var sources = self.incomeSources
        let newSource = IncomeSource(
            name: name,
            amount: amount,
            frequency: frequency
        )
        sources.append(newSource)
        self.incomeSources = sources
    }
    
    // Convenience method to remove an income source
    func removeIncomeSource(at index: Int) {
        var sources = self.incomeSources
        guard index < sources.count else { return }
        sources.remove(at: index)
        self.incomeSources = sources
    }
}

