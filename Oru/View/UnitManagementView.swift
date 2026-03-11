import SwiftUI

struct UnitManagementView: View {

    var viewModel: HabitViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var units: [Unit] = []
    @State private var newUnitName = ""
    @State private var unitToRename: Unit?
    @State private var renameName = ""
    @State private var unitToDelete: Unit?
    @State private var blockedUnitName = ""
    @State private var blockedHabitCount = 0
    @State private var showBlockedAlert = false
    @FocusState private var isAddFieldFocused: Bool

    private var baseUnits: [Unit] { units.filter { $0.origin == .base } }
    private var customUnits: [Unit] { units.filter { $0.origin == .custom } }
    private var canAddMore: Bool { customUnits.count < Unit.maxCustomCount }

    private var trimmedNewName: String {
        newUnitName.trimmingCharacters(in: .whitespaces)
    }

    private var isNewNameValid: Bool {
        !trimmedNewName.isEmpty
            && !units.contains(where: { $0.name.lowercased() == trimmedNewName.lowercased() })
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Predefinidas") {
                    ForEach(baseUnits) { unit in
                        Text(unit.name)
                            .oruTextPrimary()
                    }
                }

                Section {
                    ForEach(customUnits) { unit in
                        Text(unit.name)
                            .oruTextPrimary()
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    requestDelete(unit)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }

                                Button {
                                    renameName = unit.name
                                    unitToRename = unit
                                } label: {
                                    Label("Renombrar", systemImage: "pencil")
                                }
                                .tint(.oruPrimary)
                            }
                    }

                    if canAddMore {
                        addUnitRow
                    }
                } header: {
                    Text("Personalizadas")
                } footer: {
                    Text("\(customUnits.count)/\(Unit.maxCustomCount) unidades personalizadas")
                }
            }
            .navigationTitle("Unidades")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
            .alert("Renombrar unidad", isPresented: showRenameBinding) {
                TextField("Nombre", text: $renameName)
                    .onChange(of: renameName) { _, newValue in
                        renameName = String(newValue.prefix(Unit.maxNameLength))
                    }
                Button("Cancelar", role: .cancel) { unitToRename = nil }
                Button("Guardar") { rename() }
                    .disabled(renameName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .alert("Unidad en uso", isPresented: $showBlockedAlert) {
                Button("Entendido", role: .cancel) { }
            } message: {
                let noun = blockedHabitCount == 1 ? "hábito" : "hábitos"
                let info = "\(blockedHabitCount) \(noun)"
                Text("«\(blockedUnitName)» está en uso por \(info). Cambia su unidad antes de eliminarla.")
            }
            .confirmationDialog(
                "¿Eliminar unidad?",
                isPresented: showDeleteBinding,
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) { delete() }
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .task { loadUnits() }
        }
    }

    // MARK: - Fila de nueva unidad

    private var addUnitRow: some View {
        HStack(spacing: 8) {
            TextField("Nueva unidad", text: $newUnitName)
                .oruInputSmall()
                .focused($isAddFieldFocused)
                .onSubmit { addUnit() }
                .onChange(of: newUnitName) { _, newValue in
                    newUnitName = String(newValue.prefix(Unit.maxNameLength))
                }

            Button {
                addUnit()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(isNewNameValid ? Color.oruPrimary : .secondary.opacity(0.3))
            }
            .disabled(!isNewNameValid)
        }
    }

    // MARK: - Bindings

    private var showRenameBinding: Binding<Bool> {
        Binding(
            get: { unitToRename != nil },
            set: { if !$0 { unitToRename = nil } }
        )
    }

    private var showDeleteBinding: Binding<Bool> {
        Binding(
            get: { unitToDelete != nil },
            set: { if !$0 { unitToDelete = nil } }
        )
    }

    // MARK: - Acciones

    private func loadUnits() {
        units = viewModel.fetchUnits()
    }

    private func addUnit() {
        guard viewModel.addCustomUnit(name: newUnitName) else { return }
        newUnitName = ""
        loadUnits()
    }

    private func requestDelete(_ unit: Unit) {
        let count = viewModel.countHabitsUsingUnit(unit)
        if count > 0 {
            blockedUnitName = unit.name
            blockedHabitCount = count
            showBlockedAlert = true
        } else {
            unitToDelete = unit
        }
    }

    private func rename() {
        guard let unit = unitToRename else { return }
        _ = viewModel.renameUnit(unit, to: renameName)
        unitToRename = nil
        loadUnits()
    }

    private func delete() {
        guard let unit = unitToDelete else { return }
        viewModel.deleteUnit(unit)
        unitToDelete = nil
        loadUnits()
    }
}
