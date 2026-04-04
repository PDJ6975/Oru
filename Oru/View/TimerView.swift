import SwiftData
import SwiftUI

struct TimerView: View {

    @State var viewModel: TimerViewModel
    @State private var isEditing = false
    @State private var showCancelAlert = false
    @State private var showHabitInfo = false

    var body: some View {
        VStack(spacing: 0) {
            timerDisplay

            controls

            if viewModel.state == .idle {
                habitTrackingCard
                    .padding(.top, 40)
                    .padding(.horizontal, 24)

                notificationCard
                    .padding(.top, 40)
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
        .frame(maxHeight: .infinity, alignment: viewModel.state == .running ? .center : .top)
        .padding(.top, viewModel.state == .idle ? 80 : 0)
        .animation(.easeInOut(duration: 0.8), value: viewModel.state)
        .buttonStyle(.plain)
        .alert("¿Quieres acabar ya la sesión?", isPresented: $showCancelAlert) {
            Button("Finalizar", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.cancel()
                }
            }
            Button("Continuar", role: .cancel) { }
        }
        .task {
            viewModel.loadCompatibleHabits()
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

    // MARK: - Habit Tracking Card

    private var habitTrackingCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Toggle(isOn: $viewModel.trackHabit) {
                Text("Registrar tiempo de la sesión:")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Menu {
                    Button {
                        viewModel.selectedHabit = nil
                    } label: {
                        Text("Ninguno")
                    }
                    ForEach(viewModel.compatibleHabits) { habit in
                        Button {
                            viewModel.selectedHabit = habit
                        } label: {
                            Text("\(habit.icon) \(habit.name)")
                        }
                    }
                } label: {
                    HStack {
                        if let habit = viewModel.selectedHabit {
                            Text("\(habit.icon) \(habit.name)")
                                .oruTextPrimary()
                        } else {
                            Text("Selecciona uno de tus hábitos")
                                .oruInputSmall()
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!viewModel.trackHabit)
                .opacity(viewModel.trackHabit ? 1 : 0.4)

                Divider()
                    .frame(height: 28)

                Button { showHabitInfo.toggle() } label: {
                    Image(systemName: "questionmark")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.oruPrimary)
                        .padding(4)
                }
                .glassEffect(.regular.tint(.white), in: .circle)
                .popover(isPresented: $showHabitInfo, arrowEdge: .top) {
                    Text("💡Solo aparecerán hábitos activos de cantidad"
                         + " con unidad de tiempo (min,h).")
                        .oruTip()
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 260)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                }
            }
            .padding(10)
            .glassEffect(.regular, in: .rect(cornerRadius: 10))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    // MARK: - Notification Card

    private var notificationCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 20) {
                Text("No te olvides de las notificaciones")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)

                Text("Activa las notificaciones para maximizar la experiencia en la aplicación")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .lineSpacing(3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
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

// MARK: - Preview

private struct TimerPreview: View {
    @State private var viewModel: TimerViewModel

    let container: ModelContainer

    init() {
        let schema = Schema([
            User.self, Habit.self, Unit.self, Compliance.self,
            Origami.self, UserOrigami.self, OrigamiPhase.self, Quote.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: [config])
        self.container = container

        let context = container.mainContext
        let min = Unit(name: "min")
        context.insert(min)

        let meditar = Habit(
            icon: "🧘🏼", name: "Meditar", type: .quantity,
            scheduledDays: Habit.Weekday.allCases, dailyGoal: 15
        )
        meditar.unit = min
        context.insert(meditar)
        try? context.save()

        let repository = HabitRepository(modelContext: context)
        _viewModel = State(initialValue: TimerViewModel(repository: repository))
    }

    var body: some View {
        TimerView(viewModel: viewModel)
            .modelContainer(container)
    }
}

#Preview {
    TimerPreview()
}
