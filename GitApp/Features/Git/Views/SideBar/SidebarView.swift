//
//  SidebarView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI
import Foundation

struct SidebarView: View {
    @Bindable var viewModel: GitViewModel
    @State private var expandedGroups: Set<SidebarSection> = [.branches]
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""

    enum SidebarSection: String, CaseIterable {
        case branches = "Branches"
        case tags = "Tags"
        case stashes = "Stashes"
        case remotes = "Remotes"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    // Repository Info
                    repositoryInfo

                    // Groups
                    LazyVStack(alignment: .leading, spacing: 16) {
                        branchesGroup
                        remotesGroup
                        tagsGroup
                        stashesGroup
                    }
                }
                .padding()
            }
            .background(Color(.textBackgroundColor))

            // Search Bar
            searchBar
                .padding()
                .background(Color(.windowBackgroundColor))
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.textBackgroundColor))
        )
    }

    private var repositoryInfo: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            if let currentBranch = viewModel.currentBranch {
                LazyHStack(spacing: 12) {
                    Image(systemName: "gitbranch")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Branch")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(currentBranch.name)
                            .font(.headline)
                    }
                }
            }
        }
    }

    private func groupHeader(_ title: String, section: SidebarSection) -> some View {
        LazyHStack {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    if expandedGroups.contains(section) {
                        expandedGroups.remove(section)
                    } else {
                        expandedGroups.insert(section)
                    }
                }
            }) {
                Image(systemName: expandedGroups.contains(section) ? "chevron.down" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                if expandedGroups.contains(section) {
                    expandedGroups.remove(section)
                } else {
                    expandedGroups.insert(section)
                }
            }
        }
    }

    private func filteredBranches() -> [Branch] {
        if searchText.isEmpty {
            return viewModel.branches
        }
        return viewModel.branches.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func filteredRemotes() -> [Branch] {
        if searchText.isEmpty {
            return viewModel.remotebranches
        }
        return viewModel.remotebranches.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func filteredTags() -> [Tag] {
        if searchText.isEmpty {
            return viewModel.tags
        }
        return viewModel.tags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func filteredStashes() -> [Stash] {
        if searchText.isEmpty {
            return viewModel.stashes
        }
        return viewModel.stashes.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
    }

    @ViewBuilder
    private var branchesGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupHeader("Local Branches", section: .branches)

            if expandedGroups.contains(.branches) {
                let filtered = filteredBranches()
                if filtered.isEmpty {
                    emptyStateView(message: searchText.isEmpty ? "No branches" : "No matching branches")
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { branch in
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
    }

    @ViewBuilder
    private var remotesGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupHeader("Remotes", section: .remotes)

            if expandedGroups.contains(.remotes) {
                let filtered = filteredRemotes()
                if filtered.isEmpty {
                    emptyStateView(message: searchText.isEmpty ? "No remotes" : "No matching remotes")
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { remote in
                            RemoteRowView(remote: Remote(name: remote.name))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var tagsGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupHeader("Tags", section: .tags)

            if expandedGroups.contains(.tags) {
                let filtered = filteredTags()
                if filtered.isEmpty {
                    emptyStateView(message: searchText.isEmpty ? "No tags" : "No matching tags")
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { tag in
                            TagRowView(tag: tag)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var stashesGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            groupHeader("Stashes", section: .stashes)

            if expandedGroups.contains(.stashes) {
                let filtered = filteredStashes()
                if filtered.isEmpty {
                    emptyStateView(message: searchText.isEmpty ? "No stashes" : "No matching stashes")
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { stash in
                            StashRowView(stash: stash)
                        }
                    }
                }
            }
        }
    }

    private func emptyStateView(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 16)
    }
}

// MARK: - Row Views
struct BranchRowView: View {
    let branch: Branch
    let isCurrent: Bool
    let onSelect: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCurrent ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isCurrent ? .green : .secondary)
                .frame(width: 24, height: 24)

            Text(branch.name)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrent ? Color.accentColor.opacity(0.1) :
                      isHovered ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture(count: 2) {
            onSelect()
        }
        .contextMenu {
            Button(action: onSelect) {
                Label("Checkout", systemImage: "arrow.triangle.branch")
            }
            .disabled(isCurrent)
        }
    }
}

struct TagRowView: View {
    let tag: Tag
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tag")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.orange)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(tag.name)
                    .font(.body)
                Text(tag.commitHash)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct StashRowView: View {
    let stash: Stash
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "archivebox")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.purple)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(stash.message)
                    .font(.body)
                Text("#\(stash.index)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct RemoteRowView: View {
    let remote: Remote
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cloud")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(remote.name)
                    .font(.body)
                Text(remote.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
