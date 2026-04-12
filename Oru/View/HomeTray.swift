import SwiftUI

// MARK: - HomeTrayDetent

enum HomeTrayDetent: CaseIterable {
    case peek, full
    
    // % de área útil a utilizar en cada modo
    var heightFraction: CGFloat {
        switch self {
        case .peek: 0.38
        case .full: 0.92
        }
    }
    
    // el tamaño útil relativo al modo por el área disponible
    func height(in container: CGFloat) -> CGFloat {
        container * heightFraction
    }
}

// MARK: - HomeTray

// Bandeja inferior anclada al bottom con 2 puntos de anclaje (peek / full).
// La zona arrastrable combina el handle y el `header` (fijo, no scrollea)
struct HomeTray<Header: View, Content: View>: View {

    @Binding var detent: HomeTrayDetent
    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content

    @State private var dragOffset: CGFloat = 0 // refleja el desplazamiento en vivo del usuario mientras arrastra la bandeja por el handle

    private let overscrollThreshold: CGFloat = 60
    private let snapAnimation: Animation = .smooth(duration: 0.35)

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let container = geo.size.height // nos da la altura real disponible en puntos del espacio dado por GeometryReader, que es la pantalla menos nav bar y tab bar
            let baseHeight = detent.height(in: container)
            let minHeight = HomeTrayDetent.peek.height(in: container)
            let maxHeight = HomeTrayDetent.full.height(in: container)
            let liveHeight = max(minHeight, min(maxHeight, baseHeight - dragOffset))

            VStack(spacing: 0) {
                dragHeader(baseHeight: baseHeight, container: container)
                listContent
            }
            .frame(maxWidth: .infinity)
            .frame(height: liveHeight)
            .background(trayBackground)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .animation(snapAnimation, value: detent)
        }
    }

    // MARK: - Drag Header (handle + header)

    private func dragHeader(baseHeight: CGFloat, container: CGFloat) -> some View {
        VStack(spacing: 0) {
            handleGrip
            header()
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .gesture(dragGesture(baseHeight: baseHeight, container: container))
        .onTapGesture { toggleDetent() }
    }

    private var handleGrip: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.35))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 8)
    }

    // MARK: - List Content

    private var listContent: some View {
        List {
            content()
        }
        .listRowSpacing(15)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { scroll in
            scroll.contentOffset.y
        } action: { _, newValue in
            guard detent == .full, newValue < -overscrollThreshold else { return }
            withAnimation(snapAnimation) {
                detent = .peek
            }
        }
    }

    // MARK: - Background

    private var trayBackground: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 28,
            topTrailingRadius: 28
        )
        .fill(.ultraThinMaterial)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Gestures

    private func dragGesture(baseHeight: CGFloat, container: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                let projected = baseHeight - value.predictedEndTranslation.height
                let target = nearestDetent(to: projected, in: container)
                withAnimation(snapAnimation) {
                    detent = target
                    dragOffset = 0
                }
            }
    }

    private func toggleDetent() {
        withAnimation(snapAnimation) {
            detent = detent == .peek ? .full : .peek
        }
    }

    // MARK: - Snap Helpers

    private func nearestDetent(to height: CGFloat, in container: CGFloat) -> HomeTrayDetent {
        HomeTrayDetent.allCases.min { lhs, rhs in
            abs(lhs.height(in: container) - height) < abs(rhs.height(in: container) - height)
        } ?? .peek
    }
}
