import SwiftUI
import CoreData

struct HomeView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var previousMonthNetWorth: Double = 0.0
    @State private var hasSufficientDataTimespan: Bool = false
    @State private var showingAddTransaction = false
    @State private var isSettingBudget = false
    @State private var showingMainApp = false
    @AppStorage("selectedTab") private var selectedTab = 0
    @State private var showingAccountsView = false
    @State private var showingAddAccount = false
    
    // Privacy mode toggle
    @AppStorage("privacyModeEnabled") private var privacyModeEnabled = false
    @State private var editingAccount: Account? = nil
    
    // Fetch accounts from Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    
    // Get current time of day for greeting
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning"
        } else if hour < 18 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(UIColor.systemGray5)
                    .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 24) {  // Increased spacing between sections
                    // Header with welcome and date
                    headerSection
                    
                    // Net worth overview
                    netWorthCard
                    
                    // Accounts overview
                    accountsOverviewSection
                    
                    // Budget overview card
                    if let _ = viewModel.currentBudget {
                        financialOverviewCard
                    }
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Recent activity
                    recentActivitySection
                }
                .padding()
                }
            }
            .navigationDestination(isPresented: $showingMainApp) {
                ContentView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingAddTransaction) {
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
            .onChange(of: isSettingBudget) { isShowing in
                if !isShowing {
                    // Refresh data when sheet is dismissed
                    viewModel.loadData(context: viewContext)
                }
            }
            .sheet(isPresented: $showingAccountsView) {
                AccountsView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $editingAccount) { account in
                EditAccountView(account: account)
                    .environment(\.managedObjectContext, viewContext)
            }
            .onAppear {
                viewModel.loadData(context: viewContext)
                loadPreviousMonthNetWorth()
            }
            .refreshable {
                viewModel.loadData(context: viewContext)
            }
        }
    }
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(greeting)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("Joe")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(spacing: 8) {  // Use VStack with smaller spacing
                    // Dashboard button
                    Button {
                        selectedTab = 0
                        showingMainApp = true
                    } label: {
                        HStack {
                            Text("Dashboard")
                                .font(.headline)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    
                    // Privacy toggle button below dashboard
                    Button {
                        togglePrivacyMode()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: privacyModeEnabled ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 14))
                            
                            Text(privacyModeEnabled ? "Hidden" : "Visible")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(privacyModeEnabled ? Color.indigo : Color.gray.opacity(0.2))
                        .foregroundColor(privacyModeEnabled ? .white : .primary)
                        .cornerRadius(16)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }
    
    private var netWorthCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Net Worth")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button("This Month", action: {})
                    Button("Last 3 Months", action: {})
                    Button("This Year", action: {})
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(alignment: .bottom) {
                Text(formatCurrencyWithPrivacy(totalNetWorth))
                    .font(.system(size: 32, weight: .bold))
                
                Spacer()
                
                if hasValidHistoricalData && netWorthChangePercentage != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: netWorthChangePercentage >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                            .foregroundColor(netWorthChangePercentage >= 0 ? .green : .red)
                        
                        Text("\(abs(netWorthChangePercentage))%")
                            .font(.caption)
                            .foregroundColor(netWorthChangePercentage >= 0 ? .green : .red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((netWorthChangePercentage >= 0 ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            if !accounts.isEmpty {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Assets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatCurrencyWithPrivacy(totalAssets))
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Debts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatCurrencyWithPrivacy(viewModel.totalDebt))
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .cardStyle()
    }
    
    private var financialOverviewCard: some View {
        VStack {
            if let budget = viewModel.currentBudget {
                VStack(spacing: 20) {
                    HStack {
                        Text("Monthly Budget")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            isSettingBudget = true
                        } label: {
                            Text("Edit")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack(spacing: 30) {
                        financialStatView(
                            title: "Budget",
                            amount: budget.amount,
                            icon: "dollarsign.circle.fill",
                            color: .blue
                        )
                        
                        financialStatView(
                            title: "Spent",
                            amount: viewModel.totalSpent,
                            icon: "creditcard.fill",
                            color: viewModel.totalSpent > budget.amount ? .red : .orange
                        )
                        
                        financialStatView(
                            title: "Remaining",
                            amount: budget.amount - viewModel.totalSpent,
                            icon: "arrow.left.arrow.right",
                            color: budget.amount - viewModel.totalSpent < 0 ? .red : .green
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
                }
                .cardStyle()
            } else {
                VStack(spacing: 16) {
                    Text("No budget set for this month")
                        .foregroundColor(.secondary)
                    
                Button {
                    isSettingBudget = true
                } label: {
                    Text("Set Budget")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                .cardStyle()
                
                // Add a balance section if there are accounts
                if !accounts.isEmpty {
                    HStack {
                        Text("Total Balance")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(formatCurrencyWithPrivacy(totalAccountsBalance))
                            .font(.headline)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
    
    private var accountsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Accounts")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingAccountsView = true
                } label: {
                    HStack {
                        Text("View All")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            
            if accounts.isEmpty {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Image(systemName: "banknote")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.bottom, 4)
                        
                        Text("No accounts added yet")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text("Add your accounts to track balances and monitor your financial health")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    
                    Button {
                        showingAccountsView = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Your First Account")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                .cardStyle()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(accounts) { account in
                            accountCard(account)
                                .onTapGesture {
                                    editingAccount = account  // Show edit view instead of accounts view
                                }
                        }
                        
                        // "Add Account" card
                        Button {
                            showingAccountsView = true
                        } label: {
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(.gray)
                                }
                                
                                Text("Add Account")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                            }
                            .frame(width: 120, height: 150)
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private func accountCard(_ account: Account) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Account icon and type
            HStack {
                // Use system icon or a default based on account type
                Image(systemName: account.icon ?? accountTypeIcon(account.type ?? "other"))
                    .font(.system(size: 24))
                    .foregroundColor(accountTypeColor(account.type ?? "other"))
                    .frame(width: 40, height: 40)
                    .background(accountTypeColor(account.type ?? "other").opacity(0.2))
                    .clipShape(Circle())
                
                Spacer()
                
                Text(account.type ?? "Account")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            // Account name
            Text(account.name ?? "Account")
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Account balance
            Text(formatCurrencyWithPrivacy(account.balance))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(accountTypeColor(account.type ?? "other"))
        }
        .frame(width: 150, height: 150)
        .cardStyle()
    }
    
    private func accountTypeIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "checking":
            return "creditcard.fill"
        case "savings":
            return "banknote.fill"
        case "investment":
            return "chart.line.uptrend.xyaxis"
        default:
            return "dollarsign.circle.fill"
        }
    }
    
    private func accountTypeColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "checking":
            return .blue
        case "savings":
            return .green
        case "investment":
            return .purple
        default:
            return .gray
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 16) {
                actionButton(
                    title: "Add Transaction",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    showingAddTransaction = true
                }
                
                actionButton(
                    title: "Set Budget",
                    icon: "dollarsign.circle.fill",
                    color: .green
                ) {
                    isSettingBudget = true
                }
                
                Button {
                    selectedTab = 0
                    showingMainApp = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 30))
                            .foregroundColor(.orange)
                        
                        Text("View All")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    selectedTab = 0
                    showingMainApp = true
                } label: {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
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
            }
        }
        .cardStyle()
    }
    
    // MARK: - Helper Views
    
    private func financialStatView(title: String, amount: Double, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(formatCurrencyWithPrivacy(amount))
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Helpers
    
    private var totalNetWorth: Double {
        // Net worth is total assets minus debts
        let assets = totalAssets
        let debts = viewModel.totalDebt
        return assets - debts
    }
    
    // Calculate the net worth change percentage
    private var netWorthChangePercentage: Int {
        // Only calculate if we have valid previous data and at least $10 of net worth for meaningful comparison
        guard previousMonthNetWorth >= 10 && totalNetWorth > 0 else { return 0 }
        
        let change = totalNetWorth - previousMonthNetWorth
        let percentage = (change / previousMonthNetWorth) * 100
        
        return Int(percentage)
    }
    
    // Check if we have enough historical data to show a percentage
    private var hasValidHistoricalData: Bool {
        return previousMonthNetWorth >= 10 && hasSufficientDataTimespan
    }
    
    // Load the previous month's net worth data
    private func loadPreviousMonthNetWorth() {
        let context = viewContext
        let calendar = Calendar.current
        
        // Get the first day of previous month
        guard let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())),
              let prevMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else {
            return
        }
        
        // Get last day of previous month
        let prevMonthRange = calendar.range(of: .day, in: .month, for: prevMonth)
        let lastDayOfPrevMonth = prevMonthRange?.count ?? 28
        
        guard let endOfPrevMonth = calendar.date(from: DateComponents(
            year: calendar.component(.year, from: prevMonth),
            month: calendar.component(.month, from: prevMonth),
            day: lastDayOfPrevMonth,
            hour: 23,
            minute: 59,
            second: 59
        )) else { return }
        
        // Fetch accounts as they were at the end of the previous month
        // This is a simplified version - in a real app, you would track account balances over time
        
        // For now, estimate previous month net worth based on transactions in that month
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date <= %@", endOfPrevMonth as NSDate)
        
        do {
            let transactions = try context.fetch(fetchRequest)
            
            // Reset duration check flag
            hasSufficientDataTimespan = false
            
            // Only calculate if we have enough transaction history (minimum 3 transactions)
            if transactions.count < 3 {
                previousMonthNetWorth = 0 // Not enough historical data
                return
            }
            
            // Check if transactions span at least 30 days
            if let oldestTransaction = transactions.min(by: { 
                ($0.date ?? Date()) < ($1.date ?? Date()) 
            }), let oldestDate = oldestTransaction.date {
                let daysSinceOldest = Calendar.current.dateComponents([.day], from: oldestDate, to: Date()).day ?? 0
                hasSufficientDataTimespan = daysSinceOldest >= 30
                
                if !hasSufficientDataTimespan {
                    previousMonthNetWorth = 0 // Not enough time span
                    return
                }
            } else {
                previousMonthNetWorth = 0 // Couldn't determine time span
                return
            }
            
            // Calculate net change from transactions
            let netChange = transactions.reduce(0.0) { result, transaction in
                if transaction.type == "expense" {
                    return result - transaction.amount
                } else if transaction.type == "income" {
                    return result + transaction.amount
                }
                return result
            }
            
            // Verify there's significant financial activity (at least $10 in total transaction volume)
            let totalActivity = transactions.reduce(0.0) { result, transaction in
                return result + transaction.amount
            }
            
            if totalActivity < 10 {
                previousMonthNetWorth = 0 // Not enough meaningful activity
                return
            }
            
            // Estimate previous month's net worth as current minus changes since then
            // This is an approximation - a real implementation would store historical balances
            previousMonthNetWorth = max(totalNetWorth - netChange, 0.01) // Avoid division by zero
            
        } catch {
            print("Error fetching previous transactions: \(error)")
            previousMonthNetWorth = 0 // Default to no historical data
            hasSufficientDataTimespan = false
        }
    }
    
    private var totalAssets: Double {
        // Sum of all non-debt account balances
        accounts.reduce(0) { sum, account in
            // Only include non-debt accounts as assets
            if !account.isDebt {
                return sum + max(account.balance, 0)
            } else {
                return sum
            }
        }
    }
    
    private var totalAccountsBalance: Double {
        // Total balance considering debts as negative
        accounts.reduce(0) { sum, account in
            if account.isDebt {
                return sum - account.balance // Subtract debt balances
            } else {
                return sum + account.balance // Add asset balances
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    // MARK: - Privacy Mode
    
    // Format currency with privacy mode support
    private func formatCurrencyWithPrivacy(_ value: Double) -> String {
        if privacyModeEnabled {
            return "••••••"
        } else {
            return viewModel.formatCurrency(value)
        }
    }
    
    // Toggle privacy mode with haptic feedback
    private func togglePrivacyMode() {
        // Toggle the mode
        privacyModeEnabled.toggle()
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

