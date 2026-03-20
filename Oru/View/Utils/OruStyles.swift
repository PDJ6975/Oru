import SwiftUI

// MARK: - Colors

extension Color {
    static let oruPrimary = Color.cyan
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

// MARK: - Input Big

private struct OruInputBigModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 22, weight: .light, design: .rounded))
            .tracking(0.8)
    }
}

// MARK: - Input Medium

private struct OruInputMediumModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17, weight: .regular, design: .rounded))
    }
}

// MARK: - Input Small

private struct OruInputSmallModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .regular, design: .rounded))
    }
}

// MARK: - Pill Circle

private struct OruPillCircleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .semibold, design: .rounded))
    }
}

// MARK: - Text Primary

private struct OruTextPrimaryModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16, weight: .medium, design: .rounded))
    }
}

// MARK: - Text Secondary

private struct OruTextSecondaryModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .regular, design: .rounded))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Tip (consejos con icono)

private struct OruTipModifier: ViewModifier {
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

// MARK: - Navigation Icon Secondary

private struct OruNavigationIconSecondaryModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.secondary)
            .frame(width: 30, height: 30)
    }
}

// MARK: - Consolidation Progress

private struct ConsolidationProgressModifier: ViewModifier {
    let progress: Double
    let leadingInset: CGFloat

    func body(content: Content) -> some View {
        content
            .background(alignment: .leading) {
                GeometryReader { geo in
                    let clampedProgress = min(max(progress, 0), 1)
                    let trailingMargin: CGFloat = 8
                    let availableWidth = geo.size.width - leadingInset - trailingMargin

                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: clampedProgress >= 1
                                    ? [Color.oruPrimary.opacity(0.15)]
                                    : [Color.oruPrimary.opacity(0.15), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: availableWidth * clampedProgress)
                        .padding(.vertical, -4)
                        .padding(.leading, leadingInset)
                }
            }
            .transaction { $0.animation = nil }
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

    func oruInputBig() -> some View {
        modifier(OruInputBigModifier())
    }

    func oruInputMedium() -> some View {
        modifier(OruInputMediumModifier())
    }

    func oruInputSmall() -> some View {
        modifier(OruInputSmallModifier())
    }

    func oruPillCircle() -> some View {
        modifier(OruPillCircleModifier())
    }

    func oruTextPrimary() -> some View {
        modifier(OruTextPrimaryModifier())
    }

    func oruTextSecondary() -> some View {
        modifier(OruTextSecondaryModifier())
    }

    func oruTip() -> some View {
        modifier(OruTipModifier())
    }

    func oruAccent() -> some View {
        modifier(OruAccentModifier())
    }

    func oruNavigationIconSecondary() -> some View {
        modifier(OruNavigationIconSecondaryModifier())
    }

    func oruPulse(scale: CGFloat = 1.25, action: @escaping () -> Void) -> some View {
        modifier(OruPulseModifier(scale: scale, action: action))
    }

    func oruConsolidationProgress(_ progress: Double, leadingInset: CGFloat = 0) -> some View {
        modifier(ConsolidationProgressModifier(progress: progress, leadingInset: leadingInset))
    }
}
