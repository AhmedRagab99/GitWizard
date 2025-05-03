import SwiftUI
import AppKit


// MARK: - SwiftUI Wrapper
struct SidebarOutlineView: NSViewControllerRepresentable {
    var items: [SidebarItem]
    @Binding var selectedItem: SidebarItem?

    var menuProvider: ((SidebarItem) -> NSMenu?)? = nil
    var branchCellProvider: ((BranchNode, Bool) -> NSView)? = nil

    func makeNSViewController(context: Context) -> SidebarOutlineViewController {
        let controller = SidebarOutlineViewController()
        controller.items = items
        controller.selectedItem = selectedItem
        controller.menuProvider = menuProvider
        controller.branchCellProvider = branchCellProvider
        controller.onSelect = { item in selectedItem = item }
        return controller
    }
    func updateNSViewController(_ nsViewController: SidebarOutlineViewController, context: Context) {
        nsViewController.items = items
        nsViewController.selectedItem = selectedItem
        nsViewController.menuProvider = menuProvider
        nsViewController.branchCellProvider = branchCellProvider
        nsViewController.reloadSidebar()
    }
    static func dismantleNSViewController(_ nsViewController: SidebarOutlineViewController, coordinator: ()) {
        // No-op
    }
    class Coordinator {
        var lastReloadTrigger: Int = 0
    }
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    func didUpdateNSViewController(_ nsViewController: SidebarOutlineViewController, context: Context) {
        let last = context.coordinator.lastReloadTrigger

    }
}

// MARK: - NSViewController with NSOutlineView
class SidebarOutlineViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    var outlineView: NSOutlineView!
    var scrollView: NSScrollView!
    var items: [SidebarItem] = []
    var selectedItem: SidebarItem? = nil
    var onSelect: ((SidebarItem?) -> Void)?
    var menuProvider: ((SidebarItem) -> NSMenu?)? = nil
    var branchCellProvider: ((BranchNode, Bool) -> NSView)? = nil

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
        let isSelected = isSelected(sidebarItem)
        switch sidebarItem {
        case .section(let title):
            return sectionHeaderView(title: title)
        case .workspace(let item):
            return sidebarCell(
                icon: item.icon,
                text: item.rawValue,
                selected: isSelected,
                iconColor: .systemGray,
                textColor: isSelected ? .white : .labelColor,
                highlight: isSelected,
                indent: outlineView.level(forItem: item)
            )
        case .branch(let node):
            if let branchCellProvider = branchCellProvider {
                return branchCellProvider(node, isSelected)
            }
            let isHead = node.branch?.isCurrent == true
            return sidebarCell(
                icon: node.isFolder ? "folder.fill" : "arrow.triangle.branch",
                text: node.name,
                selected: isSelected,
                iconColor: .systemGray,
                textColor: .labelColor,
//                highlight: isSelected,
                badge: isHead ? "HEAD" : nil,
                indent: outlineView.level(forItem: item)
            )
        case .remote(let node):
            return sidebarCell(
                icon: node.isFolder ? "folder.fill" : "arrow.triangle.branch",
                text: node.name,
                selected: isSelected,
                iconColor: .systemGray,
                textColor: .labelColor,
//                highlight: isSelected,
                indent: outlineView.level(forItem: item)
            )
        case .tag(let tag):
            return sidebarCell(
                icon: "tag",
                text: tag.name,
                selected: isSelected,
                iconColor: .systemGray,
                textColor: .labelColor,
                highlight: isSelected,
                indent: outlineView.level(forItem: item)
            )
        }
    }
    func isSelected(_ item: SidebarItem) -> Bool {
        return item.id == selectedItem?.id
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
    private func sidebarCell(icon: String, text: String, selected: Bool, iconColor: NSColor, textColor: NSColor, highlight: Bool = false, badge: String? = nil, indent: Int = 0) -> NSView {
        let cell = NSTableCellView()
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 6, bottom: 6, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false
        // Icon with background circle
        let iconContainer = NSView()
        iconContainer.wantsLayer = true
        iconContainer.layer?.cornerRadius = 7.5
        let iconView = NSImageView(image: NSImage(systemSymbolName: icon, accessibilityDescription: nil) ?? NSImage())
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        iconView.contentTintColor = selected ? NSColor.systemBlue : iconColor
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
        label.textColor = selected ? NSColor.systemBlue : textColor
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
        cell.layer?.backgroundColor = selected ? NSColor.systemBlue.withAlphaComponent(0.18).cgColor : NSColor.clear.cgColor
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
        }
    }
    // MARK: - Context Menu
    override func rightMouseDown(with event: NSEvent) {
        let point = outlineView.convert(event.locationInWindow, from: nil)
        let row = outlineView.row(at: point)
        guard row >= 0, let item = outlineView.item(atRow: row) as? SidebarItem else {
            super.rightMouseDown(with: event)
            return
        }
        if let menu = menuProvider?(item) {
            NSMenu.popUpContextMenu(menu, with: event, for: outlineView)
        } else {
            super.rightMouseDown(with: event)
        }
    }
}
