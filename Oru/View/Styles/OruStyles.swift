import SwiftUI

// MARK: - Colors

extension Color {
    static let oruPrimary = Color.indigo
    static let oruSecondary = Color.purple
    static let oruBackground = Color.indigo.opacity(0.2) // A establecer más adelante
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

// MARK: - Text (texto de elemento, como habit name)

private struct OruTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .medium, design: .rounded))
    }
}

// MARK: - Note (texto secundario pequeño, como habit note)

private struct OruNoteModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .regular, design: .rounded))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Accent

private struct OruAccentModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .medium, design: .serif))
            .italic()
            .tracking(0.8)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Pulse Animation

private struct OruPulseModifier: ViewModifier {
    let scale: CGFloat
    let action: () -> Void
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: isPressed)
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.15)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeIn(duration: 0.1)) {
                        isPressed = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        action()
                    }
                }
            }
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

    func oruText() -> some View {
        modifier(OruTextModifier())
    }

    func oruNote() -> some View {
        modifier(OruNoteModifier())
    }

    func oruAccent() -> some View {
        modifier(OruAccentModifier())
    }

    func oruPulse(scale: CGFloat = 1.25, action: @escaping () -> Void) -> some View {
        modifier(OruPulseModifier(scale: scale, action: action))
    }
}
