import SwiftUI

struct ConflictLineView: View {
    let line: Line
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Line number/indicator area
            ZStack {
                Rectangle()
                    .fill(backgroundColor)
                    .frame(width: 40)

                if line.kind == .conflictStart {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .foregroundColor(.red)
                } else if line.kind == .conflictMiddle {
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .foregroundColor(.orange)
                } else if line.kind == .conflictEnd {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .frame(width: 40, alignment: .center)

            // Content
            Text(line.raw)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .background(isSelected ? Color.accentColor.opacity(0.2) : backgroundColor.opacity(0.5))
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }

    private var backgroundColor: Color {
        switch line.kind {
        case .conflictStart, .conflictEnd:
            return Color.red.opacity(0.2)
        case .conflictMiddle:
            return Color.orange.opacity(0.2)
        case .conflictOurs:
            return Color.blue.opacity(0.2)
        case .conflictTheirs:
            return Color.green.opacity(0.2)
        default:
            return .clear
        }
    }

    private var textColor: Color {
        switch line.kind {
        case .conflictStart, .conflictEnd:
            return .red
        case .conflictMiddle:
            return .orange
        case .conflictOurs:
            return .blue
        case .conflictTheirs:
            return .green
        default:
            return .primary
        }
    }
}

// Preview
#Preview {
    VStack {
        ConflictLineView(
            line: Line(id: 1, raw: "<<<<<<< HEAD"),
            isSelected: false,
            onSelect: {}
        )
        ConflictLineView(
            line: Line(id: 2, raw: "Our changes"),
            isSelected: false,
            onSelect: {}
        )
        ConflictLineView(
            line: Line(id: 3, raw: "======="),
            isSelected: true,
            onSelect: {}
        )
        ConflictLineView(
            line: Line(id: 4, raw: "Their changes"),
            isSelected: false,
            onSelect: {}
        )
        ConflictLineView(
            line: Line(id: 5, raw: ">>>>>>> branch-name"),
            isSelected: false,
            onSelect: {}
        )
    }
    .padding()
}
