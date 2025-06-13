import SwiftUI

struct TableHeader: View {
    var columns: [TableColumn]
    var padding: EdgeInsets = EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)

    struct TableColumn {
        let title: String
        let width: CGFloat?
        let alignment: Alignment

        init(title: String, width: CGFloat? = nil, alignment: Alignment = .leading) {
            self.title = title
            self.width = width
            self.alignment = alignment
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                Text(column.title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .frame(
                        width: column.width,
                        alignment: column.alignment
                    )

                if index < columns.count - 1 {
                    Spacer(minLength: 8)
                }
            }
        }
        .padding(padding)
        .background(Color(.separatorColor).opacity(0.1))
    }
}

struct ListRow<Content: View>: View {
    var content: Content
    var isSelected: Bool = false
    var padding: EdgeInsets = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
    var onTap: (() -> Void)?
    var backgroundColor: Color = Color(.windowBackgroundColor)
    var selectedBackgroundColor: Color = Color(.selectedContentBackgroundColor).opacity(0.5)
    var cornerRadius: CGFloat = 8
    var shadowRadius: CGFloat = 1

    init(
        isSelected: Bool = false,
        padding: EdgeInsets = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12),
        onTap: (() -> Void)? = nil,
        backgroundColor: Color = Color(.windowBackgroundColor),
        selectedBackgroundColor: Color = Color(.selectedContentBackgroundColor).opacity(0.5),
        cornerRadius: CGFloat = 8,
        shadowRadius: CGFloat = 1,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.padding = padding
        self.onTap = onTap
        self.backgroundColor = backgroundColor
        self.selectedBackgroundColor = selectedBackgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = content()
    }

    var body: some View {
        Card(
            backgroundColor: isSelected ? selectedBackgroundColor : backgroundColor,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            padding: .init(top: 0, leading: 0, bottom: 0, trailing: 0)
        ) {
            content
                .padding(padding)
                .contentShape(Rectangle())
        }
        .if(onTap != nil) { view in
            view.onTapGesture {
                onTap?()
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"
    var onCommit: (() -> Void)?

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .onSubmit {
                    onCommit?()
                }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct EmptyListView: View {
    var title: String
    var message: String
    var systemImage: String
    var action: (() -> Void)?
    var actionTitle: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Conditional modifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
