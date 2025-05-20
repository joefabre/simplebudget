
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

    private var goals: FetchRequest<SavingsGoal>
    private var goalsList: FetchedResults<SavingsGoal> {
        goals.wrappedValue
    }

    init() {
        goals = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoal.createdAt, ascending: false)],
            predicate: nil,
            animation: .default)
    }

    var body: some View {
        Group {
            if goalsList.isEmpty {
                EmptyStateView()
            } else {
                List {
                    Section {
                        Toggle("Show Completed Goals", isOn: $showCompletedGoals)
                        Toggle("Group by Account", isOn: $groupByAccount)
                    }
                    if groupByAccount {
                        ForEach(groupedGoals.keys.sorted(), id: \.self) { accountName in
                            Section(header: Text(accountName)) {
                                ForEach(groupedGoals[accountName] ?? []) { goal in
                                    GoalRow(goal: goal)
                                        .environment(\.managedObjectContext, viewContext)
                                }
                                .onDelete { indexSet in
                                    deleteGoals(from: groupedGoals[accountName] ?? [], at: indexSet)
                                }
                            }
                        }
                    } else {
                        Section {
                            ForEach(filteredGoals) { goal in
                                GoalRow(goal: goal)
                                    .environment(\.managedObjectContext, viewContext)
                            }
                            .onDelete(perform: deleteGoals)
                        }
                    }
                }
            }
        }
        .navigationTitle("Savings Goals")
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
            // To update sort, you must recreate the FetchRequest.
            // This is a limitation of FetchRequest in SwiftUI.
            // For a dynamic fetch, consider using @FetchRequest in a child view or use a ViewModel.
        }
    }

    private var filteredGoals: [SavingsGoal] {
        goalsList.filter { goal in
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
}

struct GoalCardView: View {
    let goal: SavingsGoal

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
            ProgressView(value: goal.progressRatio) {
                HStack {
                    Text(String(format: "$%.2f", (goal.currentAmount as? NSDecimalNumber)?.doubleValue ?? 0))
                    Text("of")
                    Text(String(format: "$%.2f", (goal.targetAmount as? NSDecimalNumber)?.doubleValue ?? 0))
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

#Preview {
    NavigationStack {
        SavingsGoalListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
