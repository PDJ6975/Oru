import SwiftUI
import SwiftData

// MARK: - Teclado de emojis

private struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let field = EmojiOnlyField()
        field.text = text
        field.font = .systemFont(ofSize: 30)
        field.textAlignment = .center
        field.delegate = context.coordinator
        field.tintColor = .clear
        field.backgroundColor = .clear
        field.returnKeyType = .done
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        init(text: Binding<String>) { _text = text }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            if string.unicodeScalars.allSatisfy({ $0.properties.isEmoji && $0.properties.isEmojiPresentation })
                || string.isEmpty {
                if !string.isEmpty {
                    text = string
                    textField.resignFirstResponder()
                }
                return true
            }
            return false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }

    // Campo que siempre abre el teclado de emojis
    private final class EmojiOnlyField: UITextField {
        override var textInputMode: UITextInputMode? {
            UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
        }
    }
}

struct HabitFormView: View {

    var viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Estado del formulario

    @State private var icon = "🌟"
    @State private var name = ""
    @State private var selectedDays: Set<Habit.Weekday> = Set(Habit.Weekday.allCases)
    @State private var habitType: Habit.HabitType = .boolean
    @State private var dailyGoal = ""
    @State private var selectedUnit: Unit?
    @State private var note = ""
    @State private var confirmTap = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case name, goal, note
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedDays.isEmpty
    }

    private var availableUnits: [Unit] {
        viewModel.fetchUnits()
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 1) {
                    header
                    iconAndNameSection
                }
                daysSection
                typeSection
                goalSection
                noteSection

                Spacer()
                
                Spacer()

                VStack(spacing: 18) {
                    confirmButton
                    consolidationHint
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.immediately)
        .onTapGesture { focusedField = nil }
        .animation(.easeInOut(duration: 0.25), value: habitType)
    }

    // MARK: - Header con botón cerrar

    private var header: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 30, height: 30)
            }
            .glassEffect(.regular.interactive(), in: .circle)
        }
    }

    // MARK: - Icono + Nombre

    private var iconAndNameSection: some View {
        HStack(spacing: 14) {
            EmojiTextField(text: $icon)
                .frame(width: 46, height: 46)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))

            TextField("Añade tu nuevo hábito...", text: $name)
                .oruInputBig()
                .foregroundStyle(.primary)
                .focused($focusedField, equals: .name)
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
        .buttonStyle(.plain)
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
            ForEach(availableUnits, id: \.name) { unit in
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
        .lineLimit(4...8)
        .focused($focusedField, equals: .note)
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
        .disabled(!isValid)
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
        let normalized = dailyGoal.replacingOccurrences(of: ",", with: ".")
        let goal = Double(normalized)

        let habit = Habit(
            icon: icon,
            name: name.trimmingCharacters(in: .whitespaces),
            type: habitType,
            scheduledDays: Array(selectedDays).sorted { $0.rawValue < $1.rawValue },
            dailyGoal: goal,
            note: note.trimmingCharacters(in: .whitespaces).isEmpty
                ? nil
                : note.trimmingCharacters(in: .whitespaces)
        )

        habit.unit = selectedUnit

        viewModel.addHabit(habit)
        dismiss()
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
