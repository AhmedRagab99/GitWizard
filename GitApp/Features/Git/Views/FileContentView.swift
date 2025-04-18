//
//  FileContentView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI

struct FileContentView: View {
    let file: FileChange
    @ObservedObject var viewModel: GitViewModel
    @State private var selectedLines: Set<UUID> = []
    @State private var showStagedOnly = false
    @State private var showUnstagedOnly = false

    var body: some View {
        VStack {
            // File header
            HStack {
                Text(file.name)
                    .font(.headline)
                Spacer()
                Text("\(file.stagedChanges.count + file.unstagedChanges.count) changes")
                    .foregroundStyle(.secondary)
            }
            .padding()

            // Filter controls
            HStack {
                Picker("Filter", selection: $showStagedOnly) {
                    Text("All Changes").tag(false)
                    Text("Staged Only").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)

                Spacer()
            }
            .padding(.horizontal)

            // Changes content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if showStagedOnly {
                        ForEach(file.stagedChanges) { change in
                            LineChangeView(
                                change: change,
                                isSelected: selectedLines.contains(change.id),
                                onSelect: { toggleLine(change) }
                            )
                        }
                    } else {
                        ForEach(file.lineChanges) { change in
                            LineChangeView(
                                change: change,
                                isSelected: selectedLines.contains(change.id),
                                onSelect: { toggleLine(change) }
                            )
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: { stageSelectedLines() }) {
                    Label("Stage", systemImage: "plus.circle")
                }
                .disabled(selectedLines.isEmpty)

                Button(action: { unstageSelectedLines() }) {
                    Label("Unstage", systemImage: "minus.circle")
                }
                .disabled(selectedLines.isEmpty)

                Button(action: { resetSelectedLines() }) {
                    Label("Reset", systemImage: "arrow.uturn.backward.circle")
                }
                .disabled(selectedLines.isEmpty)
            }
        }
    }

    private func toggleLine(_ line: LineChange) {
        if selectedLines.contains(line.id) {
            selectedLines.remove(line.id)
        } else {
            selectedLines.insert(line.id)
        }
    }

    private func stageSelectedLines() {
        viewModel.stageLines(selectedLines, in: file)
        selectedLines.removeAll()
    }

    private func unstageSelectedLines() {
        viewModel.unstageLines(selectedLines, in: file)
        selectedLines.removeAll()
    }

    private func resetSelectedLines() {
        viewModel.resetLines(selectedLines, in: file)
        selectedLines.removeAll()
    }
}
