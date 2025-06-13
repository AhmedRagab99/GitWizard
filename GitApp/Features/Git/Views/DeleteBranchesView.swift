import SwiftUI

struct DeleteBranchesView: View {
    @Binding var isPresented: Bool
    let branches: [Branch]
    let onDelete: ([Branch], Bool, Bool, Bool) async -> Void

    @State private var selectedBranches: Set<Branch> = []
    @State private var deleteRemote: Bool = false
    @State private var forceDelete: Bool = false
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
        VStack(alignment: .leading, spacing: 16) {
            SheetHeader(
                title: "Delete Branches",
                subtitle: "Select branches you want to remove",
                icon: "trash",
                iconColor: .red
            )

            // Branch type selector
            Picker("Branch Type", selection: $branchTypeFilter) {
                Text("Local Branches").tag(BranchType.local)
                Text("Remote Branches").tag(BranchType.remote)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: branchTypeFilter) { _ in
                // Clear selections when switching views
                selectedBranches.removeAll()
            }

            // Branch list
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select branches to delete")
                        .font(.headline)
                        .padding(.horizontal, 8)

                    if filteredBranches.isEmpty {
                        EmptyListView(
                            title: "No \(branchTypeFilter.rawValue) branches available",
                            message: "There are no \(branchTypeFilter.rawValue) branches that can be deleted.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .frame(height: 200)
                    } else {
                        ScrollView {
                            VStack(spacing: 2) {
                                ForEach(filteredBranches, id: \.name) { branch in
                                    ListRow(
                                        isSelected: selectedBranches.contains(branch),
                                        onTap: {
                                            if selectedBranches.contains(branch) {
                                                selectedBranches.remove(branch)
                                            } else {
                                                selectedBranches.insert(branch)
                                            }
                                        },
                                        cornerRadius: 8,
                                        shadowRadius: 1
                                    ) {
                                        HStack {
                                            Image(systemName: selectedBranches.contains(branch) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedBranches.contains(branch) ? .blue : .gray)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(branchTypeFilter == .remote ? branch.displayName : branch.name)
                                                    .font(.headline)

                                                // Show branch type indicator
                                                if branch.isRemote {
                                                    TagView(text: "Remote", color: .gray, systemImage: "globe")
                                                } else if branch.isCurrent {
                                                    TagView(text: "Current", color: .green, systemImage: "checkmark.circle")
                                                } else {
                                                    TagView(text: "Local", color: .gray, systemImage: "laptopcomputer")
                                                }
                                            }

                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 250)
                    }

                    if branchTypeFilter == .local {
                        Text("Current branch cannot be deleted.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                    } else {
                        Text("Deleting remote branches will remove them from the remote repository.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                    }
                }
            }

            FormSection(title: "Options", showDivider: false) {
                VStack(alignment: .leading, spacing: 8) {
                    // Only show "Also delete remote branches" toggle for local branches
                    // and only if there are remote counterparts
                    if branchTypeFilter == .local && hasRemoteCounterparts {
                        Toggle("Also delete remote branches", isOn: $deleteRemote)
                    }

                    // Force delete option for local branches
                    if branchTypeFilter == .local {
                        Toggle("Force delete (even if not fully merged)", isOn: $forceDelete)
                    }
                }
                .padding(.horizontal, 8)
            }

            SheetFooter(
                cancelAction: { isPresented = false },
                confirmAction: {
                    Task {
                        isDeleting = true
                        await onDelete(
                            Array(selectedBranches),
                            branchTypeFilter == .local ? deleteRemote : false,
                            branchTypeFilter == .remote,
                            forceDelete
                        )
                        isDeleting = false
                        isPresented = false
                    }
                },
                confirmText: "Delete Branches",
                isConfirmDisabled: selectedBranches.isEmpty,
                isLoading: isDeleting
            )
        }
        .frame(width: 400)
        .padding(24)
        .background(Color(.windowBackgroundColor))
    }

    // Branch type enum
    enum BranchType: String {
        case local = "local"
        case remote = "remote"
    }
}


