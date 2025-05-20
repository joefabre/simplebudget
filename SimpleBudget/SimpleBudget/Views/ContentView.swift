import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("selectedTab") private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(UIColor.systemGray5)
                .ignoresSafeArea()
            Group {
                switch selectedTab {
                case 0:
                    DashboardView()
                        .environment(\.managedObjectContext, viewContext)
                case 1:
                    TransactionsView()
                        .environment(\.managedObjectContext, viewContext)
                case 2:
                    SavingsGoalListView()                        .environment(\.managedObjectContext, viewContext)
                case 3:
                    SettingsView()
                        .environment(\.managedObjectContext, viewContext)
                default:
                    DashboardView()
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .padding(.bottom, FooterView.height)
            FooterView(selectedTab: $selectedTab)
                .background(Color(UIColor.systemBackground).shadow(radius: 1))
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
