//
//  MergeSheet.swift
//  GitApp
//
//  Created by Ahmed Ragab on 24/04/2025.
//

import SwiftUI

struct MergeSheet: View {
    @Bindable var viewModel: GitViewModel
    @Binding var isPresented: Bool
    @State private var selectedBranch: String = ""
    @State private var mergingInProgress = false
    @State private var options = MergeOptions()
    @State private var branchType: BranchType = .remote

    enum BranchType {
        case local
        case remote
    }

    struct MergeOptions {
        var commitMerged: Bool = true
        var includeMessages: Bool = false
        var createNewCommit: Bool = false
        var rebaseInsteadOfMerge: Bool = false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Merge")
                .font(.title)
                .padding(.bottom, 10)

            // Branch type selector
            Picker("Branch Type", selection: $branchType) {
                Text("Local Branches").tag(BranchType.local)
                Text("Remote Branches").tag(BranchType.remote)
            }
            .pickerStyle(.segmented)
            .onChange(of: branchType) { _, newType in
                // Reset selected branch when switching branch type
                selectedBranch = ""

                // Set default branch if available
                if newType == .local, let firstLocal = viewModel.branches.first {
                    selectedBranch = firstLocal.name
                } else if newType == .remote, let firstRemote = viewModel.remotebranches.first {
                    selectedBranch = firstRemote.name
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Merge from \(branchType == .local ? "local" : "remote") branch:")
                    .font(.headline)

                if branchType == .local {
                    Picker("Select Branch", selection: $selectedBranch) {
                        ForEach(viewModel.branches) { branch in
                            if branch.name != viewModel.currentBranch?.name {
                                Text(branch.name).tag(branch.name)
                            }
                        }
                    }
                    .labelsHidden()
                } else {
                    Picker("Select Branch", selection: $selectedBranch) {
                        ForEach(viewModel.remotebranches) { branch in
                            Text(branch.name).tag(branch.name)
                        }
                    }
                    .labelsHidden()
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Options")
                    .font(.headline)

                Toggle("Commit merge immediately (if no conflicts)", isOn: $options.commitMerged)

                Toggle("Include messages from commits being merged in merge commit", isOn: $options.includeMessages)

                Toggle("Create a commit even if merge resolved via fast-forward", isOn: $options.createNewCommit)

                Toggle("Rebase instead of merge (WARNING: make sure you haven't pushed changes)", isOn: $options.rebaseInsteadOfMerge)
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    Task {
                        mergingInProgress = true
                        await performMerge()
                        mergingInProgress = false
                        isPresented = false
                    }
                } label: {
                    if mergingInProgress {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("OK")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedBranch.isEmpty || mergingInProgress)
            }
        }
        .frame(width: 500)
        .padding()
        .onAppear {
            // Set default branch selections on appear
            if branchType == .local {
                // Filter out current branch and select the first available branch
                let availableBranches = viewModel.branches.filter { $0.name != viewModel.currentBranch?.name }
                if let firstBranch = availableBranches.first {
                    selectedBranch = firstBranch.name
                }
            } else if let firstRemote = viewModel.remotebranches.first {
                selectedBranch = firstRemote.name
            }
        }
    }

    private func performMerge() async {
        await viewModel.mergeBranch(
            selectedBranch,
            commitMerged: options.commitMerged,
            includeMessages: options.includeMessages,
            createNewCommit: options.createNewCommit,
            rebaseInsteadOfMerge: options.rebaseInsteadOfMerge
        )
    }
}

#Preview {
    MergeSheet(
        viewModel: GitViewModel(),
        isPresented: .constant(true)
    )
}
