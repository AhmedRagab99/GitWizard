import SwiftUI

struct FileDiffView: View {
    let fileDiff: FileDiff
    let onStage: (Chunk) -> Void
    let onUnstage: (Chunk) -> Void
    let onReset: (Chunk) -> Void

    @State private var selectedChunk: Chunk?
    @State private var isHovering = false
    @State private var showLineNumbers = true
    @State private var showWhitespace = true
    @State private var fontSize: CGFloat = 12
    @State private var theme: Theme = .light

    enum Theme: String, CaseIterable {
        case light = "xcode"
        case dark = "atom-one-dark"

        var colorScheme: ColorScheme {
            switch self {
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Diff content
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(fileDiff.chunks) { chunk in
                        chunkViewContent(chunk)
                    }
                }
            }
        }
//        .background(Color.clear)
        .environment(\.colorScheme, theme.colorScheme)
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                // File status and path
                HStack(spacing: 4) {
                    Image(systemName: fileDiff.status.icon)
                        .foregroundColor(fileDiff.status.color)
                    Text(fileDiff.filePathDisplay)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                }

                Spacer()

                // Controls
                HStack(spacing: 16) {
                    // Theme picker
                    Picker("Theme", selection: $theme) {
                        ForEach(Theme.allCases, id: \.self) { theme in
                            Text(theme.rawValue.capitalized)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)

                    // Font size control
                    HStack(spacing: 4) {
                        Image(systemName: "textformat.size")
                        Slider(value: $fontSize, in: 8...20, step: 1)
                            .frame(width: 100)
                    }

                    // Toggles
                    Toggle("Line Numbers", isOn: $showLineNumbers)
                    Toggle("Whitespace", isOn: $showWhitespace)
                }
            }
            .padding(.horizontal)

            Divider()
        }
        .padding(.vertical, 8)
    }

    private func chunkViewContent(_ chunk: Chunk) -> some View {
        VStack(spacing: 0) {
            // Chunk header
            HStack {
                Text(chunk.raw.components(separatedBy: "\n").first ?? "")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()

                // Chunk actions
                HStack(spacing: 8) {
                    Button(action: { onStage(chunk) }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)

                    Button(action: { onUnstage(chunk) }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)

                    Button(action: { onReset(chunk) }) {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color(.clear))

            // Diff content
            HStack(spacing: 0) {
                // Left side (old content)
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(chunk.lines.filter { $0.kind == .removed || $0.kind == .unchanged }) { line in
                            lineView(line.raw, isOld: true)
                        }
                    }
                }
                .frame(minWidth: 300)

                Divider()

                // Right side (new content)
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(chunk.lines.filter { $0.kind == .added || $0.kind == .unchanged }) { line in
                            lineView(line.raw, isOld: false)
                        }
                    }
                }
                .frame(minWidth: 300)
            }
        }
        .background(selectedChunk == chunk ? Color(.selectedControlColor).opacity(0.3) : Color.clear)
        .onHover { isHovering in
            self.isHovering = isHovering
        }
        .onTapGesture {
            selectedChunk = chunk
        }
    }

    private func lineView(_ line: String, isOld: Bool) -> some View {
        HStack(spacing: 0) {
            if showLineNumbers {
                Text(line.prefix(while: { $0.isNumber }))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
                    .padding(.trailing, 8)
            }

            Text(line)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(lineColor(for: line))
                .padding(.vertical, 2)
        }
        .padding(.horizontal, 8)
        .background(lineBackground(for: line))
    }

    private func lineColor(for line: String) -> Color {
        if line.hasPrefix("+") {
            return .green
        } else if line.hasPrefix("-") {
            return .red
        } else if line.hasPrefix("@@") {
            return .blue
        }
        return .clear
    }

    private func lineBackground(for line: String) -> Color {
        if line.hasPrefix("+") {
            return Color.green.opacity(0.1)
        } else if line.hasPrefix("-") {
            return Color.red.opacity(0.1)
        }
        return .clear
    }
}
//
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
