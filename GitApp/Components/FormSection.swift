import SwiftUI

struct FormSection<Content: View>: View {
    let title: String
    let content: Content
    var helpText: String?
    var showDivider: Bool = true

    init(title: String, helpText: String? = nil, showDivider: Bool = true, @ViewBuilder content: () -> Content) {
        self.title = title
        self.helpText = helpText
        self.showDivider = showDivider
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 2)

            content
                .padding(.leading, 8)

            if let helpText = helpText {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .padding(.leading, 8)
            }

            if showDivider {
                Divider()
                    .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    VStack {
        FormSection(title: "Basic Information", helpText: "Enter your personal details") {
            TextField("Name", text: .constant(""))
                .textFieldStyle(.roundedBorder)

            TextField("Email", text: .constant(""))
                .textFieldStyle(.roundedBorder)
        }

        FormSection(title: "Advanced Settings") {
            Toggle("Enable Notifications", isOn: .constant(true))
            Toggle("Dark Mode", isOn: .constant(false))
        }
    }
    .padding()
}
