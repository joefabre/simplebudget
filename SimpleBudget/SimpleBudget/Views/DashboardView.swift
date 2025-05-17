import SwiftUI
import Charts

public struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isAddingTransaction = false
    @State private var isSettingBudget = false
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(UIColor.systemGray5)
                    .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 24) {  // Increased spacing between cards
                    budgetSummaryCard
                    spendingChartsSection
                    categoryBreakdownSection
                    recentTransactionsSection
                }
                .padding()
                // No need for extra bottom padding since ContentView handles it
                }
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
            HStack {
                Text("Monthly Budget")
                    .font(.headline)
                
                Spacer()
                
                if let budget = viewModel.currentBudget, viewModel.incomeSourceCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text("\(viewModel.incomeSourceCount) Income \(viewModel.incomeSourceCount == 1 ? "Source" : "Sources")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.bottom, 4)
            
            if let budget = viewModel.currentBudget {
                // Income information (if available)
                if viewModel.totalMonthlyIncome > 0 {
                    HStack {
                        Text("Total Monthly Income:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.formatCurrency(viewModel.totalMonthlyIncome))
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
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
                    
                    if viewModel.totalMonthlyIncome > 0 {
                        BudgetStatView(
                            title: "Available",
                            amount: max(0, viewModel.totalMonthlyIncome - viewModel.totalSpent),
                            color: viewModel.totalMonthlyIncome >= viewModel.totalSpent ? .green : .red,
                            icon: "arrow.left.arrow.right"
                        )
                    } else {
                        BudgetStatView(
                            title: "Remaining",
                            amount: budget.amount - viewModel.totalSpent,
                            color: budget.amount - viewModel.totalSpent < 0 ? .red : .green,
                            icon: "arrow.left.arrow.right"
                        )
                    }
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    if viewModel.totalMonthlyIncome > 0 {
                        // Income vs Expenses section
                        HStack {
                            Text("Income Usage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(min((viewModel.totalSpent / viewModel.totalMonthlyIncome) * 100, 100)))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: min(viewModel.totalSpent / viewModel.totalMonthlyIncome, 1.0))
                            .tint(viewModel.progressColor(spent: viewModel.totalSpent, budget: viewModel.totalMonthlyIncome))
                        
                        if viewModel.totalMonthlyIncome > 0 && budget.amount > 0 {
                            // Income distribution (budget vs savings)
                            HStack {
                                Text("Budget Allocation")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(min((budget.amount / viewModel.totalMonthlyIncome) * 100, 100)))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                            
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(height: 8)
                                    .foregroundColor(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .frame(width: min((budget.amount / viewModel.totalMonthlyIncome) * UIScreen.main.bounds.width * 0.8, UIScreen.main.bounds.width * 0.8), height: 8)
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                            
                            // Legend
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .frame(width: 8, height: 8)
                                        .foregroundColor(.blue)
                                    Text("Budget")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .frame(width: 8, height: 8)
                                        .foregroundColor(.gray.opacity(0.2))
                                    Text("Unallocated")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 2)
                        }
                    } else {
                        // Original budget progress bar
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
        .background(Color(UIColor.systemBackground))  // Lighter background for better contrast
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
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
        .background(Color(UIColor.systemBackground))  // Lighter background for better contrast
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
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
        .background(Color(UIColor.systemBackground))  // Lighter background for better contrast
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
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
        .background(Color(UIColor.systemBackground))  // Lighter background for better contrast
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
    
    // Formatter for currency
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // Can be made customizable in settings
        return formatter
    }()
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

