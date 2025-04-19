import SwiftUI

struct ChangesView: View {
    @ObservedObject var viewModel: GitViewModel
    @State private var commitMessage: String = ""
    @State private var selectedFile: FileChange?
    @State private var selectedFileChange: FileChange?
    @State private var showingCommitSheet = false
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Top section - File list
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Button(action: { showingCommitSheet = true }) {
                        Label("Commit", systemImage: "checkmark.circle")
                    }
                    .disabled(viewModel.stagedChanges.isEmpty)

                    Spacer()

                    Button(action: { viewModel.stageAllChanges() }) {
                        Label("Stage All", systemImage: "plus.circle")
                    }
                    .disabled(viewModel.unstagedChanges.isEmpty)

                    Button(action: { viewModel.unstageAllChanges() }) {
                        Label("Unstage All", systemImage: "minus.circle")
                    }
                    .disabled(viewModel.stagedChanges.isEmpty)
                }
                .padding()
                .background(ModernUI.colors.background)

                // File list
                List(selection: $selectedFile) {
                    if !viewModel.stagedChanges.isEmpty {
                        Section("Staged Changes") {
                            ForEach(viewModel.stagedChanges) { file in
                                FileChangeRow(file: file)
                                    .onTapGesture {
                                        selectedFileChange = file
                                    }
                            }
                        }
                    }

                    if !viewModel.unstagedChanges.isEmpty {
                        Section("Unstaged Changes") {
                            ForEach(viewModel.unstagedChanges) { file in
                                FileChangeRow(file: file)
                                    .onTapGesture {
                                        selectedFileChange = file
                                    }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minHeight: 200)

            // Bottom section - File content
            if let file = selectedFileChange {
                VStack(spacing: 0) {
                    // File header
                    HStack {
                        Text(file.name)
                            .font(.headline)
                        Spacer()
                        Text("\(file.stagedChanges.count + file.unstagedChanges.count) changes")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(ModernUI.colors.background)

                    // File content
                    FileContentView(file: file, viewModel: viewModel)
                }
                .frame(minHeight: 200)
            } else {
                Text("Select a file to view changes")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ModernUI.colors.background)
            }
        }
        .task {
            await viewModel.loadChanges()
        }
        .sheet(isPresented: $showingCommitSheet) {
            CommitSheet(viewModel: viewModel, commitMessage: $commitMessage)
        }
    }
}
