import SwiftUI

struct FileDiffContainerView: View {
     var viewModel: GitViewModel
    let fileDiff: FileDiff

    var body: some View {
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
        .navigationTitle(fileDiff.filePathDisplay)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: {
                        viewModel.stageChunk(fileDiff.chunks.first!, in: fileDiff)
                    }) {
                        Label("Stage All", systemImage: "plus.circle")
                    }

                    Button(action: {
                        viewModel.unstageChunk(fileDiff.chunks.first!, in: fileDiff)
                    }) {
                        Label("Unstage All", systemImage: "minus.circle")
                    }

                    Button(action: {
                        viewModel.resetChunk(fileDiff.chunks.first!, in: fileDiff)
                    }) {
                        Label("Reset All", systemImage: "arrow.uturn.backward.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
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
