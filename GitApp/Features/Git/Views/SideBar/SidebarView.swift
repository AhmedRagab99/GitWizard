//
//  SidebarView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI
import Foundation

// Workspace items for the top section
enum WorkspaceSidebarItem: String, CaseIterable, Identifiable {
    case workingCopy = "Working Copy"
    case history = "History"
    case stashes = "Stashes"
    case pullRequests = "Pull Requests"
    case branchesReview = "Branches Review"
    case settings = "Settings"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .workingCopy: return "folder"
        case .history: return "clock"
        case .stashes: return "archivebox"
        case .pullRequests: return "arrow.triangle.branch"
        case .branchesReview: return "point.topleft.down.curvedto.point.bottomright.up"
        case .settings: return "gearshape"
        }
    }
}

struct SidebarView: View {
    @Bindable var viewModel: GitViewModel
    @Binding var selectedWorkspaceItem: WorkspaceSidebarItem
    @State private var filterText: String = ""
    @State private var expandedFeature: Bool = true

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.windowBackgroundColor))
                .shadow(radius: 2)

            VStack(alignment: .leading, spacing: 0) {
                // Workspace Section
                sectionHeader("Workspace")
                ForEach(WorkspaceSidebarItem.allCases) { item in
                    let isSelected = selectedWorkspaceItem == item
                    Button(action: { selectedWorkspaceItem = item }) {
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .foregroundColor(isSelected ? .accentColor : .blue.opacity(0.7))
                            Text(item.rawValue)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundColor(isSelected ? .primary : .blue.opacity(0.8))
                            Spacer()
                        }
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 8)

                // Branches Section
                sectionHeader("Branches")
                ForEach(viewModel.branches) { branch in
                    if branch.name == "feature" {
                        // Feature folder
                        DisclosureGroup(isExpanded: $expandedFeature) {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(viewModel.branches.filter { $0.name.hasPrefix("feature/") }) { featureBranch in
                                    branchRow(featureBranch, indent: 34)
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "folder")
                                    .foregroundColor(.blue.opacity(0.7))
                                Text("feature")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 18)
                        }
                        .padding(.bottom, 2)
                    } else if !branch.name.hasPrefix("feature/") {
                        branchRow(branch, indent: 22)
                    }
                }

               
                // Remotes Section
                sectionHeader("Remotes")
                ForEach(viewModel.remotebranches, id: \.name) { remote in
                    HStack(spacing: 10) {
                        Image(systemName: "cloud")
                            .foregroundColor(.blue.opacity(0.7))
                        Text(remote.name)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 22)
                }
                
                // Tags Section
                sectionHeader("Tags")
                ForEach(viewModel.tags, id: \.name) { tag in
                    HStack(spacing: 10) {
                        Image(systemName: "tag")
                            .foregroundColor(.blue.opacity(0.7))
                        Text(tag.name)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 22)
                }


                Spacer()

                // Filter Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Filter", text: $filterText)
                        .textFieldStyle(.plain)
                        .font(.body)
                    Button(action: {
                        // Add new remote/tag/branch logic
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .padding(.top, 8)
        }
        .frame(minWidth: 240)
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 2)
    }

    @ViewBuilder
    private func branchRow(_ branch: Branch, indent: CGFloat) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                .foregroundColor(.blue.opacity(0.7))
            Text(branch.name.replacingOccurrences(of: "feature/", with: ""))
                .fontWeight(branch.isCurrent ? .bold : .regular)
                .foregroundColor(.primary)
                .lineLimit(1)
            if branch.isCurrent {
                BadgeView(text: "HEAD")
            }
            Spacer()
        }
        .padding(.vertical, 5)
        .padding(.leading, indent)
        .padding(.trailing, 8)
    }
}

struct BadgeView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(.systemGray))
            .cornerRadius(6)
            .foregroundColor(.primary)
    }
}
