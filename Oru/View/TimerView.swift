import SwiftUI

struct TimerView: View {

    @State private var selectedMinutes = 25
    @State private var isEditing = false

    private static let stepMinutes = 5
    private static let minMinutes = 5
    private static let maxMinutes = 60

    var body: some View {
        VStack(spacing: 0) {
            timerDisplay

            editButton

            Spacer()
        }
        .padding(.top, 80)
        .tint(.secondary)
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        HStack(spacing: 15) {
            stepButton(systemName: "minus", enabled: canDecrease) {
                selectedMinutes -= Self.stepMinutes
            }

            Text(formattedTime)
                .font(.system(size: 65, weight: .light, design: .rounded))
                .tracking(2)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            stepButton(systemName: "plus", enabled: canIncrease) {
                selectedMinutes += Self.stepMinutes
            }
        }
    }

    private var editButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditing.toggle()
            }
        } label: {
            Image(systemName: isEditing ? "checkmark" : "pencil")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.secondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private func stepButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        if isEditing {
            Button(action: action) {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(enabled ? .secondary : .quaternary)
            }
            .disabled(!enabled)
            .transition(.opacity.combined(with: .scale))
        }
    }

    private var canDecrease: Bool { selectedMinutes > Self.minMinutes }
    private var canIncrease: Bool { selectedMinutes < Self.maxMinutes }

    private var formattedTime: String {
        String(format: "%02d:%02d", selectedMinutes, 0)
    }
}

#Preview {
    TimerView()
}
