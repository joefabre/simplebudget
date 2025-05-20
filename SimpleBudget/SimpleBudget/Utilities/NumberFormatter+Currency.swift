import Foundation

extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    static func formatCurrency(_ value: Double) -> String {
        return Self.currency.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

