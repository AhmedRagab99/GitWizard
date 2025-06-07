import SwiftUI

struct MergePullRequestView: View {
    @Bindable var viewModel: PullRequestViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Merge Pull Request")
                .font(.title2)
                .fontWeight(.bold)

            Picker("Merge Strategy", selection: $viewModel.mergeMethod) {
                Text("Merge Commit").tag("merge")
                Text("Squash and Merge").tag("squash")
                Text("Rebase and Merge").tag("rebase")
            }
            .pickerStyle(SegmentedPickerStyle())

            VStack(alignment: .leading) {
                Text("Commit Title")
                    .font(.headline)
                TextField("Title", text: $viewModel.mergeCommitTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            VStack(alignment: .leading) {
                Text("Commit Message (Optional)")
                    .font(.headline)
                TextEditor(text: $viewModel.mergeCommitMessage)
                    .frame(height: 150)
                    .border(Color.gray.opacity(0.5), width: 1)
                    .cornerRadius(5)
            }

            HStack {
                Button(action: { isPresented = false }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.cancelAction)

                Button(action: {
                    Task {
                        await viewModel.mergePullRequest()
                        isPresented = false
                    }
                }) {
                    Text("Confirm Merge")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.mergeCommitTitle.isEmpty)
            }
            .buttonStyle(.bordered)

        }
        .padding()
        .frame(width: 400)
    }
}
