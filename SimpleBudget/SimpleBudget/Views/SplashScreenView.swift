import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotation = 0.0
    @State private var showTagline = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                VStack(spacing: 20) {
                    // Budget icon with multiple elements
                    ZStack {
                        // Background circles
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 130, height: 130)
                        
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: 130, height: 130)
                        
                        // Multiple financial symbols
                        HStack(spacing: 0) {
                            
                            
                            Image(systemName: "dollarsign.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(rotation))
                            
                            
                        }
                    }
                    
                    // App title and subtitle
                    Text("JoeBudget")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("FABREulous Technology")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, -5)
                        
                    // Tagline appears after a short delay
                    if showTagline {
                        Text("Track accounts, budgets & more")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary.opacity(0.8))
                            .padding(.top, 8)
                            .transition(.opacity)
                    }
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                        self.rotation = 360
                    }
                    
                    // Show tagline after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation {
                            showTagline = true
                        }
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
            
            // Version number at bottom
            VStack {
                Spacer()
                Text("v1.0.0")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.bottom, 15)
            }
        }
    }
}

#Preview {
    SplashScreenView()
}

