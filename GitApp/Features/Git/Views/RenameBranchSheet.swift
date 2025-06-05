import SwiftUI

struct RenameBranchSheet: View {
    @Binding var isPresented: Bool
    let branch: Branch
    let onRename: (String) async -> Void

    @State private var newName: String
    @State private var isRenaming = false
    @State private var errorMessage: String?

    init(isPresented: Binding<Bool>, branch: Branch, onRename: @escaping (String) async -> Void) {
        self._isPresented = isPresented
        self.branch = branch
        self.onRename = onRename
        self._newName = State(initialValue: branch.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Branch Name", text: $newName)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("New Branch Name")
                } footer: {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Rename") {
                        Task {
                            isRenaming = true
                            await onRename(newName)
                            isRenaming = false
                            isPresented = false
                        }
                    }
                    .disabled(newName.isEmpty || newName == branch.name || isRenaming)
                }
            }
        }
        .frame(width: 400, height: 200)
    }
}
