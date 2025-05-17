import SwiftUI

// Budget stat view for displaying budget statistics
struct BudgetStatView: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    private let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f
    }()
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(formatter.string(from: NSNumber(value: amount)) ?? "$0.00")
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HStack {
        BudgetStatView(
            title: "Income",
            amount: 2500.00,
            color: .green,
            icon: "arrow.down.circle.fill"
        )
        
        BudgetStatView(
            title: "Expenses",
            amount: 1200.00,
            color: .orange,
            icon: "arrow.up.circle.fill"
        )
        
        BudgetStatView(
            title: "Remaining",
            amount: 1300.00,
            color: .blue,
            icon: "equal.circle.fill"
        )
    }
    .padding()
    .previewLayout(.sizeThatFits)
}

