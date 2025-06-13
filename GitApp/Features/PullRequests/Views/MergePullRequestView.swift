import SwiftUI

struct MergePullRequestView: View {
    @Bindable var viewModel: PullRequestViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 16) {
            SheetHeader(
                title: "Merge Pull Request",
                subtitle: "Combine changes from this pull request",
                icon: "arrow.triangle.merge",
                iconColor: .purple
            )

            Card {
                VStack(alignment: .leading, spacing: 16) {
                    FormSection(title: "Merge Strategy") {
                        Picker("Merge Strategy", selection: $viewModel.mergeMethod) {
                            Text("Merge Commit").tag("merge")
                            Text("Squash and Merge").tag("squash")
                            Text("Rebase and Merge").tag("rebase")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 4)
                    }

                    FormSection(title: "Commit Details") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Commit Title")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Title", text: $viewModel.mergeCommitTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Text("Commit Message (Optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            TextEditor(text: $viewModel.mergeCommitMessage)
                                .frame(height: 150)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                }
            }

            SheetFooter(
                cancelAction: { isPresented = false },
                confirmAction: {
                    Task {
                        await viewModel.mergePullRequest()
                        isPresented = false
                    }
                },
                cancelText: "Cancel",
                confirmText: "Confirm Merge",
                isConfirmDisabled: viewModel.mergeCommitTitle.isEmpty
            )
        }
        .padding(24)
        .frame(width: 450)
    }
}
