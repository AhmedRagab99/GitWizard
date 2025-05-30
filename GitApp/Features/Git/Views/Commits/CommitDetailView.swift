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
    @State private var expandedFileID: FileDiff.ID?
    @State private var isLoadingContent: Bool = true
    @Bindable var viewModel: GitViewModel
    var onClose: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            if isLoadingContent {
                loadingView
            } else {
                mainContentView
            }
        }
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 5)
        .animation(.default, value: isLoadingContent)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isLoadingContent = false
            }
        }
        .onDisappear {
            viewModel.selectedMergeCommit = nil
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.5)
            Text("Loading commit details...").foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }

    private var mainContentView: some View {
        VStack(spacing: 0) {
            CommitDetailHeader(
                commit: commit,
                refs: commit.branches,
                viewModel: viewModel,
                onClose: onClose
            )
            .padding([.horizontal, .top])
            .padding(.bottom, 8)
            .background(Material.bar)
            .zIndex(1)

            contentBodyView.layoutPriority(1)
        }
    }

    @ViewBuilder
    private var contentBodyView: some View {
        ZStack {
            Color(.textBackgroundColor).ignoresSafeArea()

            if commit.isMergeCommit && viewModel.isMergeDetailsVisible {
                mergeDetailsFlowView.transition(.opacity.animation(.easeInOut))
            } else if let validDetails = details {
                fileChangesListView(details: validDetails).transition(.opacity.animation(.easeInOut))
            } else {
                noChangesView.transition(.opacity.animation(.easeInOut))
            }
        }
    }

    private var noChangesView: some View {
        Text("No changes to display")
            .font(.headline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var mergeDetailsFlowView: some View {
        if let selectedMergeCommit = viewModel.selectedMergeCommit, let mergeCommitDetails = details {
            selectedMergeCommitDetailView(commit: selectedMergeCommit, details: mergeCommitDetails)
        } else {
            mergedCommitsListView
        }
    }

    private func selectedMergeCommitDetailView(commit: Commit, details: CommitDetails) -> some View {
        VStack(spacing: 0) {
            mergeNavigationHeader(title: commit.shortHash) {
                withAnimation(.spring()) { viewModel.selectedMergeCommit = nil }
            }
            Divider()
            fileChangesListView(details: details)
        }
    }

    private var mergedCommitsListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: "Commits in this merge", count: viewModel.mergeCommits.count, icon: "arrow.triangle.merge")
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.mergeCommits) { mergeCommit in
                        RefactoredMergeCommitRow(commit: mergeCommit) {
                            Task { await viewModel.selectMergeCommit(mergeCommit) }
                        }
                        if mergeCommit.id != viewModel.mergeCommits.last?.id {
                            Divider().padding(.leading, 20)
                        }
                    }
                }
            }
        }
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
        .padding()
    }

    private func fileChangesListView(details: CommitDetails) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                sectionHeader(title: "Changed files", count: details.diff.fileDiffs.count, icon: "doc.on.doc")
                    .padding(.top, 12)

                ForEach(details.diff.fileDiffs) { fileDiff in
                    FileChangeSection(
                        fileDiff: fileDiff,
                        viewModel: viewModel,
                        isExpanded: fileDiff.id == expandedFileID
                    )
                    .padding(.horizontal)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            expandedFileID = (expandedFileID == fileDiff.id) ? nil : fileDiff.id
                        }
                    }
                }
                Spacer().frame(height: 20)
            }
        }
    }

    private func mergeNavigationHeader(title: String, backAction: @escaping () -> Void) -> some View {
        HStack {
            Button(action: backAction) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.caption.bold())
                    Text("Back to Merged Commits").font(.headline)
                }
            }.buttonStyle(.plain)
            Spacer()
            Text(title)
                .font(.caption.monospaced())
                .foregroundColor(.secondary)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding()
        .background(Material.bar)
    }

    private func sectionHeader(title: String, count: Int, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.accentColor)
            Text(title).font(.headline)
            Spacer()
            if count > 0 {
                Text("\(count) \(count == 1 ? "item" : "items")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.horizontal)
    }
}

private struct RefactoredMergeCommitRow: View {
    let commit: Commit
    let onSelect: () -> Void
    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: commit.commitType.commitIcon.name)
                    .foregroundStyle(commit.commitType.commitIcon.color)
                    .font(.system(size: 22))
                    .frame(width: 24, alignment: .center)

                VStack(alignment: .leading, spacing: 3) {
                    Text(commit.title).font(.subheadline.weight(.medium)).lineLimit(1)
                    HStack(spacing: 4) {
                        AuthorAvatarView(avatarURLString: commit.authorAvatar)
                        Text(commit.author).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                        Text("•").font(.caption2).foregroundColor(.secondary)
                        Text(commit.authorDateDisplay).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                    }
                }
                Spacer()
                Text(commit.shortHash)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background(isHovered ? Color.accentColor.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in isHovered = hovering }
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}

struct LineRow: View {
    let line: LineChange

    var body: some View {
        HStack(spacing: 0) {
            // Line number
            Text("\(line.lineNumber)")
                .font(.caption)
                .frame(width: 40, alignment: .trailing)
                .padding(.horizontal, 4)
                .foregroundColor(.secondary)
                .background(Color(NSColor.headerColor))

            // Line content with appropriate color based on change type
            Text(line.content)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(backgroundColorForLine(line))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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


