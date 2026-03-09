import SwiftUI
import SwiftData

// MARK: - Teclado de emojis (rawValue no público pero funcional y estable)

private extension UIKeyboardType {
    static let emoji = UIKeyboardType(rawValue: 124) ?? .default
}

private extension Character {
    var isEmoji: Bool {
        unicodeScalars.first?.properties.isEmoji == true
    }
}

struct HabitFormView: View {

    var viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Estado del formulario

    @State private var icon = "🌟"
    @State private var iconSelection: TextSelection?
    @State private var name = ""
    @State private var selectedDays: Set<Habit.Weekday> = Set(Habit.Weekday.allCases)
    @State private var habitType: Habit.HabitType = .boolean
    @State private var dailyGoal = ""
    @State private var selectedUnit: Unit?
    @State private var note = ""
    @State private var confirmTap = false
    @State private var isCreating = false
    @State private var units: [Unit] = []

    @FocusState private var focusedField: Field?

    private enum Field {
        case emoji, name, goal, note
    }

    private var isValid: Bool {
        viewModel.isValidHabit(name: name, selectedDays: selectedDays)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 1) {
                    header
                    iconAndNameSection
                }
                daysSection
                typeSection
                goalSection
                noteSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 18) {
                confirmButton
                consolidationHint
            }
        }
        .ignoresSafeArea(.keyboard)
        .onTapGesture { focusedField = nil }
        .sensoryFeedback(.selection, trigger: focusedField)
        .task { units = viewModel.fetchUnits() }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.lastError != nil },
                set: { if !$0 { viewModel.lastError = nil } }
            )
        ) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text(viewModel.lastError ?? "")
        }
    }

    // MARK: - Header con botón cerrar

    private var header: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .oruNavigationIconSecondary()
            }
            .glassEffect(.regular.interactive(), in: .circle)
        }
    }

    // MARK: - Icono + Nombre

    private var iconAndNameSection: some View {
        HStack(spacing: 14) {
            TextField("", text: $icon, selection: $iconSelection)
                .keyboardType(.emoji)
                .font(.system(size: 30))
                .multilineTextAlignment(.center)
                .tint(.clear)
                .frame(width: 46, height: 46)
                .focused($focusedField, equals: .emoji)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))
                .onChange(of: focusedField) { _, newValue in
                    if newValue == .emoji {
                        iconSelection = TextSelection(
                            range: icon.startIndex..<icon.endIndex
                        )
                    }
                }
                .onChange(of: icon) { _, newValue in
                    let emojis = newValue.filter { $0.isEmoji }
                    icon = emojis.isEmpty ? "🌟" : String(emojis.suffix(1))
                }

            TextField("Añade tu nuevo hábito...", text: $name)
                .oruInputBig()
                .focused($focusedField, equals: .name)
                .onChange(of: name) { _, newValue in
                    name = viewModel.clampName(newValue)
                }
        }
    }

    // MARK: - Días

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("¿Qué días quieres realizarlo?")
                .oruLabel()

            HStack(spacing: 8) {
                ForEach(Habit.Weekday.allCases, id: \.self) { day in
                    dayPill(day)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func dayPill(_ day: Habit.Weekday) -> some View {
        let isSelected = selectedDays.contains(day)
        return Button {
            if isSelected {
                selectedDays.remove(day)
            } else {
                selectedDays.insert(day)
            }
        } label: {
            Text(day.shortName)
                .oruPillCircle()
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 42, height: 42)
                .background(isSelected ? Color.oruPrimary : .clear, in: .circle)
        }
        .glassEffect(.regular, in: .circle)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: - Tipo de hábito

    private var typeSection: some View {
        HStack(spacing: 12) {
            Text("Selecciona un tipo:")
                .oruLabel()
                .fixedSize()

            Picker("Tipo", selection: $habitType) {
                Text("Sí/No").tag(Habit.HabitType.boolean)
                Text("Cantidad").tag(Habit.HabitType.quantity)
            }
            .pickerStyle(.segmented)
            .sensoryFeedback(.selection, trigger: habitType)
        }
    }

    // MARK: - Objetivo

    private var goalSection: some View {
        HStack(spacing: 12) {
            Text("¿Tienes un objetivo?:")
                .oruLabel()
                .fixedSize()

            HStack(spacing: 8) {
                TextField("Número/meta", text: $dailyGoal)
                    .keyboardType(.decimalPad)
                    .oruInputSmall()
                    .focused($focusedField, equals: .goal)
                    .onChange(of: dailyGoal) { _, newValue in
                        dailyGoal = viewModel.clampGoal(newValue)
                    }

                Spacer()

                unitPicker
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
        }
    }

    private var unitPicker: some View {
        Menu {
            ForEach(units, id: \.name) { unit in
                Button(unit.name) { selectedUnit = unit }
            }
        } label: {
            HStack(spacing: 2) {
                Text(selectedUnit?.name ?? "uds")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.oruPrimary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.oruPrimary)
            }
        }
    }

    // MARK: - Nota

    private var noteSection: some View {
        TextField(
            "Deja aquí una nota, estado de ánimo...",
            text: $note,
            axis: .vertical
        )
        .oruInputSmall()
        .focused($focusedField, equals: .note)
        .onChange(of: note) { _, newValue in
            note = viewModel.clampNote(newValue)
        }
        .padding(16)
        .frame(minHeight: 160, alignment: .topLeading)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Botón confirmar

    private var confirmButton: some View {
        Button {
            confirmTap.toggle()
            createHabit()
        } label: {
            Image(systemName: "checkmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: 150)
                .padding(.vertical, 16)
                .background(
                    isValid ? Color.oruPrimary : Color.oruPrimary.opacity(0.4),
                    in: .rect(cornerRadius: 16)
                )
        }
        .disabled(!isValid || isCreating)
        .sensoryFeedback(.success, trigger: confirmTap)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
    }

    // MARK: - Hint 66 días

    private var consolidationHint: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "lightbulb.max")
                .font(.system(size: 11))
                .foregroundStyle(Color.oruPrimary)
            Text("Este hábito se considerará consolidado y parte de tu identidad tras cumplirlo por 66 días.")
                .oruTip()
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Creación

    private func createHabit() {
        guard !isCreating else { return }
        isCreating = true

        let normalized = dailyGoal.replacingOccurrences(of: ",", with: ".")
        let goal = Double(normalized)
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)

        let habit = Habit(
            icon: icon,
            name: name.trimmingCharacters(in: .whitespaces),
            type: habitType,
            scheduledDays: Array(selectedDays).sorted { $0.rawValue < $1.rawValue },
            dailyGoal: goal,
            note: trimmedNote.isEmpty ? nil : trimmedNote
        )

        habit.unit = selectedUnit

        viewModel.addHabit(habit)

        if viewModel.lastError == nil {
            dismiss()
        } else {
            isCreating = false
        }
    }
}

// MARK: - Weekday nombres cortos para pills

extension Habit.Weekday {
    var shortName: String {
        switch self {
        case .monday: "lun"
        case .tuesday: "mar"
        case .wednesday: "mie"
        case .thursday: "jue"
        case .friday: "vie"
        case .saturday: "sab"
        case .sunday: "dom"
        }
    }
}

// MARK: - Preview

private struct HabitFormPreview: View {
    @State private var viewModel: HabitViewModel

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

        let minutos = Unit(name: "min")
        let km = Unit(name: "km")
        let paginas = Unit(name: "páginas")
        context.insert(minutos)
        context.insert(km)
        context.insert(paginas)

        let repository = HabitRepository(modelContext: context)
        _viewModel = State(initialValue: HabitViewModel(repository: repository))
    }

    var body: some View {
        HabitFormView(viewModel: viewModel)
            .modelContainer(container)
    }
}

#Preview {
    HabitFormPreview()
}
