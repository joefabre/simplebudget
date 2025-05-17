import SwiftUI

struct CategoryDetailView: View {
    let categories: [CategorySpending]
    
    var body: some View {
        List {
            ForEach(categories, id: \.category) { item in
                HStack {
                    Text(item.category)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(formatCurrency(item.amount))
                        .font(.headline)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Expense Categories")
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// Preview for CategoryDetailView
#Preview {
    // Sample data for preview
    let sampleCategories = [
        CategorySpending(category: "Food", amount: 350.50),
        CategorySpending(category: "Transportation", amount: 150.75),
        CategorySpending(category: "Entertainment", amount: 200.00),
        CategorySpending(category: "Utilities", amount: 180.25)
    ]
    
    return CategoryDetailView(categories: sampleCategories)
}

