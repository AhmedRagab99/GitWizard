import SwiftUI

struct CreatePullRequestView: View {
    @Bindable var viewModel: PullRequestViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            SheetHeader(
                title: "New Pull Request",
                subtitle: "Create a request to merge your changes",
                icon: "arrow.triangle.branch",
                iconColor: .blue
            )

            Card {
                VStack(alignment: .leading, spacing: 16) {
                    FormSection(title: "Pull Request Details") {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Title", text: $viewModel.newPRTitle)
                                .textFieldStyle(.roundedBorder)
                                .padding(.vertical, 4)

                            Text("Description")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextEditorWithPlaceholder(text: $viewModel.newPRBody, placeholder: "Provide a detailed description of your changes...")
                                .frame(height: 120)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }

                    FormSection(title: "Branch Selection") {
                        if viewModel.isLoadingBranches {
                            HStack {
                                ProgressView()
                                Text("Loading branches...")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        } else if !viewModel.availableBranches.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "arrow.down.circle")
                                        .foregroundStyle(.blue)
                                        .frame(width: 24)

                                    Text("Base Branch (target):")
                                        .frame(width: 150, alignment: .leading)

                                    Picker("Base Branch", selection: $viewModel.newPRBaseBranch) {
                                        ForEach(viewModel.availableBranches, id: \.name) { branch in
                                            Text(branch.name).tag(branch.name as String?)
                                        }
                                    }
                                    .labelsHidden()
                                }

                                HStack {
                                    Image(systemName: "arrow.up.circle")
                                        .foregroundStyle(.green)
                                        .frame(width: 24)

                                    Text("Compare Branch (source):")
                                        .frame(width: 150, alignment: .leading)

                                    Picker("Compare Branch", selection: $viewModel.newPRHeadBranch) {
                                        ForEach(viewModel.availableBranches, id: \.name) { branch in
                                            Text(branch.name).tag(branch.name as String?)
                                        }
                                    }
                                    .labelsHidden()
                                }
                            }
                            .padding(.vertical, 4)
                        } else {
                            Label("No branches found or failed to load.", systemImage: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .padding(.vertical)
                        }
                    }

                    if let errorMessage = viewModel.prCreationError {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }

            SheetFooter(
                cancelAction: { dismiss() },
                confirmAction: {
                    Task {
                        await viewModel.createPullRequest()
                        if viewModel.prCreationError == nil && !viewModel.isCreatingPR {
                            dismiss()
                        }
                    }
                },
                cancelText: "Cancel",
                confirmText: "Create Pull Request",
                isConfirmDisabled: !viewModel.canCreatePR,
                isLoading: viewModel.isCreatingPR
            )
        }
        .padding(24)
        .background(Color(nsColor: .controlBackgroundColor))
        .task {
            if viewModel.availableBranches.isEmpty {
                await viewModel.fetchBranchesForCurrentRepository()
            }
            if viewModel.newPRBaseBranch == nil, let defaultBranch = viewModel.repository?.defaultBranch {
                viewModel.newPRBaseBranch = defaultBranch
            }
            if viewModel.newPRHeadBranch == nil, let currentBranch = viewModel.currentBranchNameFromGitService {
                viewModel.newPRHeadBranch = currentBranch
            } else if viewModel.newPRHeadBranch == nil && !viewModel.availableBranches.isEmpty {
                viewModel.newPRHeadBranch = viewModel.availableBranches.first(where: { $0.name != viewModel.newPRBaseBranch })?.name
            }
        }
    }
}

// TextEditorWithPlaceholder remains the same
struct TextEditorWithPlaceholder: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color(NSColor.placeholderTextColor))
                    .padding(.top, 8)
                    .padding(.leading, 5) // Standard padding for TextEditor content
            }
            TextEditor(text: $text)
                .frame(minHeight: 100, maxHeight: .infinity)
        }
    }
}

// Extension on PullRequestViewModel for the canCreatePR computed property
// This should ideally be in the PullRequestViewModel.swift file, but for the purpose of this edit:
extension PullRequestViewModel {
    var canCreatePR: Bool {
        !newPRTitle.isEmpty &&
        newPRBaseBranch != nil &&
        newPRHeadBranch != nil &&
        newPRBaseBranch != newPRHeadBranch
    }
}
