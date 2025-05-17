import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("selectedTab") private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background color - make it darker
            Color(UIColor.systemGray5)  // Darker than systemGray6
                .ignoresSafeArea()
            
            // Main content based on selected tab
            Group {
                switch selectedTab {
                case 0:
                    DashboardView()
                        .environment(\.managedObjectContext, viewContext)
                case 1:
                    TransactionsView()
                        .environment(\.managedObjectContext, viewContext)
                case 2:
                    SettingsView()
                        .environment(\.managedObjectContext, viewContext)
                default:
                    DashboardView()
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .padding(.bottom, FooterView.height)  // Space for footer using standard height
            
            // Custom footer with slightly different background
            FooterView(selectedTab: $selectedTab)
                .background(Color(UIColor.systemBackground).shadow(radius: 1))
        }
        .edgesIgnoringSafeArea(.bottom)  // Allow footer to extend to bottom edge
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
