import CoreData
import SwiftUI

struct SavingsGoalListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    enum SortOption: String, CaseIterable {
        case dateCreated = "Date Created"
        case progress = "Progress"
        case deadline = "Deadline"
        case remaining = "Remaining Amount"
    }

    @State private var selectedSort: SortOption = .dateCreated
    @State private var showingAddGoal = false
    @State private var showCompletedGoals = true
    @State private var groupByAccount = false
    @State private var refreshID = UUID()
    
    @FetchRequest private var goals: FetchedResults<SavingsGoal>
    
    init() {
        _goals = FetchRequest<SavingsGoal>(
            sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoal.createdAt, ascending: false)],
            animation: .default
        )
    }

    var body: some View {
        Group {
            if goals.isEmpty {
                EmptyStateView()
            } else {
                List {
                    Section {
                        Toggle("Show Completed Goals", isOn: $showCompletedGoals)
                        Toggle("Group by Account", isOn: $groupByAccount)
                    }
                    
                    if groupByAccount {
                        GroupedGoalsSection(
                            groupedGoals: groupedGoals,
                            viewContext: viewContext,
                            deleteGoals: deleteGoals(from:at:)
                        )
                    } else {
                        NonGroupedGoalsSection(
                            goals: filteredGoals,
                            viewContext: viewContext,
                            deleteGoals: deleteGoals(offsets:)
                        )
                    }
                }
            }
        }
        .id(refreshID)
        .navigationTitle("Savings Goals")
        .refreshable {
            refreshView()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshSavingsGoals"))) { _ in
            refreshView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddGoal = true
                } label: {
                    Label("Add Goal", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Picker("Sort By", selection: $selectedSort) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            SavingsGoalView()
                .environment(\.managedObjectContext, viewContext)
        }
        .onChange(of: selectedSort) { _ in
            updateSort()
        }
    }

    private var filteredGoals: [SavingsGoal] {
        goals.filter { goal in
            showCompletedGoals ? true : !goal.isComplete
        }
    }

    private var groupedGoals: [String: [SavingsGoal]] {
        Dictionary(grouping: filteredGoals) { goal in
            goal.account?.name ?? "Unlinked Goals"
        }
    }

    private func deleteGoals(from goals: [SavingsGoal], at offsets: IndexSet) {
        withAnimation {
            offsets.map { goals[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }

    private func deleteGoals(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredGoals[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
    
    private func updateSort() {
        withAnimation {
            goals.nsSortDescriptors = [
                selectedSort == .dateCreated ? NSSortDescriptor(keyPath: \SavingsGoal.createdAt, ascending: false) :
                selectedSort == .progress ? NSSortDescriptor(keyPath: \SavingsGoal.currentAmount, ascending: false) :
                selectedSort == .deadline ? NSSortDescriptor(keyPath: \SavingsGoal.deadline, ascending: true) :
                NSSortDescriptor(keyPath: \SavingsGoal.targetAmount, ascending: true)
            ]
            refreshID = UUID()
        }
    }
    
    private func refreshView() {
        // Refresh the view context first
        try? viewContext.refreshAllObjects()
        // Then trigger view update
        withAnimation {
            refreshID = UUID()
        }
    }
}

struct GoalCardView: View {
    let goal: SavingsGoal
    @Environment(\.managedObjectContext) private var viewContext

    private var progressRatio: Double {
        let targetDouble = (goal.targetAmount as? Decimal).map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0
        return targetDouble > 0 ? goal.currentAmount / targetDouble : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.name ?? "")
                    .font(.headline)
                Spacer()
                if let deadline = goal.deadline {
                    HStack(spacing: 4) {
                        if goal.isPastDeadline {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        Text(deadline, style: .date)
                            .font(.caption)
                            .foregroundColor(goal.isPastDeadline ? .red : .secondary)
                    }
                }
            }
            ProgressView(value: progressRatio) {
                HStack {
                    Text(String(format: "$%.2f", goal.currentAmount))
                    Text("of")
                    Text(String(format: "$%.2f", (goal.targetAmount as? Decimal).map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0))
                }
                .font(.caption)
            }
            .tint(goal.isComplete ? .green : .blue)
            HStack {
                if let account = goal.account {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.secondary)
                        Text(account.name ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if let contribution = goal.requiredMonthlyContribution {
                    Text("Monthly: $\(String(format: "%.2f", contribution))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(goal.isComplete ? 0.8 : 1.0)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("No Savings Goals Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Tap the + button to create your first savings goal")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct GoalRow: View {
    let goal: SavingsGoal
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationLink {
            SavingsGoalView(goal: goal)
                .environment(\.managedObjectContext, viewContext)
        } label: {
            GoalCardView(goal: goal)
        }
        .listRowBackground(
            goal.isComplete ? Color(.systemBackground).opacity(0.6) :
            goal.isPastDeadline ? Color(.systemPink).opacity(0.1) :
            Color(.systemBackground)
        )
    }
}

private struct GroupedGoalsSection: View {
    let groupedGoals: [String: [SavingsGoal]]
    let viewContext: NSManagedObjectContext
    let deleteGoals: ([SavingsGoal], IndexSet) -> Void
    
    var body: some View {
        ForEach(groupedGoals.keys.sorted(), id: \.self) { accountName in
            Section(header: Text(accountName)) {
                ForEach(groupedGoals[accountName] ?? []) { goal in
                    GoalRow(goal: goal)
                        .environment(\.managedObjectContext, viewContext)
                }
                .onDelete { indexSet in
                    deleteGoals(groupedGoals[accountName] ?? [], indexSet)
                }
            }
        }
    }
}

private struct NonGroupedGoalsSection: View {
    let goals: [SavingsGoal]
    let viewContext: NSManagedObjectContext
    let deleteGoals: (IndexSet) -> Void
    
    var body: some View {
        Section {
            ForEach(goals) { goal in
                GoalRow(goal: goal)
                    .environment(\.managedObjectContext, viewContext)
            }
            .onDelete(perform: deleteGoals)
        }
    }
}

#Preview {
    NavigationStack {
        SavingsGoalListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
