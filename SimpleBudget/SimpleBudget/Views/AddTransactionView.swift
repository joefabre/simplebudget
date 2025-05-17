import SwiftUI

public struct AddTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var category: String = "Uncategorized"
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var isExpense: Bool = true
    @State private var showingSuccessToast = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // Predefined categories
    private let categories = [
        "Food", "Transportation", "Housing", "Entertainment", 
        "Shopping", "Utilities", "Healthcare", "Education", 
        "Travel", "Personal", "Income", "Uncategorized"
    ]
    
    private var successToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                Text("\(isExpense ? "Expense" : "Income") saved")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(20)
            .shadow(radius: 5)
            .padding(.bottom, 32)  // Increased bottom padding
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .ignoresSafeArea(edges: .bottom)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Transaction type
                Section {
                    Picker("Transaction Type", selection: $isExpense) {
                        Text("Expense").tag(true)
                        Text("Income").tag(false)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Transaction Type")
                }
                
                // Title
                Section {
                    TextField("Title", text: $title)
                } header: {
                    Text("Title")
                }
                
                // Amount
                Section {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Amount")
                }
                
                // Category
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                } header: {
                    Text("Category")
                }
                
                // Date
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                } header: {
                    Text("Date")
                }
                
                // Notes
                Section {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(amount.isEmpty || Double(amount) == 0 || title.isEmpty)
                }
            }
        }
        .overlay(
            successToast
                .opacity(showingSuccessToast ? 1 : 0)
                .animation(.spring(), value: showingSuccessToast)
        )
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let transaction = Transaction(context: viewContext)
        transaction.id = UUID()
        transaction.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        transaction.amount = isExpense ? amountValue : -amountValue
        transaction.category = category
        transaction.date = date
        transaction.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        transaction.type = isExpense ? "expense" : "income"
        transaction.createdAt = Date()
        
        do {
            try viewContext.save()
            
            // Provide haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Show success toast
            withAnimation(.spring()) {
                showingSuccessToast = true
            }
            
            // Dismiss after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {  // Increased from 0.5 to 1.5
                dismiss()
            }
        } catch {
            // Show error alert
            errorMessage = "Error saving transaction: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
}

#Preview {
    AddTransactionView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

