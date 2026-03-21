import SwiftUI

struct UnitManagementView: View {

    var viewModel: HabitViewModel

    @State private var units: [Unit] = []
    @State private var newUnitName = ""
    @State private var unitToRename: Unit?
    @State private var renameName = ""
    @State private var unitToDelete: Unit?
    @State private var showDeleteDialog = false
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

    private var isRenameValid: Bool {
        let trimmed = renameName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let lowered = trimmed.lowercased()
        guard lowered != unitToRename?.name.lowercased() else { return false }
        return !units.contains(where: { $0.name.lowercased() == lowered })
    }

    var body: some View {
        NavigationStack {
            List {
                    Section("Esenciales") {
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
                                    Button {
                                        requestDelete(unit)
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                    .tint(.red)

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
                        Text("Creadas por ti")
                    } footer: {
                        Text("\(customUnits.count)/\(Unit.maxCustomCount) unidades a medida")
                    }
                }
            .scrollDismissesKeyboard(.immediately)
            .onTapGesture { isAddFieldFocused = false }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("A tu medida")
                        .oruAccent()
                }
            }
            .alert("Renombrar unidad", isPresented: showRenameBinding) {
                TextField("Nombre", text: $renameName)
                    .onChange(of: renameName) { _, newValue in
                        renameName = String(newValue.prefix(Unit.maxNameLength))
                    }
                Button("Cancelar", role: .cancel) { unitToRename = nil }
                Button("Guardar") { rename() }
                    .disabled(!isRenameValid)
            }
            .alert("Unidad en uso", isPresented: $showBlockedAlert) {
                Button("Entendido", role: .cancel) { }
            } message: {
                let noun = blockedHabitCount == 1 ? "hábito" : "hábitos"
                let info = "\(blockedHabitCount) \(noun)"
                Text("«\(blockedUnitName)» está en uso por \(info). Cambia su unidad antes de eliminarla.")
            }
            .alert("¿Eliminar unidad?", isPresented: $showDeleteDialog) {
                Button("Cancelar", role: .cancel) { unitToDelete = nil }
                Button("Eliminar", role: .destructive) { delete() }
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .task { loadUnits() }
        }
        .presentationDragIndicator(.visible)
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
            showDeleteDialog = true
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
