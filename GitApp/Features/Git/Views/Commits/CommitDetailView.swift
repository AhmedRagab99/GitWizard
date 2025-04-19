//
//  CommitDetailView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI

struct CommitDetailView: View {
    let commit: Commit
    let details: GitViewModel.CommitDetails?
    @State private var expandedFile: FileChange?
    @State private var isLoading = true
    @ObservedObject var viewModel: GitViewModel

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                VStack(spacing: ModernUI.spacing) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Loading commit details...")
                        .foregroundColor(ModernUI.colors.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ModernUI.colors.background)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ModernUI.spacing, pinnedViews: [.sectionHeaders]) {
                        CommitDetailHeader(
                            commit: commit,
                            refs: details?.branchNames ?? [],
                            viewModel: viewModel
                        )

                        // Commit message
                        Text(commit.message)
                            .font(.system(.body))
                            .padding(ModernUI.padding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ModernUI.colors.background)
                            .cornerRadius(ModernUI.cornerRadius)
                            .modernShadow(.small)

                        if let details = details {
                            // Changed files section
                            Section {
                                ForEach(details.changedFiles) { file in
                                    FileChangeSection(
                                        fileChange: file,
                                        diffContent: details.diffContent,
                                        expandedFile: $expandedFile
                                    )
                                }
                            } header: {
                                HStack {
                                    Text("Changed Files")
                                        .font(.headline)
                                    Text("(\(details.changedFiles.count))")
                                        .foregroundColor(ModernUI.colors.secondaryText)
                                    Spacer()
                                }
                                .padding(ModernUI.padding)
                                .background(ModernUI.colors.background)
                            }
                        }
                    }
                    .padding(ModernUI.padding)
                }
            }
        }
        .background(ModernUI.colors.background)
        .onAppear {
            withAnimation(ModernUI.animation.delay(0.3)) {
                isLoading = false
            }
        }
    }
}

struct FileChangeRow: View {
    let file: FileChange

    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)

            Text(file.name)
                .lineLimit(1)

            Spacer()

            Text("\(file.stagedChanges.count + file.unstagedChanges.count)")
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.secondary.opacity(0.2))
                .clipShape(Capsule())
        }
        .padding(.horizontal, ModernUI.padding)
        .padding(.vertical, 4)
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
