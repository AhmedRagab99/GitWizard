//
//  SidebarView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI
import Foundation
import GitApp

struct SidebarView: View {
    @ObservedObject var viewModel: GitViewModel
    @State private var filterText: String = ""
    @State private var expandedBranches: Set<String> = ["feature"]
    @FocusState private var isSearchFocused: Bool

    private var filteredBranches: [Branch] {
        if filterText.isEmpty {
            return viewModel.branches
        }
        return viewModel.branches.filter { branch in
            branch.name.localizedCaseInsensitiveContains(filterText) ||
            branch.displayName.localizedCaseInsensitiveContains(filterText)
        }
    }

    private func toggleBranch(_ branch: String) {
        if expandedBranches.contains(branch) {
            expandedBranches.remove(branch)
        } else {
            expandedBranches.insert(branch)
        }
    }

    private func groupBranches(_ branches: [Branch]) -> [String: [Branch]] {
        var groups: [String: [Branch]] = [:]

        for branch in branches {
            let components = branch.name.components(separatedBy: "/")
            if components.count > 1 {
                let groupName = components[0]
                groups[groupName, default: []].append(branch)
            } else {
                groups["", default: []].append(branch)
            }
        }

        return groups
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar with cloud sync status
            HStack {
                Text("Workspace")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "cloud.fill")
                        .foregroundColor(.secondary)
                }
                Button(action: {}) {
                    Image(systemName: "externaldrive.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            List(selection: $viewModel.selectedSidebarItem) {
                // Workspace section
                Section {
                    ForEach(SidebarItem.WorkspaceItem.allCases, id: \.self) { item in
                        HStack {
                            Image(systemName: item.icon)
                                .foregroundColor(item.color)
                            Text(item.rawValue)
                        }
                        .tag(SidebarItem.workspace(item))
                    }
                }

                // Branches section
                Section("Branches") {
                    let branchGroups = groupBranches(filteredBranches)

                    // Main branches
                    if let mainBranches = branchGroups[""] {
                        ForEach(mainBranches) { branch in
                            SidebarBranchView(
                                branch: branch,
                                isExpanded: false,
                                hasSubbranches: false,
                                viewModel: viewModel
                            )
                            .tag(SidebarItem.branch(branch))
                        }
                    }

                    // Grouped branches
                    ForEach(Array(branchGroups.keys.sorted().filter { $0 != "" }), id: \.self) { group in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedBranches.contains(group) },
                                set: { _ in toggleBranch(group) }
                            )
                        ) {
                            ForEach(branchGroups[group] ?? []) { branch in
                                SidebarBranchView(
                                    branch: branch,
                                    isExpanded: false,
                                    hasSubbranches: false,
                                    viewModel: viewModel
                                )
                                .tag(SidebarItem.branch(branch))
                            }
                        } label: {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                Text(group)
                            }
                        }
                    }
                }

                // Tags section
                Section("Tags") {
                    ForEach(viewModel.tags) { tag in
                        SidebarTagView(tag: tag)
                            .tag(SidebarItem.tag(tag))
                    }
                }

                // Remotes section
                if !viewModel.repoInfo.remotes.isEmpty {
                    Section("Remotes") {
                        ForEach(viewModel.repoInfo.remotes) { remote in
                            HStack {
                                Image(systemName: "network")
                                    .foregroundColor(.blue)
                                Text(remote.name)
                            }
                            .tag(SidebarItem.remote(remote.name))
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            // Modern search field at bottom
            VStack(spacing: 0) {
                Divider()
                    .padding(.bottom, 8)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(isSearchFocused ? .blue : .secondary)
                        .font(.system(size: 14))

                    TextField("Search branches...", text: $filterText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($isSearchFocused)

                    if !filterText.isEmpty {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                filterText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.windowBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSearchFocused ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(Color(.windowBackgroundColor))
        }
        .background(Color(.windowBackgroundColor))
    }
}
