import SwiftUI

struct SwiftUISidebarView: View {
    let items: [SidebarItem]
    @Binding var selectedItem: SidebarItem?
    @Binding var selectedWorkspaceItem: WorkspaceSidebarItem
    // Add providers for context menus or specific actions if needed
    // var menuProvider: ((SidebarItem) -> Menu<Button<Label<Text, Image>>>)? = nil
    // var branchContextMenuProvider: ((BranchNode) -> Menu<Button<Label<Text, Image>>>)? = nil // Example

    var body: some View {
        // Use a List with hierarchical data support
        List(items, children: \.children, selection: $selectedItem) { item in
            rowView(for: item)
                .listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10)) // Adjust padding
                .onTapGesture {
                    if case let .workspace(workspaceItem) = item {
                        selectedWorkspaceItem = workspaceItem
                        selectedItem = .workspace(selectedWorkspaceItem)
                    }
                }
                // Add context menus if needed
                // .contextMenu {
                //     if let menu = menuProvider?(item) {
                //         menu
                //     }
                //     // Or provide specific menus based on type
                //     // if case .branch(let node) = item, let branchMenu = branchContextMenuProvider?(node) {
                //     //     branchMenu
                //     // }
                // }
        }
        .listStyle(.sidebar) // Use the sidebar list style for appropriate appearance
//        .background(Color(nsColor: NSColor(named: "SidebarBackground") ?? NSColor(calibratedRed: 23/255, green: 34/255, blue: 56/255, alpha: 1))) // Match background
    }

    // Helper function to create the appropriate view for each row type
    @ViewBuilder
    private func rowView(for item: SidebarItem) -> some View {
        let isSelected = selectedItem == item
        switch item {
        case .section(let title):
            SectionHeaderView(title: title)
                .padding(.leading, -2) // Adjust alignment if needed
                 .listRowSeparator(.hidden) // Hide separator for sections
        case .workspace(let workspaceItem):
            SidebarCellView(
                icon: workspaceItem.icon,
                text: workspaceItem.rawValue,
                isSelected: isSelected,
                iconColor: .secondary, // Use SwiftUI Color
                textColor: isSelected ? .white : .primary // Use SwiftUI Color
            )
        case .branch(let node):
            // You could potentially reuse SidebarBranchView here if its dependencies match
             SidebarCellView(
                 icon: node.isFolder ? "folder.fill" : "arrow.triangle.branch",
                 text: node.name,
                 isSelected: isSelected,
                 iconColor: .secondary,
                 textColor: isSelected ? .white : .primary,
                 badge: node.branch?.isCurrent ?? false ? "HEAD" : nil
             )
        case .remote(let node):
             SidebarCellView(
                 icon: node.isFolder ? "folder.fill" : "arrow.triangle.branch", // Or specific remote icon
                 text: node.name,
                 isSelected: isSelected,
                 iconColor: .secondary,
                 textColor: isSelected ? .white : .primary
             )
        case .tag(let tag):
            SidebarCellView(
                icon: "tag.fill", // Use filled version maybe
                text: tag.name,
                isSelected: isSelected,
                iconColor: .secondary,
                textColor: isSelected ? .white : .primary
            )
        }
    }
}

// MARK: - Helper Views (Replicating NSView components in SwiftUI)

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)

    }
}

struct SidebarCellView: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let iconColor: Color
    let textColor: Color
    var badge: String? = nil

    @Environment(\.colorScheme) var colorScheme // To potentially adjust colors

    private var selectedBackgroundColor: Color {
        // Approximating the NSView selection style
         Color.accentColor.opacity(0.2) // SwiftUI standard accent
    }
  


    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) { // Adjust spacing as needed
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                 // .fontWeight(.medium) // Adjust weight if needed
                .frame(width: 17, height: 17) // Match size from NSView if possible
                .foregroundColor(isSelected ? .accentColor : iconColor) // Use accent color when selected


            Text(text)
                .font(.system(size: 14, weight: isSelected ? .medium : .regular)) // Adjust font
                .foregroundColor(isSelected ? .primary : textColor) // Use primary when selected for better contrast
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer() // Push badge to the right

            if let badgeText = badge {
                ModernPillBadgeView(text: badgeText)
            }
        }
        .padding(.vertical, 5) // Adjust padding
        .padding(.horizontal, 8)
        .background(
             RoundedRectangle(cornerRadius: 6) // Adjust corner radius
                 .fill(isSelected ? selectedBackgroundColor : Color.clear)
        )       
    }
}

// Replicating the modern pill badge in SwiftUI
struct ModernPillBadgeView: View {
    let text: String

    private var isHead: Bool { text.uppercased() == "HEAD" }

    private var backgroundColor: Color {
        isHead ? Color.accentColor.opacity(0.15) : Color(nsColor: .quinaryLabel).opacity(0.18)
    }

    private var foregroundColor: Color {
        isHead ? Color.accentColor : Color.primary.opacity(0.8)
    }

    private var borderColor: Color {
        isHead ? Color.accentColor.opacity(0.8) : Color(nsColor: .separatorColor)
    }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold)) // Slightly smaller font
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 8) // Adjust padding
            .padding(.vertical, 3)
            .background(backgroundColor)
            .clipShape(Capsule()) // Use Capsule for pill shape
            .overlay(Capsule().stroke(borderColor, lineWidth: 1)) // Add border
    }
}
