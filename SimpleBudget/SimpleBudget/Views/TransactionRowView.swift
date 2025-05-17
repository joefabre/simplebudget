import SwiftUI

public struct TransactionRowView: View {
    let transaction: Transaction
    
    public init(transaction: Transaction) {
        self.transaction = transaction
    }
    
    // Currency formatter
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // Note: This could be made dynamic based on user settings
        return formatter
    }()
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    public var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(categoryColor(category: transaction.category ?? "Uncategorized").opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transaction.type == "income" ? "arrow.down" : "arrow.up")
                    .foregroundColor(transaction.type == "income" ? .green : .red)
                    .font(.system(size: 16, weight: .bold))
            }
            
            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text(transaction.category ?? "Uncategorized")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let date = transaction.date {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(dateFormatter.string(from: date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            Text(currencyFormatter.string(from: NSNumber(value: abs(transaction.amount))) ?? "$0.00")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.type == "income" ? .green : .red)
        }
        .padding(.vertical, 4)
    }
    
    // Helper function to get color for category
    private func categoryColor(category: String) -> Color {
        switch category {
        case "Food":
            return .orange
        case "Transportation":
            return .blue
        case "Housing":
            return .purple
        case "Entertainment":
            return .pink
        case "Shopping":
            return .yellow
        case "Utilities":
            return .gray
        case "Healthcare":
            return .red
        case "Education":
            return .green
        case "Travel":
            return .mint
        case "Personal":
            return .indigo
        case "Income":
            return .green
        default:
            return .gray
        }
    }
}

// Preview
struct TransactionRowView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.amount = 42.50
        transaction.category = "Food"
        transaction.date = Date()
        transaction.title = "Lunch at Cafe"
        transaction.type = "expense"
        
        return TransactionRowView(transaction: transaction)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

