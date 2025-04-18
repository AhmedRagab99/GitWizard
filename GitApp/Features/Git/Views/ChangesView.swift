import SwiftUI

struct ChangesView: View {
    @ObservedObject var viewModel: GitViewModel
    @State private var commitMessage: String = ""
    @State private var selectedFile: FileChange?
    @State private var selectedFileChange: FileChange?
    @State private var showingCommitSheet = false

    var body: some View {
        HStack {
            // Left side - File list
            VStack {
                List(selection: $selectedFile) {
                    Section("Staged Changes") {
                        ForEach(viewModel.stagedChanges) { file in
                            FileChangeRow(file: file)
                                .onTapGesture {
                                    selectedFileChange = file
                                }
                        }
                    }

                    Section("Unstaged Changes") {
                        ForEach(viewModel.unstagedChanges) { file in
                            FileChangeRow(file: file)
                                .onTapGesture {
                                    selectedFileChange = file
                                }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 200, maxWidth: 300)

            // Right side - File content
            if let file = selectedFileChange {
                FileContentView(file: file, viewModel: viewModel)
            } else {
                Text("Select a file to view changes")
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            await viewModel.loadChanges()
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: { showingCommitSheet = true }) {
                    Label("Commit", systemImage: "checkmark.circle")
                }
                .disabled(viewModel.stagedChanges.isEmpty)

                Button(action: { viewModel.stageAllChanges() }) {
                    Label("Stage All", systemImage: "plus.circle")
                }
                .disabled(viewModel.unstagedChanges.isEmpty)

                Button(action: { viewModel.unstageAllChanges() }) {
                    Label("Unstage All", systemImage: "minus.circle")
                }
                .disabled(viewModel.stagedChanges.isEmpty)
            }
        }
        .sheet(isPresented: $showingCommitSheet) {
            CommitSheet(viewModel: viewModel, commitMessage: $commitMessage)
        }
    }
}

struct FileChangeRow: View {
    let file: FileChange

    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)

            VStack(alignment: .leading) {
                Text(file.name)
                    .lineLimit(1)
                Text(file.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(file.stagedChanges.count + file.unstagedChanges.count)")
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.secondary.opacity(0.2))
                .clipShape(Capsule())
        }
    }

    private var statusIcon: String {
        switch file.status {
        case "Added": return "plus.circle.fill"
        case "Modified": return "pencil.circle.fill"
        case "Deleted": return "minus.circle.fill"
        default: return "doc.circle.fill"
        }
    }

    private var statusColor: Color {
        switch file.status {
        case "Added": return .green
        case "Modified": return .blue
        case "Deleted": return .red
        default: return .secondary
        }
    }
}



