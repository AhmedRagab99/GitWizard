import SwiftUI

struct SheetHeader: View {
    let title: String
    var subtitle: String?
    var icon: String?
    var iconColor: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let icon = icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .foregroundStyle(iconColor)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }

                Text(title)
                    .font(.title)
                    .lineLimit(1)
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, icon != nil ? 44 : 0)
            }

            Divider()
                .padding(.top, 6)
        }
        .padding(.bottom, 10)
    }
}

struct SheetFooter: View {
    var cancelAction: () -> Void
    var confirmAction: () -> Void
    var cancelText: String = "Cancel"
    var confirmText: String = "OK"
    var isConfirmDisabled: Bool = false
    var isLoading: Bool = false

    var body: some View {
        HStack {
            Button(cancelText) {
                cancelAction()
            }
            .buttonStyle(.bordered)

            Spacer()

            Button {
                confirmAction()
            } label: {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text(confirmText)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isConfirmDisabled || isLoading)
        }
        .padding(.top, 10)
    }
}

#Preview {
    VStack(spacing: 30) {
        VStack(alignment: .leading) {
            SheetHeader(
                title: "Merge Branch",
                subtitle: "Choose a branch to merge into the current branch",
                icon: "arrow.triangle.merge",
                iconColor: .blue
            )

            Text("Content goes here")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

            SheetFooter(
                cancelAction: {},
                confirmAction: {},
                confirmText: "Merge"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
        )

        VStack(alignment: .leading) {
            SheetHeader(
                title: "Push Changes",
                icon: "arrow.up.circle.fill",
                iconColor: .green
            )

            Text("Content goes here")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

            SheetFooter(
                cancelAction: {},
                confirmAction: {},
                confirmText: "Push",
                isConfirmDisabled: true
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
        )
    }
    .padding()
    .frame(width: 500)
}
