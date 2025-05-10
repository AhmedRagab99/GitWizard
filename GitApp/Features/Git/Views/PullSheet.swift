//
//  PullSheet.swift
//  GitApp
//
//  Created by Ahmed Ragab on 10/05/2025.
//

import SwiftUI

struct PullSheet: View {
    @Binding var isPresented: Bool
    var remotes: [String]
    var remoteBranches: [String]
    var localBranches: [String]
    var currentRemote: String
    var currentRemoteBranch: String
    var currentLocalBranch: String
    var onPull: (_ remote: String, _ remoteBranch: String, _ localBranch: String, _ options: PullOptions) -> Void

    @State private var selectedRemote: String
    @State private var selectedRemoteBranch: String
    @State private var selectedLocalBranch: String
    @State private var commitMerged: Bool = false
    @State private var includeMessages: Bool = false
    @State private var createNewCommit: Bool = false
    @State private var rebaseInsteadOfMerge: Bool = false

    struct PullOptions {
        var commitMerged: Bool
        var includeMessages: Bool
        var createNewCommit: Bool
        var rebaseInsteadOfMerge: Bool
    }

    init(isPresented: Binding<Bool>, remotes: [String], remoteBranches: [String], localBranches: [String], currentRemote: String, currentRemoteBranch: String, currentLocalBranch: String, onPull: @escaping (_ remote: String, _ remoteBranch: String, _ localBranch: String, _ options: PullOptions) -> Void) {
        self._isPresented = isPresented
        self.remotes = remotes
        self.remoteBranches = remoteBranches
        self.localBranches = localBranches
        self.currentRemote = currentRemote
        self.currentRemoteBranch = currentRemoteBranch
        self.currentLocalBranch = currentLocalBranch
        self.onPull = onPull
        _selectedRemote = State(initialValue: currentRemote)
        _selectedRemoteBranch = State(initialValue: currentRemoteBranch)
        _selectedLocalBranch = State(initialValue: currentLocalBranch)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pull from repository:")
                    .font(.headline)
                Spacer()
                Picker("Remote", selection: $selectedRemote) {
                    ForEach(remotes, id: \.self) { remote in
                        Text(remote).tag(remote)
                    }
                }
                .labelsHidden()
                .frame(width: 120)
            }
            .padding(.bottom, 4)

            HStack {
                Text("Remote branch to pull:")
                    .font(.subheadline)
                Picker("Remote Branch", selection: $selectedRemoteBranch) {
                    ForEach(remoteBranches, id: \.self) { branch in
                        Text(branch).tag(branch)
                    }
                }
                .labelsHidden()
                .frame(width: 200)
                Button("Refresh") {
                    // TODO: Refresh remote branches
                }
            }

            HStack {
                Text("Pull into local branch:")
                    .font(.subheadline)
                Picker("Local Branch", selection: $selectedLocalBranch) {
                    ForEach(localBranches, id: \.self) { branch in
                        Text(branch).tag(branch)
                    }
                }
                .labelsHidden()
                .frame(width: 200)
            }

            Text("Options")
                .font(.subheadline)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Commit merged changes immediately", isOn: $commitMerged)
                Toggle("Include messages from commits being merged in merge commit", isOn: $includeMessages)
                Toggle("Create new commit even if fast-forward merge", isOn: $createNewCommit)
                Toggle("Rebase instead of merge (WARNING: make sure you haven't pushed your changes)", isOn: $rebaseInsteadOfMerge)
            }
            .padding(8)
            .background(Color(.secondaryLabelColor))
            .cornerRadius(8)

            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("OK") {
                    let options = PullOptions(
                        commitMerged: commitMerged,
                        includeMessages: includeMessages,
                        createNewCommit: createNewCommit,
                        rebaseInsteadOfMerge: rebaseInsteadOfMerge
                    )
                    onPull(selectedRemote, selectedRemoteBranch, selectedLocalBranch, options)
                    isPresented = false
                }
            }
        }
        .padding(24)
        .frame(minWidth: 500)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
        .shadow(radius: 20)
    }
}
