//
//  SidebarView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI
import Foundation

struct SidebarView: View {
    @ObservedObject var viewModel: GitViewModel
    @State private var expandedGroups: Set<SidebarSection> = [.branches]

    enum SidebarSection: String, CaseIterable {
        case branches = "Branches"
        case tags = "Tags"
        case stashes = "Stashes"
        case remotes = "Remotes"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Repository Info
                repositoryInfo
                    .padding(.bottom, 16)

                // Groups
                VStack(alignment: .leading, spacing: 0) {
                    branchesGroup
                    remotesGroup
                    tagsGroup
                    stashesGroup
                   
                }
                .background(Color(.windowBackgroundColor))
                .cornerRadius(8)
            }
            .padding()
        }
    }

    private var repositoryInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let currentBranch = viewModel.currentBranch {
                HStack {
                    Image(systemName: "gitbranch")
                        .foregroundColor(.blue)
                    Text(currentBranch.name)
                        .font(.headline)
                }
            }

            if let remote = viewModel.remotebranches.first {
                HStack {
                    Image(systemName: "cloud")
                        .foregroundColor(.blue)
                    Text(remote.name)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
    }

    private func groupHeader(_ title: String, section: SidebarSection) -> some View {
        HStack {
            Button(action: {
                withAnimation {
                    if expandedGroups.contains(section) {
                        expandedGroups.remove(section)
                    } else {
                        expandedGroups.insert(section)
                    }
                }
            }) {
                Image(systemName: expandedGroups.contains(section) ? "chevron.down" : "chevron.right")
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            if let count = countForSection(section) {
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                if expandedGroups.contains(section) {
                    expandedGroups.remove(section)
                } else {
                    expandedGroups.insert(section)
                }
            }
        }
    }

    private func countForSection(_ section: SidebarSection) -> Int? {
        switch section {
        case .branches:
            return viewModel.branches.count
        case .tags:
            return viewModel.tags.count
        case .stashes:
            return viewModel.stashes.count
        case .remotes:
            return viewModel.remotebranches.count
        }
    }

    @ViewBuilder
    private var branchesGroup: some View {
        VStack(alignment: .leading, spacing: 0) {
            groupHeader("Local Branches", section: .branches)

            if expandedGroups.contains(.branches) {
                if viewModel.branches.isEmpty {
                    emptyStateView(message: "No branches")
                } else {
                    ForEach(viewModel.branches) { branch in
                        BranchRowView(
                            branch: branch,
                            isCurrent: branch.name == viewModel.currentBranch?.name ?? "",
                            onSelect: {
                                Task {
                                    await viewModel.checkoutBranch(branch)
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var tagsGroup: some View {
        VStack(alignment: .leading, spacing: 0) {
            groupHeader("Tags", section: .tags)

            if expandedGroups.contains(.tags) {
                if viewModel.tags.isEmpty {
                    emptyStateView(message: "No tags")
                } else {
                    ForEach(viewModel.tags) { tag in
                        TagRowView(tag: tag)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var stashesGroup: some View {
        VStack(alignment: .leading, spacing: 0) {
            groupHeader("Stashes", section: .stashes)

            if expandedGroups.contains(.stashes) {
                if viewModel.stashes.isEmpty {
                    emptyStateView(message: "No stashes")
                } else {
                    ForEach(viewModel.stashes) { stash in
                        StashRowView(stash: stash)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var remotesGroup: some View {
        VStack(alignment: .leading, spacing: 0) {
            groupHeader("Remotes", section: .remotes)

            if expandedGroups.contains(.remotes) {
                if viewModel.remotebranches.isEmpty {
                    emptyStateView(message: "No remotes")
                } else {
                    ForEach(viewModel.remotebranches) { remote in
                        RemoteRowView(remote: Remote(name: remote.name))
                    }
                }
            }
        }
    }

    private func emptyStateView(message: String) -> some View {
        Text(message)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
}

// MARK: - Row Views
struct BranchRowView: View {
    let branch: Branch
    let isCurrent: Bool
    let onSelect: () -> Void
    @State private var showContextMenu = false

    var body: some View {
        HStack {
            Image(systemName: isCurrent ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCurrent ? .green : .secondary)
            Text(branch.name)
                .font(.body)
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onSelect()
        }
        .contextMenu {
            Button(action: onSelect) {
                Label("Checkout", systemImage: "arrow.triangle.branch")
            }
            .disabled(isCurrent)
        }
        .background(isCurrent ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }
}

struct TagRowView: View {
    let tag: Tag

    var body: some View {
        HStack {
            Image(systemName: "tag")
                .foregroundColor(.orange)
            Text(tag.name)
                .font(.body)
            Spacer()
            Text(tag.commitHash)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
    }
}

struct StashRowView: View {
    let stash: Stash

    var body: some View {
        HStack {
            Image(systemName: "archivebox")
                .foregroundColor(.purple)
            Text(stash.message)
                .font(.body)
            Spacer()
            Text("#\(stash.index)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
    }
}

struct RemoteRowView: View {
    let remote: Remote

    var body: some View {
        HStack {
            Image(systemName: "cloud")
                .foregroundColor(.blue)
            Text(remote.name)
                .font(.body)
            Spacer()
            Text(remote.url)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
    }
}
