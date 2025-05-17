import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddTransaction = false
    @State private var showingSetBudget = false
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
            .sheet(isPresented: $showingSetBudget) {
                AddBudgetView()
                    .environment(\.managedObjectContext, viewContext)
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
                
                if !accounts.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text("8.5%")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
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
                        
                        Text(formatCurrencyWithPrivacy(0))
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
                            showingSetBudget = true
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
                    showingSetBudget = true
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
                    showingSetBudget = true
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
        // For now we just use account balances since we don't track debts separately
        return totalAssets
    }
    
    private var totalAssets: Double {
        // Sum of all positive account balances
        accounts.reduce(0) { $0 + max($1.balance, 0) }
    }
    
    private var totalAccountsBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
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

