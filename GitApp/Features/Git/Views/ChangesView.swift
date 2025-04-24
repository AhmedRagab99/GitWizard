import SwiftUI
import Foundation

struct ChangesView: View {
     var viewModel: GitViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Changes", selection: $selectedTab) {
                Text("Staged").tag(0)
                Text("Unstaged").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            // Content
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if selectedTab == 0 {
                            stagedChangesView
                        } else {
                            unstagedChangesView
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var stagedChangesView: some View {
        Group {
            if let stagedDiff = viewModel.stagedDiff, !stagedDiff.fileDiffs.isEmpty {
                ForEach(stagedDiff.fileDiffs) { fileDiff in
                    FileDiffView(
                        fileDiff: fileDiff,
                        onStage: { chunk in
                            viewModel.unstageChunk(chunk, in: fileDiff)
                        },
                        onUnstage: { chunk in
                            viewModel.stageChunk(chunk, in: fileDiff)
                        },
                        onReset: { chunk in
                            viewModel.resetChunk(chunk, in: fileDiff)
                        }
                    )
                }
            } else {
                Text("No staged changes")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }

    private var unstagedChangesView: some View {
        Group {
            if let unstagedDiff = viewModel.unstagedDiff, !unstagedDiff.fileDiffs.isEmpty {
                ForEach(unstagedDiff.fileDiffs) { fileDiff in
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
                }
            } else {
                Text("No unstaged changes")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
}

