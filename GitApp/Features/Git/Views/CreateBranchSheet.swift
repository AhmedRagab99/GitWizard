//
//  CreateBranchSheet.swift
//  GitApp
//
//  Created by Ahmed Ragab on 10/05/2025.
//

import SwiftUI

enum CommitSource: String, CaseIterable, Identifiable {
    case workingCopyParent = "Working copy parent"
    case specifiedCommit = "Specified commit"
    var id: String { rawValue }
}

// MARK: - Create Branch Sheet
struct CreateBranchSheet: View {
    @Binding var isPresented: Bool
    var currentBranch: String
    var onCreate: (_ branchName: String, _ commitSource: CommitSource, _ specifiedCommit: String?, _ checkout: Bool) -> Void

    @State private var branchName: String = ""
    @State private var commitSource: CommitSource = .workingCopyParent
    @State private var specifiedCommit: String = ""
    @State private var showCommitPicker: Bool = false
    @State private var checkoutNewBranch: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SheetHeader(
                title: "New Branch",
                subtitle: "Create a new branch from the current state",
                icon: "plus.square.on.square",
                iconColor: .green
            )

            Card {
                VStack(alignment: .leading, spacing: 12) {
                    FormSection(title: "Current Branch") {
                        Text(currentBranch)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondaryLabelColor).opacity(0.2))
                            .cornerRadius(6)
                    }

                    FormSection(title: "New Branch") {
                        TextField("Branch name", text: $branchName)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                    }

                    FormSection(title: "Commit Source") {
                        Picker("Commit Source", selection: $commitSource) {
                            ForEach(CommitSource.allCases) { source in
                                Text(source.rawValue).tag(source)
                            }
                        }
                        .pickerStyle(.radioGroup)

                        if commitSource == .specifiedCommit {
                            HStack {
                                TextField("Commit hash", text: $specifiedCommit)
                                    .textFieldStyle(.roundedBorder)
                                Button("Pick…") {
                                    // TODO: Show commit picker
                                }
                                .disabled(true)
                            }
                        }
                    }

                    FormSection(title: "Options", showDivider: false) {
                        Toggle(isOn: $checkoutNewBranch) {
                            Text("Checkout new branch")
                        }
                        .toggleStyle(.switch)
                    }
                }
            }

            SheetFooter(
                cancelAction: { isPresented = false },
                confirmAction: {
                    onCreate(branchName.trimmingCharacters(in: .whitespacesAndNewlines), commitSource, specifiedCommit.isEmpty ? nil : specifiedCommit, checkoutNewBranch)
                    isPresented = false
                },
                confirmText: "Create Branch",
                isConfirmDisabled: branchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
        .padding(24)
        .frame(minWidth: 380)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.windowBackgroundColor))
        )
    }
}
