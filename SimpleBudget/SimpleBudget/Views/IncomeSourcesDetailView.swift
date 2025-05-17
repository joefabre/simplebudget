import SwiftUI

/// Shows a detailed list of income sources with their values
struct IncomeSourcesDetailView: View {
    let incomeSources: [Budget.IncomeSource]
    
    var body: some View {
        NavigationStack {
            List {
                if incomeSources.isEmpty {
                    emptyStateView
                } else {
                    sourcesList
                }
            }
            .navigationTitle("Income Sources")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Subviews
    
    /// Empty state when no income sources are available
    private var emptyStateView: some View {
        Text("No income sources added")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
    
    /// List of income sources
    private var sourcesList: some View {
        ForEach(incomeSources) { source in
            HStack {
                // Left side - source details
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.name)
                        .font(.headline)
                    
                    Text(source.frequency.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Right side - financial details
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(source.amount))
                        .font(.headline)
                    
                    Text(formatCurrency(source.monthlyValue))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Formats a Double as a currency string
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Preview
#Preview {
    // Sample income sources for preview
    let sampleIncomeSources = [
        Budget.IncomeSource(
            name: "Salary",
            amount: 3500.00,
            frequency: .monthly
        ),
        Budget.IncomeSource(
            name: "Freelance Work",
            amount: 500.00, 
            frequency: .biweekly
        ),
        Budget.IncomeSource(
            name: "Investment Dividends",
            amount: 200.00,
            frequency: .monthly
        )
    ]
    
    return IncomeSourcesDetailView(incomeSources: sampleIncomeSources)
}

