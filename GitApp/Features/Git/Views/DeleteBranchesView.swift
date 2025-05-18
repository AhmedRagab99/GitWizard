import SwiftUI

struct DeleteBranchesView: View {
    @Binding var isPresented: Bool
    let branches: [Branch]
    let onDelete: ([Branch], Bool, Bool) async -> Void

    @State private var selectedBranches: Set<Branch> = []
    @State private var deleteRemote: Bool = false
    @State private var isDeleting: Bool = false

    // For UI layout
    @State private var branchTypeFilter: BranchType = .local

    // Filter by branch type
    private var filteredBranches: [Branch] {
        switch branchTypeFilter {
        case .local:
            return branches.filter { !$0.isRemote && !$0.isCurrent }
        case .remote:
            return branches.filter { $0.isRemote }
        }
    }

    // Are there any remote branches that correspond to selected local branches?
    private var hasRemoteCounterparts: Bool {
        guard branchTypeFilter == .local else { return false }

        for branch in selectedBranches {
            // Look for a remote matching each selected local branch
            let remoteNameToCheck = "origin/" + branch.name
            let hasRemote = branches.contains(where: { $0.isRemote && $0.name == remoteNameToCheck })
            if hasRemote {
                return true
            }
        }
        return false
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Branch type selector
                Picker("Branch Type", selection: $branchTypeFilter) {
                    Text("Local Branches").tag(BranchType.local)
                    Text("Remote Branches").tag(BranchType.remote)
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: branchTypeFilter) { _ in
                    // Clear selections when switching views
                    selectedBranches.removeAll()
                }

                // Branch list
                if filteredBranches.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)

                        Text("No \(branchTypeFilter.rawValue) branches available")
                            .font(.headline)

                        Text("There are no \(branchTypeFilter.rawValue) branches that can be deleted.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            ForEach(filteredBranches, id: \.name) { branch in
                                HStack {
                                    Image(systemName: selectedBranches.contains(branch) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedBranches.contains(branch) ? .blue : .gray)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(branchTypeFilter == .remote ? branch.displayName : branch.name)
                                            .font(.headline)

                                        // Show branch type indicator
                                        if branch.isRemote {
                                            Label("Remote", systemImage: "globe")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else if branch.isCurrent {
                                            Label("Current", systemImage: "checkmark.circle")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        } else {
                                            Label("Local", systemImage: "laptopcomputer")
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
                        } header: {
                            Text("Select branches to delete")
                        } footer: {
                            if branchTypeFilter == .local {
                                Text("Current branch cannot be deleted.")
                            } else {
                                Text("Deleting remote branches will remove them from the remote repository.")
                            }
                        }
                    }
                }

                VStack(spacing: 16) {
                    // Only show "Also delete remote branches" toggle for local branches
                    // and only if there are remote counterparts
                    if branchTypeFilter == .local && hasRemoteCounterparts {
                        Toggle("Also delete remote branches", isOn: $deleteRemote)
                            .padding(.horizontal)
                    }

                    HStack {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task {
                                isDeleting = true
                                await onDelete(
                                    Array(selectedBranches),
                                    branchTypeFilter == .local ? deleteRemote : false,
                                    branchTypeFilter == .remote
                                )
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
                        .tint(.red)
                        .disabled(selectedBranches.isEmpty || isDeleting)
                    }
                    .padding()
                }
                .background(ModernUI.colors.secondaryBackground)
            }
            .navigationTitle("Delete Branches")
        }
        .frame(width: 400, height: 500)
    }

    // Branch type enum
    enum BranchType: String {
        case local = "local"
        case remote = "remote"
    }
}


