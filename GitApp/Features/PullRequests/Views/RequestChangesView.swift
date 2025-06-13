import SwiftUI

struct RequestChangesView: View {
    @Bindable var viewModel: PullRequestViewModel
    @Binding var isPresented: Bool
    @State private var comment: String = ""

    var body: some View {
        VStack(spacing: 16) {
            SheetHeader(
                title: "Request Changes",
                subtitle: "Submit feedback requiring modifications",
                icon: "exclamationmark.circle",
                iconColor: .orange
            )

            Card {
                FormSection(title: "Review Details") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comment (Required)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $comment)
                            .frame(height: 150)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
            }

            SheetFooter(
                cancelAction: { isPresented = false },
                confirmAction: {
                    Task {
                        await viewModel.requestChanges(comment: comment)
                        isPresented = false
                    }
                },
                cancelText: "Cancel",
                confirmText: "Submit Review",
                isConfirmDisabled: comment.isEmpty
            )
        }
        .padding(24)
        .frame(width: 450)
    }
}
