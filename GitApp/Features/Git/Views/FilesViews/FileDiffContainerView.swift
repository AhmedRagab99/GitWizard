import SwiftUI

struct FileDiffContainerView: View {
    @Bindable var viewModel: GitViewModel
    let fileDiff: FileDiff

    // Determine if this file is staged based on where it appears in the view model
    private var isFileStaged: Bool {
        guard let stagedDiff = viewModel.stagedDiff else { return false }
        return stagedDiff.fileDiffs.contains { $0.id == fileDiff.id }
    }

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

                if fileDiff.status == .conflict {
                    ConflictResolutionButtons(fileDiff: fileDiff, viewModel: viewModel)
                } else {
                    // Stats for non-conflict files
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
                },
                onResolveOurs: fileDiff.status == .conflict ? { chunk in
                    // Resolve using "our" changes
                    let path = fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath
                    Task { await viewModel.resolveConflictUsingOurs(filePath: path) }
                } : nil,
                onResolveTheirs: fileDiff.status == .conflict ? { chunk in
                    // Resolve using "their" changes
                    let path = fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath
                    Task { await viewModel.resolveConflictUsingTheirs(filePath: path) }
                } : nil,
                onMarkResolved: fileDiff.status == .conflict ? { chunk in
                    // Mark as resolved after manual edits
                    let path = fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath
                    Task { await viewModel.markConflictResolved(filePath: path) }
                } : nil,
                isStaged: isFileStaged
            )
            .background(Color(.windowBackgroundColor))
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
        )
        .padding(8)
    }
}

struct ConflictResolutionButtons: View {
    let fileDiff: FileDiff
    @Bindable var viewModel: GitViewModel

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                Button("Keep Our Changes") {
                    let path = fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath
                    Task { await viewModel.resolveConflictUsingOurs(filePath: path) }
                }

                Button("Keep Their Changes") {
                    let path = fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath
                    Task { await viewModel.resolveConflictUsingTheirs(filePath: path) }
                }

                Divider()

                Button("Mark as Resolved") {
                    let path = fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath
                    Task { await viewModel.markConflictResolved(filePath: path) }
                }
            } label: {
                Text("Resolve")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
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
