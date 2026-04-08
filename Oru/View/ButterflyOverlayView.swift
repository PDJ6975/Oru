import SwiftUI

// MARK: - Slot (posición fija que cicla su mariposa)

private struct ButterflySlotView: View {
    let position: CGPoint
    let initialDelay: Double

    private static let imageNames = [
        "mariposa_rosa", "mariposa_amarilla",
        "mariposa_verde", "maripos_azul"
    ]

    @State private var imageName = "mariposa_rosa"
    @State private var opacity: Double = 0
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var size: CGFloat = 75

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .offset(offset)
            .position(position)
            .task { await cycle() }
    }

    private func cycle() async {
        try? await Task.sleep(for: .seconds(initialDelay))

        while !Task.isCancelled {
            imageName = Self.imageNames[Int.random(in: 0..<Self.imageNames.count)]
            size = .random(in: 75...90)
            offset = .zero
            rotation = 0

            let stay = Double.random(in: 10...14)
            let fade = 2.0

            withAnimation(.easeIn(duration: fade)) {
                opacity = Double.random(in: 0.45...0.65)
            }
            withAnimation(.easeInOut(duration: stay)) {
                offset = CGSize(width: .random(in: -20...20), height: .random(in: -25...25))
                rotation = .random(in: -12...12)
            }

            try? await Task.sleep(for: .seconds(stay - fade))
            withAnimation(.easeOut(duration: fade)) {
                opacity = 0
            }
            try? await Task.sleep(for: .seconds(fade))
        }
    }
}

// MARK: - Overlay

struct ButterflyOverlayView: View {
    // Posiciones fijas bien repartidas por la pantalla
    private static let slots: [(x: Double, y: Double)] = [
        (0, 0.25), (1, 0.20),
        (0, 0.65), (1, 0.40),
        (0, 0.85), (1, 0.75)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(Self.slots.enumerated()), id: \.offset) { idx, slot in
                ButterflySlotView(
                    position: CGPoint(x: slot.x * geo.size.width, y: slot.y * geo.size.height),
                    initialDelay: Double(idx) * 1.0
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
