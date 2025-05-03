import SwiftUI

struct FileDiffView: View {
    let fileDiff: FileDiff
    let onStage: (Chunk) -> Void
    let onUnstage: (Chunk) -> Void
    let onReset: (Chunk) -> Void

    @State private var selectedChunk: Chunk?
    @State private var showLineNumbers = true
    @State private var fontSize: CGFloat = 13

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            Divider()
            // Diff content
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(fileDiff.chunks) { chunk in
                        chunkHeader(chunk)
                        ForEach(chunk.lines) { line in
                            diffLineView(line: line)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .background(Color(.windowBackgroundColor))
    }

    private var headerView: some View {
        HStack(spacing: 8) {
                    Image(systemName: fileDiff.status.icon)
                        .foregroundColor(fileDiff.status.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(fileDiff.fromFilePath.components(separatedBy: "/").last ?? fileDiff.fromFilePath)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                Text(fileDiff.fromFilePath)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                }
            Spacer()
            }
            .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
    }

    private func chunkHeader(_ chunk: Chunk) -> some View {
            HStack {
            Text(chunk.lines.first?.raw ?? "")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
                Spacer()
            // Optional: chunk actions
                HStack(spacing: 8) {
                    Button(action: { onStage(chunk) }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    Button(action: { onUnstage(chunk) }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                Button(action: { onReset(chunk) }) {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            }
        .padding(.horizontal, 8)
            .padding(.vertical, 4)
        .background(Color(.controlBackgroundColor))
    }

    private func diffLineView(line: Chunk.Line) -> some View {
        HStack(alignment: .top, spacing: 0) {
//            if showLineNumbers {
//                Group {
////                    Text(line.oldLineNumber != nil ? String(line.oldLineNumber!) : " ")
////                        .frame(width: 40, alignment: .trailing)
////                        .foregroundColor(.secondary)
//                    Text(line. != nil ? String(line.newLineNumber!) : " ")
//                        .frame(width: 40, alignment: .trailing)
//                        .foregroundColor(.secondary)
//                }
//                .font(.system(size: fontSize, design: .monospaced))
//                .padding(.trailing, 4)
//            }
            Text(line.raw)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(lineTextColor(line))
                .padding(.vertical, 1.5)
            Spacer()
        }
        .padding(.horizontal, 8)
        .background(lineBackground(line))
    }

    private func lineTextColor(_ line: Chunk.Line) -> Color {
        switch line.kind {
        case .added: return .green
        case .removed: return .red
        case .unchanged: return .primary
        case .header: return .blue
        }
    }

    private func lineBackground(_ line: Chunk.Line) -> Color {
        switch line.kind {
        case .added: return Color.green.opacity(0.12)
        case .removed: return Color.red.opacity(0.12)
        case .header: return Color.blue.opacity(0.08)
        case .unchanged: return Color.clear
    }
}
}

//#Preview {
//    FileDiffView(
//        fileDiff: FileDiff(
//            header: "diff --git a/File.swift b/File.swift",
//            extendedHeaderLines: [],
//            fromFileToFileLines: [],
//            chunks: [
//                Chunk(
//                    header: "@@ -1,5 +1,5 @@",
//                    oldLines: ["-old line 1", " old line 2", "-old line 3"],
//                    newLines: ["+new line 1", " old line 2", "+new line 3"]
//                )
//            ],
//            raw: ""
//        ),
//        onStage: { _ in },
//        onUnstage: { _ in },
//        onReset: { _ in }
//    )
//    .frame(width: 800, height: 600)
//}
