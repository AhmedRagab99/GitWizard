import SwiftUI

struct DeleteBranchesView: View {
    @Binding var isPresented: Bool
    let branches: [Branch]
    let onDelete: ([Branch], Bool) async -> Void

    @State private var selectedBranches: Set<Branch> = []
    @State private var deleteRemote: Bool = false
    @State private var isDeleting: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List(branches, id: \.name) { branch in
                    HStack {
                        Image(systemName: selectedBranches.contains(branch) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedBranches.contains(branch) ? .blue : .gray)

                        VStack(alignment: .leading) {
                            Text(branch.name)
                                .font(.headline)
                            if branch.isRemote {
                                Text("Remote Branch")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedBranches.contains(branch) {
                            selectedBranches.remove(branch)
                        } else {
                            selectedBranches.insert(branch)
                        }
                    }
                }

                VStack(spacing: 16) {
                    Toggle("Also delete remote branches", isOn: $deleteRemote)
                        .padding(.horizontal)

                    HStack {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task {
                                isDeleting = true
                                await onDelete(Array(selectedBranches), deleteRemote)
                                isDeleting = false
                                isPresented = false
                            }
                        } label: {
                            if isDeleting {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Delete")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedBranches.isEmpty || isDeleting)
                    }
                    .padding()
                }
                .background(ModernUI.colors.secondaryBackground)
            }
            .navigationTitle("Delete Branches")
//            .navigationBarTitleDisplayMode(.inline)
        }
        .frame(width: 400, height: 500)
    }
}
