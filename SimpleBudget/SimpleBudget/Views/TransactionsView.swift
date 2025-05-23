import SwiftUI
import CoreData

public struct TransactionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<Transaction>
    
    @State private var isAddingTransaction = false
    @State private var showFilterOptions = false
    @State private var selectedMonth: Date = Date()
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(UIColor.systemGray5)
                    .ignoresSafeArea()
                
                List {
                // Styling will be applied to list items individually
                if filteredTransactions.isEmpty {
                    ContentUnavailableView("No Transactions", systemImage: "list.bullet.clipboard", description: Text("Add transactions to start tracking your expenses"))
                } else {
                    ForEach(transactionsByDate.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(formatDate(date))) {
                            ForEach(transactionsByDate[date] ?? []) { transaction in
                                TransactionRowView(transaction: transaction)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            deleteTransaction(transaction)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            // Edit transaction
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                            }
                        }
                    }
                }
                }
                .scrollContentBackground(.hidden)  // Important: This hides the list's default background
            }
            // No need for extra bottom padding since ContentView handles it
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showFilterOptions = true
                    } label: {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(monthYearFormatter.string(from: selectedMonth))
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isAddingTransaction = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        exportTransactions()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $isAddingTransaction) {
                AddTransactionView()
            }
            .confirmationDialog("Filter Transactions", isPresented: $showFilterOptions) {
                Button("This Month") { selectedMonth = Date() }
                Button("Last Month") { 
                    selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                }
                Button("Custom Date...") {
                    // Would show month picker
                }
                Button("Show All", role: .cancel) {
                    // Reset filters
                }
            }
        }
    }
    
    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let startOfSelectedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfSelectedMonth)!
        
        return transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= startOfSelectedMonth && date < startOfNextMonth
        }
    }
    
    private var transactionsByDate: [Date: [Transaction]] {
        var result: [Date: [Transaction]] = [:]
        
        for transaction in filteredTransactions {
            guard let date = transaction.date else { continue }
            let day = Calendar.current.startOfDay(for: date)
            
            if result[day] == nil {
                result[day] = [transaction]
            } else {
                result[day]?.append(transaction)
            }
        }
        
        return result
    }
    
    private func deleteTransaction(_ transaction: Transaction) {
        viewContext.delete(transaction)
        
        do {
            try viewContext.save()
        } catch {
            // Handle the error
            print("Error deleting transaction: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    private func generateCSV() -> String {
        let headers = "Date,Title,Amount,Category,Account,Notes\n"
        let rows = filteredTransactions.map { transaction in
            let date = transaction.date?.formatted(date: .numeric, time: .omitted) ?? ""
            let title = transaction.title ?? ""
            let amount = String(format: "%.2f", transaction.amount)
            let category = transaction.category ?? ""
            let account = transaction.account?.name ?? ""
            let notes = transaction.notes ?? ""
            return "\(date),\"\(title)\",\(amount),\"\(category)\",\"\(account)\",\"\(notes)\""
        }.joined(separator: "\n")
        return headers + rows
    }
    
    private func exportTransactions() {
        let csvContent = generateCSV()
        if let csvData = csvContent.data(using: .utf8) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let fileName = "transactions_\(dateFormatter.string(from: Date())).csv"
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            do {
                try csvData.write(to: tempURL)
                let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    activityVC.popoverPresentationController?.sourceView = rootVC.view
                    rootVC.present(activityVC, animated: true)
                }
            } catch {
                print("Error exporting transactions: \(error)")
            }
        }
    }
}
