//
//  CommitDetailView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import Foundation

struct CommitDetailView: View {
    let commit: Commit
    let details: CommitDetails?
    @State private var expandedFile: FileDiff?
    @State private var isLoading = true
    @Bindable var viewModel: GitViewModel
    @State private var detailHeight: CGFloat = 480 // Increased default height
    var onClose: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else {
                contentView
            }
        }
        .frame(height: detailHeight)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
        .animation(.easeOut(duration: 0.25), value: detailHeight)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = false
            }
        }
        .onDisappear {
            viewModel.selectedMergeCommit = nil
        }
    }

    private var loadingView: some View {
        CenteredContentMessage(
            systemImage: "hourglass",
            title: "",
            message: "Loading commit details..."
        )
    }

    private var contentView: some View {
        VStack(spacing: 0) {
            // Header Section
            CommitDetailHeader(
                commit: commit,
                refs: commit.branches,
                viewModel: viewModel,
                onClose: onClose
            )
            .zIndex(10)

            // Content
            ZStack {
                // Background
                Color(.textBackgroundColor)
                    .ignoresSafeArea()

                // Content based on commit type
                if commit.isMergeCommit && viewModel.isMergeDetailsVisible {
                    mergeCommitsView
                        .transition(.opacity)
                } else if let details = details {
                    fileChangesView(details: details)
                        .transition(.opacity)
                } else {
                    CenteredContentMessage(
                        systemImage: "doc.text.magnifyingglass",
                        title: "No Changes",
                        message: "No changes to display for this commit"
                    )
                }
            }
        }
    }

    private var mergeCommitsView: some View {
        VStack(spacing: 0) {
            if let selectedMergeCommit = viewModel.selectedMergeCommit, let details = details {
                // Show selected merge commit changes with a header for navigation
                VStack(spacing: 0) {
                    // Back to merge commits header
                    Card(cornerRadius: 8, shadowRadius: 1) {
                        HStack {
                            Button(action: {
                                withAnimation(.spring()) {
                                    viewModel.selectedMergeCommit = nil
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.caption.bold())
                                    Text("Back to Merged Commits")
                                        .font(.headline)
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Text(selectedMergeCommit.shortHash)
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }

                    Divider()

                    // File changes
                    fileChangesView(details: details)
                }
            } else {
                // Show list of commits in the merge
                Card(padding: .init(top: 0, leading: 0, bottom: 0, trailing: 0)) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack {
                            Image(systemName: "arrow.triangle.merge")
                                .foregroundColor(.blue)
                            Text("Commits included in this merge")
                                .font(.headline)

                            Spacer()

                            CountBadge(
                                count: viewModel.mergeCommits.count,
                                textColor: .secondary,
                                backgroundColor: Color.secondary.opacity(0.1)
                            )
                        }
                        .padding()
                        .background(Color(.windowBackgroundColor))

                        Divider()

                        // List of commits
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(viewModel.mergeCommits) { mergeCommit in
                                    MergeCommitRow(
                                        commit: mergeCommit,
                                        onSelect: {
                                            Task {
                                                await viewModel.selectMergeCommit(mergeCommit)
                                            }
                                        }
                                    )
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                    .background(Color(.textBackgroundColor))

                                    if mergeCommit.id != viewModel.mergeCommits.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    private func fileChangesView(details: CommitDetails) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                // Files header
                HStack {
                    Text("Changed files")
                        .font(.headline)
                    Spacer()
                    Text("\(details.diff.fileDiffs.count) files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
                .padding(.horizontal)
                .padding(.top, 12)

                // Files
                ForEach(details.diff.fileDiffs) { file in
                    FileChangeSection(
                        fileDiff: file,
                        viewModel: viewModel,
                        isExpanded: file.id == expandedFile?.id
                    )
                    .onTapGesture {
                        withAnimation(.spring()) {
                            if expandedFile?.id == file.id {
                                expandedFile = nil
                            } else {
                                expandedFile = file
                            }
                        }
                    }
                }

                // Bottom padding
                Spacer().frame(height: 20)
            }
            .padding(.horizontal)
        }
    }
}

// New component for displaying merged commits
struct MergeCommitRow: View {
    let commit: Commit
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ListRow(
                padding: EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
                cornerRadius: 8,
                shadowRadius: 0
            ) {
                HStack(spacing: 12) {
                    // Commit icon
                    Image(systemName: commit.commitType.commitIcon.name)
                        .foregroundColor(commit.commitType.commitIcon.color)
                        .font(.system(size: 24))
                        .frame(width: 24)

                    // Commit info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(commit.message)
                            .font(.headline)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            // Author with avatar
                            if let avatarURL = URL(string: commit.authorAvatar) {
                                AsyncImage(url: avatarURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.crop.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 16, height: 16)
                                .clipShape(Circle())
                            }

                            Text(commit.author)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            // Date
                            Text(commit.authorDateRelative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Hash and navigate icon
                    HStack {
                        Text(commit.shortHash)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct LineRow: View {
    let line: LineChange

    var body: some View {
        ListRow(
            padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
            backgroundColor: backgroundColorForLine(line),
            cornerRadius: 0,
            shadowRadius: 0
        ) {
            HStack(spacing: 0) {
                // Line number
                Text("\(line.lineNumber)")
                    .font(.caption)
                    .frame(width: 40, alignment: .trailing)
                    .padding(.horizontal, 4)
                    .foregroundColor(.secondary)
                    .background(Color(.headerColor))

                // Line content with appropriate color based on change type
                Text(line.content)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func backgroundColorForLine(_ line: LineChange) -> Color {
        switch line.type {
        case .added:
            return Color.green.opacity(0.2)
        case .removed:
            return Color.red.opacity(0.2)
        case .unchanged:
            return Color.clear
        }
    }
}


