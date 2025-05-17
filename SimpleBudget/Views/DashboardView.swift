import SwiftUI
import Charts

public struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isAddingTransaction = false
    @State private var isSettingBudget = false
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    budgetSummaryCard
                    spendingChartsSection
                    categoryBreakdownSection
                    recentTransactionsSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            isAddingTransaction = true
                        } label: {
                            Label("Add Transaction", systemImage: "plus.circle")
                        }
                        
                        Button {
                            isSettingBudget = true
                        } label: {
                            Label("Set Budget", systemImage: "dollarsign.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingTransaction) {
                AddTransactionView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $isSettingBudget) {
                AddBudgetView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .onAppear {
                viewModel.loadData(context: viewContext)
            }
            .refreshable {
                viewModel.loadData(context: viewContext)
            }
        }
    }
    
    // MARK: - Component Views
    
    private var budgetSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Monthly Budget")
                .font(.headline)
                .padding(.bottom, 4)
            
            if let budget = viewModel.currentBudget {
                // Budget stats
                HStack {
                    BudgetStatView(
                        title: "Budget",
                        amount: budget.amount,
                        color: .blue,
                        icon: "dollarsign.circle.fill"
                    )
                    
                    Divider()
                    
                    BudgetStatView(
                        title: "Spent",
                        amount: viewModel.totalSpent,
                        color: viewModel.totalSpent > budget.amount ? .red : .orange,
                        icon: "creditcard.fill"
                    )
                    
                    Divider()
                    
                    BudgetStatView(
                        title: "Remaining",
                        amount: budget.amount - viewModel.totalSpent,
                        color: budget.amount - viewModel.totalSpent < 0 ? .red : .green,
                        icon: "arrow.left.arrow.right"
                    )
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Budget Used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(min((viewModel.totalSpent / budget.amount) * 100, 100)))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: min(viewModel.totalSpent / budget.amount, 1.0))
                        .tint(viewModel.progressColor(spent: viewModel.totalSpent, budget: budget.amount))
                }
                .padding(.top, 8)
            } else {
                // No budget set
                VStack(spacing: 12) {
                    Text("No budget set for this month")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    
                    Button {
                        isSettingBudget = true
                    } label: {
                        Text("Set Budget")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var spendingChartsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Overview")
                .font(.headline)
                .padding(.bottom, 4)
            
            if viewModel.recentTransactions.isEmpty {
                Text("No spending data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Weekly spending chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Spending")
                        .font(.subheadline)
                    
                    Chart {
                        ForEach(viewModel.weeklySpendingData, id: \.day) { item in
                            BarMark(
                                x: .value("Day", item.day),
                                y: .value("Amount", item.amount)
                            )
                            .foregroundStyle(Color.blue.gradient)
                        }
                    }
                    .frame(height: 180)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Monthly spending trend
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monthly Trend")
                        .font(.subheadline)
                    
                    Chart {
                        ForEach(viewModel.monthlySpendingData, id: \.month) { item in
                            LineMark(
                                x: .value("Month", item.month),
                                y: .value("Amount", item.amount)
                            )
                            .foregroundStyle(Color.green.gradient)
                            .symbol {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        ForEach(viewModel.monthlySpendingData, id: \.month) { item in
                            AreaMark(
                                x: .value("Month", item.month),
                                y: .value("Amount", item.amount)
                            )
                            .foregroundStyle(Color.green.opacity(0.1).gradient)
                        }
                    }
                    .frame(height: 180)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)
                .padding(.bottom, 4)
            
            if viewModel.categorySpending.isEmpty {
                Text("No category data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Pie chart
                Chart {
                    ForEach(viewModel.categorySpending, id: \.category) { item in
                        SectorMark(
                            angle: .value("Amount", item.amount),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .cornerRadius(5)
                        .foregroundStyle(by: .value("Category", item.category))
                    }
                }
                .frame(height: 200)
                .chartLegend(position: .bottom, alignment: .center)
                
                // Top categories
                VStack(spacing: 8) {
                    ForEach(viewModel.categorySpending.prefix(3), id: \.category) { item in
                        HStack {
                            Text(item.category)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(viewModel.formatCurrency(item.amount))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink {
                    TransactionsView()
                        .environment(\.managedObjectContext, viewContext)
                } label: {
                    Text("View All")
                        .font(.subheadline)
                }
            }
            .padding(.bottom, 4)
            
            if viewModel.recentTransactions.isEmpty {
                Text("No recent transactions")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.recentTransactions.prefix(3)) { transaction in
                    TransactionRowView(transaction: transaction)
                    
                    if transaction != viewModel.recentTransactions.prefix(3).last {
                        Divider()
                    }
                }
                
                if viewModel.recentTransactions.count > 3 {
                    NavigationLink {
                        TransactionsView()
                            .environment(\.managedObjectContext, viewContext)
                    } label: {
                        Text("View \(viewModel.recentTransactions.count - 3) more")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // Formatter for currency
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // Can be made customizable in settings
        return formatter
    }()
}

struct CategorySpending {
    var category: String
    var amount: Double
}

struct BudgetStatView: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String  // Changed from iconName to match usage
    
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
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

