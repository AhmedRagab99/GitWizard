//
//  SidebarView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI
import Foundation

struct BranchNode: Identifiable {
    let id = UUID() // Unique ID for the list item
    let name: String // Name of the folder or branch segment
    var children: [BranchNode]? // Child nodes (folders or branches within this folder) - Use optional for leaf nodes
    var branch: Branch? = nil // The actual branch data, only set for leaf nodes

    // Convenience initializer for folder nodes
    init(name: String, children: [BranchNode] = []) {
        self.name = name
        // Only set children if the array is not empty, otherwise use nil for List's children detection
        self.children = children.isEmpty ? nil : children
        self.branch = nil
    }

    // Convenience initializer for leaf nodes (representing branches)
    init(branch: Branch) {
        // Leaf node name is derived from the last path component if '/' is present, otherwise full name
        self.name = branch.name.components(separatedBy: "/").last ?? branch.name
        self.children = nil // Leaf nodes have no children
        self.branch = branch
    }

    // Helper to determine if this node represents a folder (has children or is intended as a container)
    var isFolder: Bool {
        // A node is considered a folder if it explicitly has children
        // or if it doesn't represent a final branch leaf.
        return children != nil
    }
}

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
    @State private var expandedFolders: Set<String> = []

    var body: some View {

    VStack(alignment: .leading, spacing: 0) {

                // Workspace Section
                sectionHeader("Workspace", icon: "folder")
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
                .padding([.bottom,.leading], 8)

                // Branches Section (recursive tree)
                sectionHeader("Branches", icon: "point.topleft.down.curvedto.point.bottomright.up")
                let branchTree = buildBranchTreeRevised(from: viewModel.branches)
                BranchTreeView(branchNodes: branchTree)


                // Remotes Section
                sectionHeader("Remotes", icon: "cloud")
                let branchRemoteTree = buildBranchTreeRevised(from: viewModel.remotebranches)
                BranchTreeView(branchNodes: branchRemoteTree)




                // Tags Section
                sectionHeader("Tags", icon: "tag")
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
            }
        .frame(minWidth: 240)
    }

    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 2)
    }

    func buildBranchTreeRevised(from branches: [Branch]) -> [BranchNode] {
        // Temporary storage: Key = full folder path, Value = (Set<ChildFolderName>, [DirectChildBranches])
        var structure: [String: (subfolders: Set<String>, branches: [Branch])] = [:]
        var rootFolders = Set<String>()
        var rootBranches: [Branch] = []

        // Sort branches for consistent tree order
        let sortedBranches = branches.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }

        for branch in sortedBranches {
            let components = branch.name.components(separatedBy: "/")
            if components.count == 1 {
                // Root level branch
                rootBranches.append(branch)
                continue
            }

            // Nested branch: process folder structure
            var currentPath = ""
            for i in 0..<(components.count - 1) { // Iterate folder components
                let component = components[i]
                let parentPath = currentPath
                currentPath = currentPath.isEmpty ? component : "\(currentPath)/\(component)" // Build full path key

                // Ensure entry exists for the current folder path
                if structure[currentPath] == nil {
                    structure[currentPath] = (subfolders: Set(), branches: [])
                }

                // Register this folder as a subfolder of its parent
                if parentPath.isEmpty {
                    rootFolders.insert(component) // Mark as a top-level folder
                } else {
                     // Add component to parent's subfolder set
                     structure[parentPath]?.subfolders.insert(component)
                }

                // If this is the immediate parent folder of the branch leaf
                if i == components.count - 2 {
                    structure[currentPath]?.branches.append(branch) // Add branch to its parent's list
                }
            }
        }

        // --- Recursive Helper Function ---
        func createNodes(folderName: String, path: String) -> BranchNode {
            var childNodes: [BranchNode] = []
            // Use empty defaults if path somehow doesn't exist in structure
            let data = structure[path] ?? (subfolders: Set(), branches: [])

            // Create nodes for subfolders (sorted alphabetically)
            for subfolder in data.subfolders.sorted() {
                childNodes.append(createNodes(folderName: subfolder, path: "\(path)/\(subfolder)"))
            }

            // Create nodes for direct branches (already sorted)
            for branch in data.branches {
                childNodes.append(BranchNode(branch: branch)) // Leaf node
            }

            // Return the folder node
            return BranchNode(name: folderName, children: childNodes) // children will be nil if empty via init
        }
        // --- End Recursive Helper ---

        // Build the final list of root nodes
        var rootNodes: [BranchNode] = []

        // Add root folders (sorted alphabetically)
        for folderName in rootFolders.sorted() {
            rootNodes.append(createNodes(folderName: folderName, path: folderName))
        }

        // Add root branches (already sorted)
        for branch in rootBranches {
            rootNodes.append(BranchNode(branch: branch)) // Root leaf node
        }

        return rootNodes
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

struct BranchTreeView: View {
    let branchNodes: [BranchNode] // Root nodes
    var body: some View {

            List(branchNodes, children: \.children) { node in
                BranchNodeRow(node: node)
                    .tag(node.branch?.id)

            }
            .scrollDisabled(true)
            .scrollIndicators(.hidden)
    }
}

// MARK: - Simplified Row View

// This view ONLY draws the content of a single row.
// List(children:) handles the expansion and hierarchy.
struct BranchNodeRow: View {
    let node: BranchNode
    // No need to pass Binding down here if selection is handled by .tag

    // --- Styling Properties ---
    private var iconName: String { node.isFolder ? "folder.fill" : "arrow.triangle.branch" }
    private var iconColor: Color { node.isFolder ? .secondary : .accentColor }
    private var fontWeight: Font.Weight { node.branch?.isCurrent == true ? .semibold : .regular }

    var body: some View {
        // Just the HStack for the row's content
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16).foregroundColor(iconColor)
                .opacity(node.isFolder ? 0.7 : 1.0)

            Text(node.name) // Display name (folder or last part of branch)
                .fontWeight(fontWeight).lineLimit(1)
                .help(node.branch?.name ?? node.name) // Tooltip shows full name

            Spacer()

            if node.branch?.isCurrent == true {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green).font(.subheadline)
                    .help("Current Branch")
            }
        }
    }
}
