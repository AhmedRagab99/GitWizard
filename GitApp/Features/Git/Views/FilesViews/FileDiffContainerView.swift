import SwiftUI

struct FileDiffContainerView: View {
    @Bindable var viewModel: GitViewModel
    let fileDiff: FileDiff

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: fileDiff.status.icon)
                    .foregroundColor(fileDiff.status.color)
                    .font(.system(size: 22, weight: .bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(fileDiff.fromFilePath.components(separatedBy: "/").last ?? fileDiff.fromFilePath)
                        .font(.system(size: 16, weight: .semibold))
                    Text(fileDiff.fromFilePath)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if fileDiff.lineStats.added > 0 {
                    Text("+\(fileDiff.lineStats.added)")
                        .font(.caption2.bold())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(5)
                }
                if fileDiff.lineStats.removed > 0 {
                    Text("-\(fileDiff.lineStats.removed)")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                        .padding(.horizontal, 6)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(5)
                }
                StatusBadge(status: fileDiff.status)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
            Divider()
            // Diff content
            FileDiffView(
                fileDiff: fileDiff,
                onStage: { chunk in
                    viewModel.stageChunk(chunk, in: fileDiff)
                },
                onUnstage: { chunk in
                    viewModel.unstageChunk(chunk, in: fileDiff)
                },
                onReset: { chunk in
                    viewModel.resetChunk(chunk, in: fileDiff)
                }
            )
            .background(Color(.windowBackgroundColor))
//            .cornerRadius(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
        )
        .padding(8)       
    }
}


//
//#Preview {
//    FileDiffContainerView(
//        viewModel: GitViewModel(),
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
//        )
//    )
//}
