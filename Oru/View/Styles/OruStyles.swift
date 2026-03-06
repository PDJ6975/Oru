import SwiftUI

// MARK: - Colors

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

// MARK: - Title

private struct OruTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 26, weight: .medium, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(Color.oruPrimary)
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

// MARK: - Label

private struct OruLabelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Button

private struct OruButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .semibold, design: .rounded))
    }
}

// MARK: - Input

private struct OruInputModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17, weight: .regular, design: .rounded))
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

    func oruLabel() -> some View {
        modifier(OruLabelModifier())
    }

    func oruButton() -> some View {
        modifier(OruButtonModifier())
    }

    func oruInput() -> some View {
        modifier(OruInputModifier())
    }
}
