import SwiftUI

struct RequestChangesView: View {
    @Bindable var viewModel: PullRequestViewModel
    @Binding var isPresented: Bool
    @State private var comment: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Request Changes")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading) {
                Text("Comment (Required)")
                    .font(.headline)
                TextEditor(text: $comment)
                    .frame(height: 150)
                    .border(Color.gray.opacity(0.5), width: 1)
                    .cornerRadius(5)
            }

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Submit Review") {
                    Task {
                        await viewModel.requestChanges(comment: comment)
                        isPresented = false
                    }
                }
                .disabled(comment.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 400)
    }
}
