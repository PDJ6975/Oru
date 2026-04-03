import SwiftUI

struct TimerView: View {

    @State private var viewModel = TimerViewModel()
    @State private var isEditing = false
    @State private var showCancelAlert = false

    var body: some View {
        VStack(spacing: 0) {
            timerDisplay

            controls

            Spacer()
        }
        .padding(.top, 80)
        .buttonStyle(.plain)
        .alert("¿Quieres acabar ya la sesión?", isPresented: $showCancelAlert) {
            Button("Finalizar", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.cancel()
                }
            }
            Button("Continuar", role: .cancel) { }
        }
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        HStack(spacing: 15) {
            stepButton(systemName: "minus", enabled: viewModel.canDecrease) {
                viewModel.selectedMinutes -= TimerViewModel.stepMinutes
            }

            timerText

            stepButton(systemName: "plus", enabled: viewModel.canIncrease) {
                viewModel.selectedMinutes += TimerViewModel.stepMinutes
            }
        }
    }

    @ViewBuilder
    private var timerText: some View {
        Group {
            if let interval = viewModel.timerInterval, viewModel.state == .running {
                Text(timerInterval: interval, countsDown: true, showsHours: false)
            } else {
                Text(formattedTime)
            }
        }
        .oruTimerDisplay()
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        if viewModel.state == .running {
            Button {
                showCancelAlert = true
            } label: {
                Image(systemName: "xmark")
                    .oruIconButton()
            }
            .padding(.top, 10)
            .transition(.opacity.combined(with: .scale))
        } else {
            HStack(spacing: 20) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing = false
                        viewModel.start()
                    }
                } label: {
                    Image(systemName: "play")
                        .oruIconButton()
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing.toggle()
                    }
                } label: {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                        .oruIconButton()
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .padding(.top, 10)
            .transition(.opacity)
        }
    }

    // MARK: - Step Buttons

    @ViewBuilder
    private func stepButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        if isEditing && viewModel.state == .idle {
            Button(action: action) {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(enabled ? .secondary : .quaternary)
            }
            .disabled(!enabled)
            .transition(.opacity.combined(with: .scale))
        }
    }

    private var formattedTime: String {
        String(format: "%02d:%02d", viewModel.selectedMinutes, 0)
    }
}

#Preview {
    TimerView()
}
