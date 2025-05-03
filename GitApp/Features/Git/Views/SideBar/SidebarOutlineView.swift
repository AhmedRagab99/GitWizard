import SwiftUI
import AppKit
import Foundation




indirect enum SidebarItem: Identifiable, Equatable {
    static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool { lhs.id == rhs.id }
    case workspace(WorkspaceSidebarItem)
    case branch(BranchNode)
    case remote(BranchNode)
    case tag(Tag)
    case section(String)
    var id: String {
        switch self {
        case .workspace(let w): return "workspace-\(w.id)"
        case .branch(let b): return "branch-\(b.id)"
        case .remote(let r): return "remote-\(r.id)"
        case .tag(let t): return "tag-\(t.id)"
        case .section(let s): return "section-\(s)"
        }
    }
    var children: [SidebarItem]? {
        switch self {
        case .branch(let node): return node.children?.map { .branch($0) }
        case .remote(let node): return node.children?.map { .remote($0) }
        default: return nil
        }
    }
    var isExpandable: Bool { children != nil }
}

// MARK: - SwiftUI Wrapper
struct SidebarOutlineView: NSViewControllerRepresentable {
    var items: [SidebarItem]
    @Binding var selectedItem: SidebarItem?
    func makeNSViewController(context: Context) -> SidebarOutlineViewController {
        let controller = SidebarOutlineViewController()
        controller.items = items
        controller.onSelect = { item in selectedItem = item }
        return controller
    }
    func updateNSViewController(_ nsViewController: SidebarOutlineViewController, context: Context) {
        nsViewController.items = items
        nsViewController.reloadSidebar()
    }
}

