import SwiftUI

struct FooterView: View {
    @Binding var selectedTab: Int
    
    // Standard height for the footer - can be used across the app for consistent padding
    static let height: CGFloat = 60
    
    var body: some View {
        HStack(spacing: 0) {
            // Dashboard
            Button {
                selectedTab = 0
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 0 ? "chart.pie.fill" : "chart.pie")
                        .font(.system(size: 20))
                    Text("Dashboard")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
            }
            .foregroundColor(selectedTab == 0 ? .blue : .gray)
            
            // Transactions
            Button {
                selectedTab = 1
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 1 ? "list.bullet.rectangle.fill" : "list.bullet.rectangle")
                        .font(.system(size: 20))
                    Text("Transactions")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
            }
            .foregroundColor(selectedTab == 1 ? .blue : .gray)
            
            // Settings
            Button {
                selectedTab = 2
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 2 ? "gear.circle.fill" : "gear.circle")
                        .font(.system(size: 20))
                    Text("Settings")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
            }
            .foregroundColor(selectedTab == 2 ? .blue : .gray)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .top
        )
    }
}

#Preview {
    FooterView(selectedTab: .constant(0))
}

