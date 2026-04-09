import SwiftUI

struct WelcomeView: View {
    var onStart: () -> Void

    @State private var animateOrigamis = false

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {

            headerSection

            featuresSection
                .padding(.leading, 15)

            Spacer()

            startButton
        }
        .padding(32)
        .overlay(alignment: .bottom) {
            origamiSection
                .padding(.bottom, 150)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 2.5).delay(0.3)) {
                animateOrigamis = true
            }
        }
    }
}

// MARK: - Sections

private extension WelcomeView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Da forma a tu mejor versión")
                .oruTitle()

            Text("Cada día es una hoja en blanco. Descubre cómo tus pequeños esfuerzos crean grandes resultados:")
                .oruBody()
        }
    }

    var featuresSection: some View {
        VStack(alignment: .leading, spacing: 25) {
            FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Construye rutinas diarias.")
            FeatureRow(icon: "scope", text: "Enfoca tu tiempo.")
            FeatureRow(icon: "star", text: "Colecciona tus logros.")
        }
    }

    var origamiSection: some View {
        HStack {
            Spacer()
            Image("flor_fase5")
                .resizable()
                .scaledToFit()
                .frame(width: 220)
                .rotationEffect(.degrees(-40), anchor: .bottom)
                .offset(x: 120)
                .opacity(animateOrigamis ? 0.8 : 0)
        }
    }

    var startButton: some View {
        Button(action: onStart) {
            Text("Empezar ahora")
                .oruButton()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 14))
        .tint(.oruPrimary)
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
                .foregroundStyle(Color.oruPrimary)
                .frame(width: 24) // Para alinear las filas

            Text(text)
                .oruLabel()
        }
    }
}

#Preview(traits: .emptyContainer) {
    WelcomeView(onStart: {})
}
