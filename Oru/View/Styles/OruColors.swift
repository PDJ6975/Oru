import SwiftUI

extension Color {
    static let oruPrimary = Color.indigo
    static let oruSecondary = Color.purple
}

extension LinearGradient {
    static let oruGradient = LinearGradient(
        colors: [.oruPrimary, .oruSecondary.opacity(0.9)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
