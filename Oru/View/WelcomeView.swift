import SwiftUI

struct WelcomeView: View {
    var onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {

            headerSection

            featuresSection
                .padding(.leading, 15)

            Spacer()

            startButton
        }
        .padding(32)
    }
}

// MARK: - Sections

private extension WelcomeView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Da forma a tu mejor versión")
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.indigo, Color.purple.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                    )
                )

            Text("Cada día es una hoja en blanco. Descubre cómo tus pequeños esfuerzos crean grandes resultados:")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .tracking(0.8)
                .lineSpacing(3)
                .foregroundStyle(.secondary)
        }
    }

    var featuresSection: some View {
        VStack(alignment: .leading, spacing: 25) {
            FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Construye rutinas diarias.")
            FeatureRow(icon: "scope", text: "Enfoca tu tiempo.")
            FeatureRow(icon: "star", text: "Colecciona tus logros.")
        }
    }

    var startButton: some View {
        Button(action: onStart) {
            Text("Empezar ahora")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 14))
        .tint(.indigo)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .light))
                .foregroundStyle(Color.indigo)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    WelcomeView(onStart: {})
}
