import SwiftUI
import SwiftData

struct HabitListView: View {

    var viewModel: HabitViewModel
    @State private var showCreateForm = false
    @State private var habitToEdit: Habit?
    @State private var habitToDelete: Habit?

    @Query(sort: \Habit.creationDate, order: .reverse)
    private var allHabits: [Habit]

    private var todayHabits: [Habit] {
        let today = viewModel.currentWeekday()
        return allHabits.filter { $0.status != .archived && $0.scheduledDays.contains(today) }
    }

    private var otherHabits: [Habit] {
        let today = viewModel.currentWeekday()
        return allHabits.filter { $0.status != .archived && !$0.scheduledDays.contains(today) }
    }

    private func todayFormatted() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        return formatter.string(from: .now).capitalized
    }

    private var hasNoHabits: Bool {
        todayHabits.isEmpty && otherHabits.isEmpty
    }

    var body: some View {
        Group {
            if hasNoHabits {
                emptyStateView
            } else {
                habitListView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(todayFormatted())
                    .oruAccent()
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateForm = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .sheet(isPresented: $showCreateForm) {
            HabitFormView(viewModel: viewModel)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $habitToEdit) { habit in
            HabitFormView(viewModel: viewModel, habitToEdit: habit)
                .presentationDragIndicator(.visible)
        }
        .alert(
            "Eliminar hábito",
            isPresented: Binding(
                get: { habitToDelete != nil },
                set: { if !$0 { habitToDelete = nil } }
            )
        ) {
            Button("Eliminar", role: .destructive) {
                if let habit = habitToDelete {
                    viewModel.deleteHabit(habit)
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Se eliminará el hábito y todo su historial. Esta acción no se puede deshacer.")
        }
        .alert(
            "¡Hábito consolidado! 🎉",
            isPresented: Binding(
                get: { viewModel.consolidatedHabit != nil },
                set: { if !$0 { viewModel.consolidatedHabit = nil } }
            )
        ) {
            Button("Aceptar") {
                viewModel.consolidatedHabit = nil
            }
        } message: {
            if let habit = viewModel.consolidatedHabit {
                let intro = "¡Enhorabuena! \(habit.name) ya es parte de ti."
                let detail = "Puedes mantenerlo en tu día a día o, cuando sientas"
                    + " que ya no necesitas registrarlo,"
                    + " deslízalo para archivarlo en tus estadísticas."
                Text("\(intro) \(detail)")
            }
        }
    }

    private var emptyStateView: some View {
        VStack {
            Spacer()

            Text("Empieza a construir tu rutina creando tu primer hábito.")
                .oruBody()
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(32)
    }

    private var habitListView: some View {
        List {
            Section("Para hoy") {
                if todayHabits.isEmpty {
                    todayEmptyRow
                } else {
                    ForEach(todayHabits) { habit in
                        TodayHabitRow(habit: habit, viewModel: viewModel)
                            .oruConsolidationCard(progress: viewModel.consolidationProgress(for: habit))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    habitToDelete = habit
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                                .tint(.red)
                                Button {
                                    habitToEdit = habit
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                .tint(.oruPrimary)
                                if habit.status == .consolidated {
                                    Button {
                                        viewModel.archiveHabit(habit)
                                    } label: {
                                        Label("Archivar", systemImage: "archivebox")
                                    }
                                    .tint(.orange)
                                }
                            }
                    }
                }
            }

            if !otherHabits.isEmpty {
                Section("En pausa") {
                    ForEach(otherHabits) { habit in
                        HabitRow(habit: habit, today: viewModel.currentWeekday())
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    habitToDelete = habit
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                                .tint(.red)
                                Button {
                                    habitToEdit = habit
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                .tint(.oruPrimary)
                            }
                    }
                }
            }
        }
        .listRowSpacing(10)
        .scrollDismissesKeyboard(.immediately)
    }

    private var todayEmptyRow: some View {
        HStack(spacing: 10) {
            Text("😌")
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 4) {
                Text("Día de descanso")
                    .oruTextPrimary()

                Text("Recarga energía y disfruta de tu tiempo.")
                    .oruTextSecondary()
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - TodayHabitRow

private struct TodayHabitRow: View {

    let habit: Habit
    var viewModel: HabitViewModel

    var body: some View {
        switch habit.type {
        case .boolean:
            BooleanHabitRow(habit: habit, viewModel: viewModel)
        case .quantity:
            QuantityHabitRow(habit: habit, viewModel: viewModel)
        }
    }
}

// MARK: - BooleanHabitRow

private struct BooleanHabitRow: View {

    let habit: Habit
    var viewModel: HabitViewModel

    private var isCompleted: Bool {
        viewModel.todayCompliance(for: habit)?.completed ?? false
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.toggleBoolean(for: habit)
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundStyle(isCompleted ? Color.oruPrimary.opacity(0.8) : Color.secondary.opacity(0.35))
                    .contentTransition(.symbolEffect(.replace))
                    .sensoryFeedback(.success, trigger: isCompleted)
            }
            .buttonStyle(.plain)
            .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(habit.icon)
                        .font(.system(size: 16))

                    Text(habit.name)
                        .oruTextPrimary()
                        .lineLimit(1)
                        .strikethrough(isCompleted)
                        .foregroundStyle(isCompleted ? .secondary : .primary)
                }

                if let note = habit.note, !note.isEmpty {
                    Text(note)
                        .oruTextSecondary()
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - QuantityHabitRow

private struct QuantityHabitRow: View {

    let habit: Habit
    var viewModel: HabitViewModel

    // Decide si el campo de texto para escribir cantidad se muestra
    @State private var isEntering = false
    // Guarda temporalmente lo que escribe el usuario en el teclado
    @State private var inputText = ""
    // Controla el teclado, al pulsar "+" se abre
    @FocusState private var isFocused: Bool

    private var todayCompliance: Compliance? {
        viewModel.todayCompliance(for: habit)
    }

    private var hasRecordedAmount: Bool {
        todayCompliance?.recordedAmount != nil && todayCompliance?.recordedAmount != 0
    }

    private var isCompleted: Bool {
        todayCompliance?.completed ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    if isEntering {
                        save()
                    } else {
                        inputText = (todayCompliance?.recordedAmount ?? 0).formatted
                        isEntering = true
                    }
                } label: {
                    Image(systemName: isEntering
                          ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(
                            isEntering || hasRecordedAmount
                                ? Color.oruPrimary.opacity(0.8)
                                : Color.secondary.opacity(0.35)
                        )
                        .contentTransition(.symbolEffect(.replace))
                        .sensoryFeedback(.success, trigger: hasRecordedAmount)
                }
                .buttonStyle(.plain)
                .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(habit.icon)
                            .font(.system(size: 16))

                        Text(habit.name)
                            .oruTextPrimary()
                            .lineLimit(1)
                            .strikethrough(isCompleted)
                            .foregroundStyle(isCompleted ? .secondary : .primary)
                    }

                    if let note = habit.note, !note.isEmpty {
                        Text(note)
                            .oruTextSecondary()
                            .lineLimit(1)
                    }
                }

                Spacer()

                progressLabel
            }
            .padding(.vertical, 4)

            if isEntering {
                HStack(spacing: 8) {
                    TextField("0", text: $inputText)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .oruTextPrimary()
                        .onChange(of: inputText) { _, newValue in
                            inputText = String(newValue.prefix(Habit.maxGoalLength))
                        }

                    if let unit = habit.unit {
                        Text(unit.name)
                            .oruTextSecondary()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: .rect(cornerRadius: 10))
                .padding(.leading, 40)
                .task { isFocused = true }
            }
        }
        .animation(.easeOut(duration: 0.2), value: isEntering)
        .onChange(of: isFocused) { _, focused in
            if !focused && isEntering { isEntering = false }
        }
    }

    private func save() {
        let normalized = inputText.replacingOccurrences(of: ",", with: ".")
        let value = Double(normalized) ?? 0
        viewModel.recordAmount(value, for: habit)
        isEntering = false
        isFocused = false
    }

    private var progressLabel: some View {
        let amount = (todayCompliance?.recordedAmount ?? 0).formatted
        let text: String

        if let goal = habit.dailyGoal {
            let suffix = habit.unit.map { " \($0.name)" } ?? ""
            text = "\(amount) / \(goal.formatted)\(suffix)"
        } else {
            text = habit.unit.map { "\(amount) \($0.name)" } ?? amount
        }

        return Text(text)
            .oruPillCircle()
            .foregroundStyle(hasRecordedAmount
                ? Color.oruPrimary.opacity(0.8)
                : Color.secondary.opacity(0.35))
    }
}

// MARK: - HabitRow (En pausa)

private struct HabitRow: View {

    let habit: Habit
    let today: Habit.Weekday

    var body: some View {
        HStack(spacing: 8) {
            Text(habit.icon)
                .font(.system(size: 19))
                .frame(width: 28)

            Text(habit.name)
                .oruTextPrimary()
                .lineLimit(1)

            Spacer()

            HStack(spacing: 6) {
                ForEach(Habit.Weekday.allCases, id: \.self) { day in
                    Text(day.shortLabel)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(dayColor(day: day))
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func dayColor(day: Habit.Weekday) -> Color {
        guard habit.scheduledDays.contains(day) else {
            return .secondary.opacity(0.3)
        }
        return day == today ? .oruPrimary : .primary
    }
}

// MARK: - Weekday Short Label

extension Habit.Weekday {
    var shortLabel: String {
        switch self {
        case .monday: "L"
        case .tuesday: "M"
        case .wednesday: "X"
        case .thursday: "J"
        case .friday: "V"
        case .saturday: "S"
        case .sunday: "D"
        }
    }
}

// MARK: - Preview

#Preview(traits: .sampleData) {
    @Previewable @Environment(\.modelContext) var context
    NavigationStack {
        HabitListView(viewModel: HabitViewModel(repository: HabitRepository(modelContext: context)))
    }
}
