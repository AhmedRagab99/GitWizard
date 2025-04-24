//
//  SidebarView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI
import Foundation
// Represents a single item in the sidebar list
struct SidebarItem: Identifiable,Equatable {
    static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool {
        return lhs.id == rhs.id
    }

    let id = UUID() // Unique identifier for the list
    var name: String
    var icon: String // SF Symbol name for the icon
    var isExpandable: Bool = false // Whether this item can be expanded
    var children: [SidebarItem]? = nil // Child items if expandable
    var isHead: Bool = false // Special flag for the 'HEAD' indicator
    var isSelected: Bool = false // To track selection state if needed
    var branch: Branch? = nil
    var tag: Tag? = nil
    var stash: Stash? = nil
    var remote: Remote? = nil

    // Helper to check if this item has children
    var hasChildren: Bool {
        children != nil && !children!.isEmpty
    }
}

// Represents a section in the sidebar
struct SidebarSection: Identifiable {
    let id = UUID()
    var title: String? // Optional title for the section (e.g., "Branches")
    var items: [SidebarItem]
}

// Represents a single row in the sidebar
struct SidebarRow: View {
    let item: SidebarItem
    @Binding var selection: SidebarItem.ID? // Bind to the selection state
    @Binding var expandedItems: Set<UUID>
    let onItemSelected: (SidebarItem) -> Void

    var body: some View {
        if item.isExpandable {
            // Use DisclosureGroup for expandable items
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedItems.contains(item.id) },
                    set: { isExpanded in
                        if isExpanded {
                            expandedItems.insert(item.id)
                        } else {
                            expandedItems.remove(item.id)
                        }
                    }
                ),
                content: {
                    // Recursively create rows for children
                    if let children = item.children {
                        ForEach(children) { childItem in
                            SidebarRow(
                                item: childItem,
                                selection: $selection,
                                expandedItems: $expandedItems,
                                onItemSelected: onItemSelected
                            )
                            .padding(.leading) // Indent child items
                        }
                    }
                },
                label: {
                    rowLabel // Use the common label view
                }
            )
            // Use the item's ID for the navigation tag
            .tag(item.id)

        } else {
            rowLabel
                .onTapGesture(count: 2) {
                    onItemSelected(item)
                }
        }
    }

    // Extracted view for the row's label content (icon, text, HEAD tag)
    private var rowLabel: some View {
        HStack {
            Image(systemName: item.icon)
                .foregroundColor(.accentColor) // Use accent color for icons
                .frame(width: 16) // Fixed width for alignment
            Text(item.name)
            Spacer() // Push HEAD tag to the right
            if item.isHead {
                Text("HEAD")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .foregroundColor(.white)
                    .background(Color.gray)
                    .cornerRadius(4)
            }
        }
    }
}

struct SidebarView: View {
     var viewModel: GitViewModel
    @State private var selection: SidebarItem.ID? = nil
    @State private var expandedItems = Set<UUID>()
    @State private var filterText = ""

    var body: some View {
        SideBarItemsView(
            sections: createSections(),
            selection: $selection,
            expandedItems: $expandedItems,
            onItemSelected: handleItemSelection
        )
        .searchable(text: $filterText, placement: .toolbar, prompt: "Filter")
    }

    private func createSections() -> [SidebarSection] {
        [
            createWorkspaceSection(),
            createBranchesSection(),
            createTagsSection(),
            createRemotesSection(),
            createStashesSection()
        ]
    }

    private func createWorkspaceSection() -> SidebarSection {
        SidebarSection(title: "Workspace", items: [
            SidebarItem(name: "Working Copy", icon: "folder"),
            SidebarItem(name: "History", icon: "clock"),
            SidebarItem(name: "Stashes", icon: "archivebox"),
            SidebarItem(name: "Pull Requests", icon: "arrow.triangle.branch"),
            SidebarItem(name: "Branches Review", icon: "list.bullet"),
            SidebarItem(name: "Settings", icon: "gear")
        ])
    }

    private func createBranchesSection() -> SidebarSection {
        // Group branches by their folder structure
        var folderStructure: [String: [Branch]] = [:]
        var rootBranches: [Branch] = []

        for branch in viewModel.branches {
            if branch.name.contains("/") {
                let components = branch.name.split(separator: "/")
                let folderPath = String(components.first!)
                folderStructure[folderPath, default: []].append(branch)
            } else {
                rootBranches.append(branch)
            }
        }

        // Create items for root branches
        var items: [SidebarItem] = rootBranches.map { branch in
            SidebarItem(
                name: branch.name,
                icon: "gitbranch",
                isHead: branch.name == viewModel.currentBranch?.name,
                branch: branch
            )
        }

        // Create folder items with their nested branches
        for (folder, branches) in folderStructure {
            let children = branches.map { branch in
                SidebarItem(
                    name: String(branch.name.split(separator: "/").last!),
                    icon: "gitbranch",
                    isHead: branch.name == viewModel.currentBranch?.name,
                    branch: branch
                )
            }

            items.append(SidebarItem(
                name: folder,
                icon: "folder",
                isExpandable: true,
                children: children
            ))
        }

        return SidebarSection(title: "Branches", items: items)
    }

    private func createTagsSection() -> SidebarSection {
        SidebarSection(title: "Tags", items:
            viewModel.tags.map { tag in
                SidebarItem(
                    name: tag.name,
                    icon: "tag",
                    tag: tag
                )
            }
        )
    }

    private func createRemotesSection() -> SidebarSection {
        SidebarSection(title: "Remotes", items:
            viewModel.remotebranches.map { remote in
                SidebarItem(
                    name: remote.name,
                    icon: "cloud",
                    remote: Remote(name: remote.name)
                )
            }
        )
    }

    private func createStashesSection() -> SidebarSection {
        SidebarSection(title: "Stashes", items:
            viewModel.stashes.map { stash in
                SidebarItem(
                    name: stash.message,
                    icon: "archivebox",
                    stash: stash
                )
            }
        )
    }

    private func handleItemSelection(_ item: SidebarItem) {
        if let branch = item.branch {
            Task {
                await viewModel.checkoutBranch(branch)
            }
        }
        // Handle other item types as needed
    }
}

struct SideBarItemsView: View {
    let sections: [SidebarSection]
    @Binding var selection: SidebarItem.ID?
    @Binding var expandedItems: Set<UUID>
    let onItemSelected: (SidebarItem) -> Void

    var body: some View {
        List(selection: $selection) {
            ForEach(sections) { section in
                if let title = section.title {
                    Section(header: Text(title).font(.caption).foregroundColor(.secondary)) {
                        ForEach(section.items) { item in
                            SidebarRow(
                                item: item,
                                selection: $selection,
                                expandedItems: $expandedItems,
                                onItemSelected: onItemSelected
                            )
                        }
                    }
                } else {
                    ForEach(section.items) { item in
                        SidebarRow(
                            item: item,
                            selection: $selection,
                            expandedItems: $expandedItems,
                            onItemSelected: onItemSelected
                        )
                    }
                }
            }
        }
        .listStyle(.sidebar)
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
