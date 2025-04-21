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
    @State private var selectedSection: SidebarSection = .branches

    enum SidebarSection: String, CaseIterable {
        case branches = "Branches"
        case tags = "Tags"
        case stashes = "Stashes"
        case remotes = "Remotes"
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionPicker
            contentView
        }
    }

    private var sectionPicker: some View {
        Picker("Section", selection: $selectedSection) {
            ForEach(SidebarSection.allCases, id: \.self) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                switch selectedSection {
                case .branches:
                    branchesContent
                case .tags:
                    tagsContent
                case .stashes:
                    stashesContent
                case .remotes:
                    remotesContent
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var branchesContent: some View {
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

    @ViewBuilder
    private var tagsContent: some View {
        if viewModel.tags.isEmpty {
            emptyStateView(message: "No tags")
        } else {
            ForEach(viewModel.tags) { tag in
                TagRowView(tag: tag)
            }
        }
    }

    @ViewBuilder
    private var stashesContent: some View {
        if viewModel.stashes.isEmpty {
            emptyStateView(message: "No stashes")
        } else {
            ForEach(viewModel.stashes) { stash in
                StashRowView(stash: stash)
            }
        }
    }

    @ViewBuilder
    private var remotesContent: some View {
        if viewModel.remotebranches.isEmpty {
            emptyStateView(message: "No remotes")
        } else {
            ForEach(viewModel.remotebranches) { remote in
                RemoteRowView(remote: Remote(name: remote.name))
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

    var body: some View {
        HStack {
            Image(systemName: isCurrent ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCurrent ? .green : .secondary)
            Text(branch.name)
                .font(.body)
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
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
    }
}
