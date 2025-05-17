import SwiftUI

@main
struct SimpleBudgetApp: App {
    // Create persistence controller
    let persistenceController = PersistenceController.shared
    
    // Scene phase monitoring
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive {
                persistenceController.save()
            }
        }
    }
}

