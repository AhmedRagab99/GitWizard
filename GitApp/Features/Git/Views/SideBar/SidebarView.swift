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
    @State private var filterText: String = ""
    @State private var expandedBranches: Set<String> = ["feature"]

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
                    let branchGroups = groupBranches(viewModel.branches)

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
                        if let groupBranches = branchGroups[group] {
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { expandedBranches.contains(group) },
                                    set: { _ in toggleBranch(group) }
                                )
                            ) {
                                ForEach(groupBranches) { branch in
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
                        ForEach(viewModel.repoInfo.remotes, id: \.name) { remote in
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

            // Filter bar at bottom
            FilterBarView(filterText: $filterText) {
                // Add button action
            }
            .background(Color(.windowBackgroundColor))
        }
        .background(Color(.windowBackgroundColor))
    }
}
