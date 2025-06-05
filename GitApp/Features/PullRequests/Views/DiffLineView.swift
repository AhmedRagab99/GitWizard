import SwiftUI

/// A view to display a single line within a diff (patch).
struct DiffLineView: View {
    let line: Line // Using the Line struct from Chunk.swift

    var body: some View {
        HStack(spacing: 0) {
            // Line number (from/to based on availability or context)
            // Chunk.Line has toFileLineNumber, which is relevant for the "new" file state.
            // For a unified diff, you often show both old and new line numbers or adapt based on line type.
            // For simplicity, we'll use toFileLineNumber for added/unchanged, and try to infer for removed.
            Text(lineNumberText)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
                .padding(.trailing, 8)

            // Change indicator (+, -, space, or other symbols for headers/conflicts)
            Text(lineIndicator)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(lineColor)
                .frame(width: 20, alignment: .center)

            // Content
            // Remove the first character if it's +, -, or space, as it's represented by the indicator
            Text(lineContent)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(lineColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.vertical, 1)
        // Removed horizontal padding to align with typical diff views, parent can add if needed.
        // Background color can also be set here based on line.kind if desired for whole line bg highlight
        .background(backgroundColor)
    }

    private var lineNumberText: String {
        if line.kind == .header { return "" }
        // TODO: Implement robust old/new line number display if needed.
        // For now, using toFileLineNumber if available.
        return line.toFileLineNumber.map { "\($0)" } ?? ""
    }

    private var lineIndicator: String {
        switch line.kind {
        case .added: return "+"
        case .removed: return "-"
        case .unchanged: return " "
        case .header: return "@"
        // Conflict markers can be handled specifically if they appear in PR patches
        case .conflictStart: return "<"
        case .conflictMiddle: return "="
        case .conflictEnd: return ">"
        case .conflictOurs, .conflictTheirs: return "!" // Example
        }
    }

    private var lineContent: String {
        if line.kind == .header || line.kind == .conflictStart || line.kind == .conflictMiddle || line.kind == .conflictEnd {
            return line.raw // Show full header/conflict marker line
        }
        // For content lines, remove the leading diff char (+, -,  ) as it's shown by `lineIndicator`
        if !line.raw.isEmpty {
            let firstChar = line.raw.first
            if firstChar == "+" || firstChar == "-" || firstChar == " " {
                return String(line.raw.dropFirst())
            }
        }
        return line.raw
    }

    private var lineColor: Color {
        switch line.kind {
        case .added, .conflictOurs: return .green
        case .removed, .conflictTheirs: return .red
        case .header: return .blue
        case .unchanged: return .primary
        case .conflictStart, .conflictMiddle, .conflictEnd: return .orange
        }
    }

    private var backgroundColor: Color {
        switch line.kind {
        case .added: return Color.green.opacity(0.1)
        case .removed: return Color.red.opacity(0.1)
        case .header: return Color.blue.opacity(0.1)
        default: return Color.clear
        }
    }
}

#if DEBUG
//struct DiffLineView_Previews: PreviewProvider {
//    static var previews: some View {
//        // Sample Chunk.Line objects for preview
//        let headerLine = Chunk.Line(id: 0, raw: "@@ -1,5 +1,6 @@")
//        var addedLine = Chunk.Line(id: 1, raw: "+This is an added line.")
//        addedLine.toFileLineNumber = 10
//        var removedLine = Chunk.Line(id: 2, raw: "-This is a removed line.")
//        // removedLine.fromFileLineNumber = 11 // Hypothetical if Line struct supported it
//        var unchangedLine = Chunk.Line(id: 3, raw: " This is an unchanged line.")
//        unchangedLine.toFileLineNumber = 12
//
//        let conflictStart = Chunk.Line(id: 4, raw: "<<<<<<< HEAD")
//        var conflictOurs = Chunk.Line(id: 5, raw: " Our conflicting line")
//        conflictOurs.isInOurConflict = true
//        let conflictMiddle = Chunk.Line(id: 6, raw: "=======")
//        var conflictTheirs = Chunk.Line(id: 7, raw: " Their conflicting line")
//        conflictTheirs.isInTheirConflict = true
//        let conflictEnd = Chunk.Line(id: 8, raw: ">>>>>>> feature-branch")
//
//
//        return ScrollView {
//            VStack(alignment: .leading, spacing: 0) {
//                DiffLineView(line: headerLine)
//                DiffLineView(line: addedLine)
//                DiffLineView(line: removedLine)
//                DiffLineView(line: unchangedLine)
//                DiffLineView(line: Chunk.Line(id: 4, raw: " Another context line"))
//                DiffLineView(line: conflictStart)
//                DiffLineView(line: conflictOurs)
//                DiffLineView(line: conflictMiddle)
//                DiffLineView(line: conflictTheirs)
//                DiffLineView(line: conflictEnd)
//            }
//            .padding()
//        }
//        .previewDisplayName("Diff Lines")
//    }
//}
#endif