// MARK: - NSViewController with NSOutlineView
class SidebarOutlineViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    var outlineView: NSOutlineView!
    var scrollView: NSScrollView!
    var items: [SidebarItem] = []
    var onSelect: ((SidebarItem?) -> Void)?
    override func loadView() {
        self.view = NSView()
        scrollView = NSScrollView()
        outlineView = NSOutlineView()
        outlineView.headerView = nil
        outlineView.rowSizeStyle = .large
        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.selectionHighlightStyle = .regular
        outlineView.backgroundColor = NSColor(named: "SidebarBackground") ?? NSColor(calibratedRed: 23/255, green: 34/255, blue: 56/255, alpha: 1)
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("main"))
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    func reloadSidebar() {
        DispatchQueue.main.async {
            self.outlineView.reloadData()
        }
    }
    // MARK: - NSOutlineViewDataSource
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        let children = childrenFor(item)
        return children.count
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let sidebarItem = item as? SidebarItem else { return false }
        return sidebarItem.isExpandable
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let children = childrenFor(item)
        return children[index]
    }
    func childrenFor(_ item: Any?) -> [SidebarItem] {
        if let sidebarItem = item as? SidebarItem {
            return sidebarItem.children ?? []
        } else {
            return items
        }
    }
    // MARK: - NSOutlineViewDelegate
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let sidebarItem = item as? SidebarItem else { return nil }
        switch sidebarItem {
        case .section(let title):
            return sectionHeaderView(title: title)
        case .workspace(let item):
            return sidebarCell(
                icon: item.icon,
                text: item.rawValue,
                selected: isSelected(sidebarItem),
                iconColor: .systemGray,
                textColor: isSelected(sidebarItem) ? .white : .labelColor,
                highlight: isSelected(sidebarItem),
                indent: outlineView.level(forItem: item)
            )
        case .branch(let node):
            let isHead = node.branch?.isCurrent == true
            return sidebarCell(
                icon: node.isFolder ? "folder.fill" : "arrow.triangle.branch",
                text: node.name,
                selected: isSelected(sidebarItem),
                iconColor: .systemGray,
                textColor: .labelColor,
                highlight: isSelected(sidebarItem),
                badge: isHead ? "HEAD" : nil,
                indent: outlineView.level(forItem: item)
            )
        case .remote(let node):
            return sidebarCell(
                icon: node.isFolder ? "folder.fill" : "arrow.triangle.branch",
                text: node.name,
                selected: isSelected(sidebarItem),
                iconColor: .systemGray,
                textColor: .labelColor,
                highlight: isSelected(sidebarItem),
                indent: outlineView.level(forItem: item)
            )
        case .tag(let tag):
            return sidebarCell(
                icon: "tag",
                text: tag.name,
                selected: isSelected(sidebarItem),
                iconColor: .systemGray,
                textColor: .systemBlue,
                highlight: isSelected(sidebarItem),
                indent: outlineView.level(forItem: item)
            )
        }
    }
    func isSelected(_ item: SidebarItem) -> Bool {
        guard let row = outlineView.row(forItem: item) as Int?, row >= 0 else { return false }
        return outlineView.selectedRowIndexes.contains(row)
    }
    // MARK: - Private UI Helpers
    private func sectionHeaderView(title: String) -> NSView {
        let header = NSTableCellView()
        let label = NSTextField(labelWithString: title.uppercased())
        label.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = NSColor.secondaryLabelColor
        label.backgroundColor = .clear
        label.isBordered = false
        label.isBezeled = false
        label.isEditable = false
        header.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            label.topAnchor.constraint(equalTo: header.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -2)
        ])
        return header
    }
    private func sidebarCell(icon: String, text: String, selected: Bool, iconColor: NSColor, textColor: NSColor, highlight: Bool, badge: String? = nil, indent: Int = 0) -> NSView {
        let cell = NSTableCellView()
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 6, left: CGFloat(20 + indent * 18), bottom: 6, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false
        // Icon with background circle
        let iconContainer = NSView()
        iconContainer.wantsLayer = true
        iconContainer.layer?.cornerRadius = 7.5
        // Optionally add a subtle background for selected
        let iconView = NSImageView(image: NSImage(systemSymbolName: icon, accessibilityDescription: nil) ?? NSImage())
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        iconView.contentTintColor = iconColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconView)
        iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor).isActive = true
        iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor).isActive = true
        iconContainer.widthAnchor.constraint(equalToConstant: 28).isActive = true
        iconContainer.heightAnchor.constraint(equalToConstant: 28).isActive = true
        stack.addArrangedSubview(iconContainer)
        // Label
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 15, weight: selected ? .semibold : .medium)
        label.textColor = textColor
        label.backgroundColor = .clear
        label.isBordered = false
        label.isBezeled = false
        label.isEditable = false
        label.lineBreakMode = .byTruncatingTail
        stack.addArrangedSubview(label)
        // Modern pill badge
        if let badge = badge {
            let badgeView = modernPillBadge(text: badge)
            stack.addArrangedSubview(badgeView)
        }
        cell.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
            stack.topAnchor.constraint(equalTo: cell.topAnchor),
            stack.bottomAnchor.constraint(equalTo: cell.bottomAnchor)
        ])
        cell.wantsLayer = true
        cell.layer?.cornerRadius = 9
        cell.layer?.backgroundColor = highlight ? NSColor.systemBlue.withAlphaComponent(0.18).cgColor : NSColor.clear.cgColor
        return cell
    }
    // Modern pill badge helper
    private func modernPillBadge(text: String) -> NSView {
        let badgeContainer = NSView()
        badgeContainer.wantsLayer = true
        badgeContainer.layer?.cornerRadius = 10
        badgeContainer.layer?.borderWidth = 1
        badgeContainer.layer?.masksToBounds = true
        // Style for HEAD badge
        let isHead = (text.uppercased() == "HEAD")
        badgeContainer.layer?.backgroundColor = (isHead ? NSColor.systemBlue.withAlphaComponent(0.13) : NSColor.quaternaryLabelColor.withAlphaComponent(0.18)).cgColor
        badgeContainer.layer?.borderColor = (isHead ? NSColor.systemBlue.cgColor : NSColor.separatorColor.cgColor)
        // Text
        let badgeLabel = NSTextField(labelWithString: text)
        badgeLabel.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        badgeLabel.textColor = isHead ? NSColor.systemBlue : NSColor.labelColor
        badgeLabel.backgroundColor = .clear
        badgeLabel.isBordered = false
        badgeLabel.isBezeled = false
        badgeLabel.isEditable = false
        badgeLabel.alignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeContainer.addSubview(badgeLabel)
        // Padding
        NSLayoutConstraint.activate([
            badgeLabel.leadingAnchor.constraint(equalTo: badgeContainer.leadingAnchor, constant: 10),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeContainer.trailingAnchor, constant: -10),
            badgeLabel.topAnchor.constraint(equalTo: badgeContainer.topAnchor, constant: 2),
            badgeLabel.bottomAnchor.constraint(equalTo: badgeContainer.bottomAnchor, constant: -2),
            badgeContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ])
        return badgeContainer
    }
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = outlineView.selectedRow
        if selectedRow >= 0, let item = outlineView.item(atRow: selectedRow) as? SidebarItem {
            onSelect?(item)
        } else {
            onSelect?(nil)
        }
    }
}
