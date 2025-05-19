import SwiftUI
import CoreData
import Charts

struct BudgetSummaryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = DashboardViewModel()
    @State private var isAddingTransaction = false
    @State private var isSettingBudget = false
    @State private var showingIncomeSourcesDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Budget Summary Section
                    incomeSummaryCard
                    expenseSummaryCard
                    budgetRemainingCard
                    
                    // Category Breakdown Section
                    categoryBreakdownSection
                    
                    // Income Sources Section
                    incomeSourcesSection
                }
                .padding()
            }
            .navigationTitle("Budget Summary")
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
                if let budget = viewModel.currentBudget {
                    AddBudgetView(budget: budget)
                        .environment(\.managedObjectContext, viewContext)
                } else {
                    AddBudgetView()
                        .environment(\.managedObjectContext, viewContext)
                }
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
    
    private var incomeSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Income")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingIncomeSourcesDetail = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        
                        Text("\(viewModel.incomeSourceCount) \(viewModel.incomeSourceCount == 1 ? "Source" : "Sources")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if viewModel.totalMonthlyIncome > 0 {
                HStack {
                    Text("Total Monthly Income:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.formatCurrency(viewModel.totalMonthlyIncome))
                        .font(.headline)
                        .foregroundColor(.green)
                }
            } else {
                VStack(spacing: 8) {
                    Text("No income sources added")
                        .foregroundColor(.secondary)
                    
                    Button {
                        isSettingBudget = true
                    } label: {
                        Text("Add Income Sources")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingIncomeSourcesDetail) {
            IncomeSourcesDetailView(incomeSources: viewModel.currentBudget?.incomeSources ?? [])
        }
    }
    
    private var expenseSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Expenses")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    isAddingTransaction = true
                } label: {
                    Label("Add", systemImage: "plus.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if viewModel.totalSpent > 0 {
                HStack {
                    Text("Total Expenses:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.formatCurrency(viewModel.totalSpent))
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                
                // Add progress bar to show expense vs income
                if viewModel.totalMonthlyIncome > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Budget Usage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(viewModel.incomeUsagePercentage)%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: min(viewModel.totalSpent / viewModel.totalMonthlyIncome, 1.0))
                            .tint(viewModel.progressColor(spent: viewModel.totalSpent, budget: viewModel.totalMonthlyIncome))
                    }
                    .padding(.top, 8)
                }
            } else {
                VStack(spacing: 8) {
                    Text("No expenses recorded this month")
                        .foregroundColor(.secondary)
                    
                    Button {
                        isAddingTransaction = true
                    } label: {
                        Text("Add Expense")
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
    
    private var budgetRemainingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
            
            if viewModel.totalMonthlyIncome > 0 {
                HStack(spacing: 20) {
                    BudgetStatView(
                        title: "Income",
                        amount: viewModel.totalMonthlyIncome,
                        color: .green,
                        icon: "arrow.down.circle.fill"
                    )
                    
                    Divider()
                    
                    BudgetStatView(
                        title: "Expenses",
                        amount: viewModel.totalSpent,
                        color: .orange,
                        icon: "arrow.up.circle.fill"
                    )
                    
                    Divider()
                    
                    BudgetStatView(
                        title: "Remaining",
                        amount: max(0, viewModel.totalMonthlyIncome - viewModel.totalSpent),
                        color: viewModel.totalMonthlyIncome >= viewModel.totalSpent ? .blue : .red,
                        icon: "equal.circle.fill"
                    )
                }
                
                // Add explanation text
                Text("Remaining budget calculated as income minus expenses.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            } else {
                Text("Add income sources and expenses to see your budget summary")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expense Categories")
                .font(.headline)
            
            if viewModel.categorySpending.isEmpty {
                Text("No expenses yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                // Category breakdown
                ForEach(viewModel.categorySpending.prefix(5), id: \.category) { item in
                    VStack(spacing: 4) {
                        HStack {
                            Text(item.category)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(viewModel.formatCurrency(item.amount))
                                .font(.subheadline)
                        }
                        
                        // Progress bar showing percentage of total expenses
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(width: geometry.size.width, height: 8)
                                    .opacity(0.2)
                                    .foregroundColor(.gray)
                                
                                Rectangle()
                                    .frame(width: min(CGFloat(item.amount / viewModel.totalSpent) * geometry.size.width, geometry.size.width), height: 8)
                                    .foregroundColor(.blue)
                            }
                            .cornerRadius(4)
                        }
                        .frame(height: 8)
                        
                        // Show percentage
                        HStack {
                            Spacer()
                            Text("\(Int((item.amount / viewModel.totalSpent) * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // View all button if there are more categories
                if viewModel.categorySpending.count > 5 {
                    NavigationLink {
                        CategoryDetailView(categories: viewModel.categorySpending)
                    } label: {
                        Text("View all categories")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var incomeSourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Income Sources")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    isSettingBudget = true
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if let budget = viewModel.currentBudget, !budget.incomeSources.isEmpty {
                ForEach(budget.incomeSources.prefix(3), id: \.id) { source in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(source.name)
                                .font(.subheadline)
                            
                            Text(source.frequency.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(viewModel.formatCurrency(source.amount))
                                .font(.subheadline)
                            
                            Text(viewModel.formatCurrency(source.monthlyValue))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if source.id != budget.incomeSources.prefix(3).last?.id {
                        Divider()
                    }
                }
                
                // Show More button if there are more income sources
                if budget.incomeSources.count > 3 {
                    Button {
                        showingIncomeSourcesDetail = true
                    } label: {
                        Text("Show \(budget.incomeSources.count - 3) more")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    }
                }
            } else {
                Text("No income sources added")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
