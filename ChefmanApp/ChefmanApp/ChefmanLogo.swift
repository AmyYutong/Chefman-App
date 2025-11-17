import SwiftUI

// MARK: - Chefman Logo Component
struct ChefmanLogo: View {
    let size: CGFloat
    
    init(size: CGFloat = 120) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Black background with subtle gradient
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
            
            // Inner circle for depth
            Circle()
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
                .frame(width: size * 0.9, height: size * 0.9)
            
            // Green CHEF text with enhanced styling
            VStack(spacing: -2) {
                Text("CHEF")
                    .font(.system(size: size * 0.22, weight: .black, design: .rounded))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.3), radius: 2, x: 0, y: 1)
                
                // Small decorative line
                Rectangle()
                    .fill(Color.green)
                    .frame(width: size * 0.3, height: 2)
                    .cornerRadius(1)
            }
        }
    }
}

// MARK: - Logo Preview
#Preview {
    VStack(spacing: 20) {
        ChefmanLogo(size: 80)
        ChefmanLogo(size: 120)
        ChefmanLogo(size: 160)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
