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
    var habitToEdit: Habit?
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
    @State private var isSaving = false
    @State private var units: [Unit] = []
    @State private var showUnitManagement = false

    private var isEditing: Bool { habitToEdit != nil }

    @FocusState private var focusedField: Field?

    private enum Field {
        case emoji, name, goal, note
    }

    private var isValid: Bool {
        let normalized = dailyGoal.replacingOccurrences(of: ",", with: ".")
        let goal = Double(normalized)
        return viewModel.isValidHabit(
            name: name,
            selectedDays: selectedDays,
            type: habitType,
            dailyGoal: goal
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                iconAndNameSection
                    .padding(.top, 16)
                daysSection
                typeSection
                if habitType == .quantity {
                    goalSection
                        .transition(.blurReplace)
                }
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
        .task {
            units = viewModel.fetchUnits()
            let defaultUnit = units.first { $0.name == Unit.defaultName }
            if let habit = habitToEdit {
                icon = habit.icon
                name = habit.name
                selectedDays = Set(habit.scheduledDays)
                habitType = habit.type
                if let goal = habit.dailyGoal {
                    dailyGoal = goal.formatted
                }
                selectedUnit = habit.unit ?? defaultUnit
                note = habit.note ?? ""
            } else {
                selectedUnit = defaultUnit
            }
        }
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
        DaysSectionView(selectedDays: $selectedDays)
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
            .onChange(of: habitType) { _, newValue in
                if newValue == .boolean {
                    dailyGoal = ""
                    selectedUnit = nil
                } else {
                    selectedUnit = units.first { $0.name == Unit.defaultName }
                }
            }
        }
        .animation(.smooth, value: habitType)
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

            Divider()

            Button {
                showUnitManagement = true
            } label: {
                Label("Añadir nueva medida", systemImage: "plus.circle.dashed")
            }
        } label: {
            HStack(spacing: 2) {
                Text(selectedUnit?.name ?? "")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.oruPrimary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.oruPrimary)
            }
        }
        .sheet(isPresented: $showUnitManagement, onDismiss: refreshUnits) {
            UnitManagementView(viewModel: viewModel)
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
            saveHabit()
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
        .disabled(!isValid || isSaving)
        .sensoryFeedback(.success, trigger: confirmTap)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
    }

    // MARK: - Hint 66 días

    private var consolidationHint: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: isEditing ? "heart" : "lightbulb.max")
                .font(.system(size: 11))
                .foregroundStyle(Color.oruPrimary)
            Text(isEditing
                 ? "Moldea este hábito a tu propio ritmo."
                 : "Este hábito se considerará consolidado y parte de tu identidad tras cumplirlo por 66 días.")
                .oruTip()
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Refrescar unidades

    private func refreshUnits() {
        units = viewModel.fetchUnits()
        if let selected = selectedUnit,
           !units.contains(where: { $0.id == selected.id }) {
            selectedUnit = units.first { $0.name == Unit.defaultName }
        }
    }

    // MARK: - Guardar (creación o edición)

    private func saveHabit() {
        guard !isSaving else { return }
        isSaving = true

        let normalized = dailyGoal.replacingOccurrences(of: ",", with: ".")
        let goal = habitType == .quantity ? Double(normalized) : nil
        let unit = habitType == .quantity ? selectedUnit : nil
        let trimmedNote = note.trimmingCharacters(in: .whitespaces)
        let sortedDays = Array(selectedDays).sorted { $0.rawValue < $1.rawValue }

        if let habit = habitToEdit {
            let data = HabitViewModel.FormData(
                icon: icon,
                name: name.trimmingCharacters(in: .whitespaces),
                type: habitType,
                scheduledDays: sortedDays,
                dailyGoal: goal,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                unit: unit
            )
            viewModel.updateHabit(habit, with: data)
        } else {
            let habit = Habit(
                icon: icon,
                name: name.trimmingCharacters(in: .whitespaces),
                type: habitType,
                scheduledDays: sortedDays,
                dailyGoal: goal,
                note: trimmedNote.isEmpty ? nil : trimmedNote
            )
            habit.unit = unit
            viewModel.addHabit(habit)
        }

        if viewModel.lastError == nil {
            dismiss()
        } else {
            isSaving = false
        }
    }
}

// MARK: - Sección de días

private struct DaysSectionView: View {

    @Binding var selectedDays: Set<Habit.Weekday>

    var body: some View {
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

#Preview(traits: .sampleData) {
    @Previewable @Environment(\.modelContext) var context
    HabitFormView(viewModel: HabitViewModel(repository: HabitRepository(modelContext: context)))
}
