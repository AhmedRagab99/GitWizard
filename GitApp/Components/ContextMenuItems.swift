import SwiftUI

/// A collection of commonly used context menu items
struct ContextMenuItems {
    enum MenuType {
        case file(onStage: () -> Void, onIgnore: (() -> Void)?, onRemove: (() -> Void)?, filePath: String)
        case unstageFile(onUnstage: () -> Void, filePath: String)
        case repository(onOpen: () -> Void, onRemove: () -> Void)
        case branch(onCheckout: () -> Void, onRename: () -> Void, onMerge: () -> Void, onDelete: () -> Void, isCurrentBranch: Bool)
        case commit(onCopy: () -> Void, onCheckout: () -> Void, onCreateBranch: () -> Void, onCreateTag: (() -> Void)?, onRevert: (() -> Void)?)
        case pullRequest(onView: () -> Void, onClose: (() -> Void)?, onReopen: (() -> Void)?)
        case custom(items: [MenuItem])
    }

    struct MenuItem: Identifiable {
        let id = UUID()
        let label: String
        let icon: String
        let action: () -> Void
        let role: ButtonRole?
        let dividerAfter: Bool

        init(label: String, icon: String, action: @escaping () -> Void, role: ButtonRole? = nil, dividerAfter: Bool = false) {
            self.label = label
            self.icon = icon
            self.action = action
            self.role = role
            self.dividerAfter = dividerAfter
        }
    }

    /// Create a context menu with the specified type
    static func menu(type: MenuType) -> some View {
        Group {
            switch type {
            case let .file(onStage, onIgnore, onRemove, filePath):
                Button {
                    onStage()
                } label: {
                    Label("Stage File", systemImage: "plus.circle")
                }

                Divider()

                if let onIgnore = onIgnore {
                    Button {
                        onIgnore()
                    } label: {
                        Label("Add to .gitignore", systemImage: "eye.slash")
                    }
                }

                if let onRemove = onRemove {
                    Button(role: .destructive) {
                        onRemove()
                    } label: {
                        Label("Move to Trash", systemImage: "trash")
                    }
                }

                Divider()

                Button {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(filePath, forType: .string)
                } label: {
                    Label("Copy Path", systemImage: "doc.on.clipboard")
                }

            case let .unstageFile(onUnstage, filePath):
                Button {
                    onUnstage()
                } label: {
                    Label("Unstage File", systemImage: "minus.circle")
                }

                Divider()

                Button {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(filePath, forType: .string)
                } label: {
                    Label("Copy Path", systemImage: "doc.on.clipboard")
                }

            case let .repository(onOpen, onRemove):
                Button {
                    onOpen()
                } label: {
                    Label("Open Repo", systemImage: "folder")
                }

                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Remove from Recent", systemImage: "trash")
                }

            case let .branch(onCheckout, onRename, onMerge, onDelete, isCurrentBranch):
                if !isCurrentBranch {
                    Button {
                        onCheckout()
                    } label: {
                        Label("Checkout Branch", systemImage: "arrow.right")
                    }
                }

                Button {
                    onRename()
                } label: {
                    Label("Rename Branch", systemImage: "pencil")
                }

                if !isCurrentBranch {
                    Button {
                        onMerge()
                    } label: {
                        Label("Merge into Current Branch", systemImage: "arrow.triangle.merge")
                    }
                }

                if !isCurrentBranch {
                    Divider()

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete Branch", systemImage: "trash")
                    }
                }

            case let .commit(onCopy, onCheckout, onCreateBranch, onCreateTag, onRevert):
                Button {
                    onCopy()
                } label: {
                    Label("Copy Commit Hash", systemImage: "doc.on.clipboard")
                }

                Divider()

                Button {
                    onCheckout()
                } label: {
                    Label("Checkout Commit", systemImage: "arrow.right")
                }

                Button {
                    onCreateBranch()
                } label: {
                    Label("Create Branch from Here", systemImage: "plus.square.on.square")
                }

                if let onCreateTag = onCreateTag {
                    Button {
                        onCreateTag()
                    } label: {
                        Label("Create Tag", systemImage: "tag")
                    }
                }

                if let onRevert = onRevert {
                    Divider()

                    Button(role: .destructive) {
                        onRevert()
                    } label: {
                        Label("Revert Commit", systemImage: "arrow.uturn.backward")
                    }
                }

            case let .pullRequest(onView, onClose, onReopen):
                Button {
                    onView()
                } label: {
                    Label("View Pull Request", systemImage: "eye")
                }

                if let onClose = onClose {
                    Button(role: .destructive) {
                        onClose()
                    } label: {
                        Label("Close Pull Request", systemImage: "xmark.circle")
                    }
                }

                if let onReopen = onReopen {
                    Button {
                        onReopen()
                    } label: {
                        Label("Reopen Pull Request", systemImage: "arrow.clockwise.circle")
                    }
                }

            case let .custom(items):
                ForEach(items) { item in
                    Button(role: item.role) {
                        item.action()
                    } label: {
                        Label(item.label, systemImage: item.icon)
                    }

                    if item.dividerAfter {
                        Divider()
                    }
                }
            }
        }
    }
}

// Extension to make it easier to apply context menus
extension View {
    func withContextMenu(type: ContextMenuItems.MenuType) -> some View {
        self.contextMenu {
            ContextMenuItems.menu(type: type)
        }
    }
}
