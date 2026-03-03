import SwiftUI

// MARK: - Title

private struct OruTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 26, weight: .medium, design: .rounded))
            .tracking(0.8)
    }
}

// MARK: - Body

private struct OruBodyModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .tracking(0.8)
            .lineSpacing(3)
            .foregroundStyle(.secondary)
    }
}

// MARK: - View Extension

extension View {
    func oruTitle() -> some View {
        modifier(OruTitleModifier())
    }

    func oruBody() -> some View {
        modifier(OruBodyModifier())
    }
}
