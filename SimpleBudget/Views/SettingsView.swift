import SwiftUI

public struct SettingsView: View {
    @AppStorage("currencyCode") private var currencyCode: String = "USD"
    @AppStorage("startDayOfMonth") private var startDayOfMonth: Int = 1
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled: Bool = false
    @AppStorage("useBiometricAuth") private var useBiometricAuth: Bool = false
    
    private let currencyOptions = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD"]
    @State private var showingExportSheet = false
    @State private var managingCategories = false
    @State private var appVersion = "1.0.0"
    
    public var body: some View {
        NavigationStack {
            Form {
                // Currency settings
                Section(header: Text("Currency")) {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(currencyOptions, id: \.self) { code in
                            Text(currencyName(for: code))
                                .tag(code)
                        }
                    }
                }
                
                // Budget settings
                Section(header: Text("Budget")) {
                    Stepper(value: $startDayOfMonth, in: 1...28) {
                        HStack {
                            Text("Budget start day")
                            Spacer()
                            Text("\(startDayOfMonth)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink("Manage Categories") {
                        Text("Category management would go here")
                    }
                }
                
                // App settings
                Section(header: Text("App Settings")) {
                    Toggle("Dark Mode", isOn: $isDarkModeEnabled)
                    
                    Toggle("Use Face ID/Touch ID", isOn: $useBiometricAuth)
                }
                
                // Data management
                Section(header: Text("Data")) {
                    Button("Export Data") {
                        showingExportSheet = true
                    }
                    
                    Button("Clear All Data") {
                        // Would show confirmation dialog
                    }
                    .foregroundColor(.red)
                }
                
                // About
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func currencyName(for code: String) -> String {
        let locale = Locale(identifier: "en_US")
        if let currencyName = locale.localizedString(forCurrencyCode: code) {
            return "\(code) - \(currencyName)"
        } else {
            return code
        }
    }
}

#Preview {
    SettingsView()
}

