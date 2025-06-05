import SwiftUI

struct CreatePullRequestView: View {
    @Bindable var viewModel: PullRequestViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) { // Use a VStack to manage overall layout, especially if removing NavigationView
            // Custom Title Bar if needed, or rely on sheet presentation title
            HStack {
                Text("New Pull Request")
                    .font(.title2).bold()
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.bar) // Gives a slight background like a toolbar

            Divider()

            Form {
                Section(header: Text("Details").font(.headline)) {
                    TextField("Title", text: $viewModel.newPRTitle)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 4)

                    Text("Description") // Label for TextEditor
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditorWithPlaceholder(text: $viewModel.newPRBody, placeholder: "Provide a detailed description of your changes...")
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding(.bottom, 10)

                Section(header: Text("Branches").font(.headline)) {
                    if viewModel.isLoadingBranches {
                        HStack {
                            ProgressView()
                            Text("Loading branches...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical)
                    } else if !viewModel.availableBranches.isEmpty {
                        Picker(selection: $viewModel.newPRBaseBranch) {
                            ForEach(viewModel.availableBranches, id: \.name) { branch in
                                Text(branch.name).tag(branch.name as String?)
                            }
                        } label: {
                            Label("Base Branch (target)", systemImage: "arrow.triangle.branch")
                        }
                        .pickerStyle(.menu)
                        .padding(.vertical, 4)

                        Picker(selection: $viewModel.newPRHeadBranch) {
                            ForEach(viewModel.availableBranches, id: \.name) { branch in
                                Text(branch.name).tag(branch.name as String?)
                            }
                        } label: {
                            Label("Compare Branch (source)", systemImage: "arrow.triangle.branch")
                        }
                        .pickerStyle(.menu)
                        .padding(.vertical, 4)
                    } else {
                        Label("No branches found or failed to load.", systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .padding(.vertical)
                    }
                }
                .padding(.bottom, 10)

                if let errorMessage = viewModel.prCreationError {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 5)
                }

                Button(action: {
                    Task {
                        await viewModel.createPullRequest()
                        if viewModel.prCreationError == nil && !viewModel.isCreatingPR {
                            dismiss()
                        }
                    }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isCreatingPR {
                            ProgressView()
                                .padding(.trailing, 4)
                                .tint(.white) // Ensure progress view is visible on colored button
                            Text("Creating Pull Request...")
                        } else {
                            Image(systemName: "plus.rectangle.on.rectangle")
                            Text("Create Pull Request")
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .font(.headline)
                    .foregroundColor(.white)
                    .background(viewModel.canCreatePR ? Color.accentColor : Color.gray) // Use accent color, gray if disabled
                    .cornerRadius(10)
                }
                .disabled(!viewModel.canCreatePR || viewModel.isCreatingPR)
                .padding(.top) // Add some space before the button

            }
            // .formStyle(.grouped) // Or .insetGrouped, explore for best macOS feel if default isn't clean
            .padding(.horizontal)
        }
        .background(Color(nsColor: .controlBackgroundColor)) // Match system background
        .task {
            if viewModel.availableBranches.isEmpty {
                await viewModel.fetchBranchesForCurrentRepository()
            }
            if viewModel.newPRBaseBranch == nil, let defaultBranch = viewModel.repository.defaultBranch {
                viewModel.newPRBaseBranch = defaultBranch
            }
            if viewModel.newPRHeadBranch == nil, let currentBranch = viewModel.currentBranchNameFromGitService {
                viewModel.newPRHeadBranch = currentBranch
            } else if viewModel.newPRHeadBranch == nil && !viewModel.availableBranches.isEmpty {
                viewModel.newPRHeadBranch = viewModel.availableBranches.first(where: { $0.name != viewModel.newPRBaseBranch })?.name
            }
        }
        // Consider removing the explicit frame if the sheet handles sizing well.
        // .frame(minWidth: 450, idealWidth: 550, minHeight: 500, idealHeight: 600)
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
