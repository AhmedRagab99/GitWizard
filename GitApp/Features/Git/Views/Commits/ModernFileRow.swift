//
//  ModernFileRow.swift
//  GitApp
//
//  Created by Ahmed Ragab on 10/05/2025.
//

import SwiftUI
// MARK: - Modern File Row
struct ModernFileRow: View {
    let fileDiff: FileDiff
    let isSelected: Bool
    let actionIcon: String
    let actionColor: Color
    let action: () -> Void
    @State private var isHovered: Bool = false
    var onStage: (() -> Void)? = nil
    var onUnstage: (() -> Void)? = nil
    var onReset: (() -> Void)? = nil
    var onIgnore: (() -> Void)? = nil
    var onTrash: (() -> Void)? = nil
    var onResolveWithMine: (() -> Void)? = nil
    var onResolveWithTheirs: (() -> Void)? = nil
    var onMarkAsResolved: (() -> Void)? = nil
    var isStaged: Bool = false

    var body: some View {
        ListRow(
            isSelected: isSelected,
            padding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10),
            onTap: nil, // We're handling tap with the outer view
            backgroundColor: isHovered ? Color.accentColor.opacity(0.08) : Color(.windowBackgroundColor).opacity(0.7),
            selectedBackgroundColor: Color.accentColor.opacity(0.18)
        ) {
            HStack(spacing: 14) {
                statusIcon
                fileInfo
                Spacer()
                rightSideContent
            }
        }
        .overlay(border)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .onHover { hovering in isHovered = hovering }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(fileDiff.fromFilePath), status: \(fileDiff.status.rawValue)")
        .help(helpText)
        .withContextMenu(type: createContextMenuType())
    }

    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(fileDiff.status.color.opacity(0.18))
                .frame(width: 28, height: 28)
            Image(systemName: fileDiff.status.icon)
                .foregroundStyle(fileDiff.status.color)
                .font(.system(size: 15, weight: .medium))
        }
    }

    private var fileInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath.components(separatedBy: "/").last ?? "" : fileDiff.fromFilePath.components(separatedBy: "/").last ?? "")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .primary : .secondary)
            Text(fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var rightSideContent: some View {
        if fileDiff.status == .conflict {
            conflictResolutionButtons
        } else {
            lineStatsView
        }
        StatusBadge(status: fileDiff.status)
        mainActionButton
    }

    private var conflictResolutionButtons: some View {
        HStack(spacing: 8) {
            Button(action: { onResolveWithMine?() }) {
                Label("Keep Mine", systemImage: "person.circle")
            }
            .help("Resolve conflict by keeping your changes")

            Button(action: { onResolveWithTheirs?() }) {
                Label("Take Theirs", systemImage: "person.2.circle")
            }
            .help("Resolve conflict by taking their changes")

            Button(action: { onMarkAsResolved?() }) {
                Label("Mark Resolved", systemImage: "checkmark.circle")
            }
            .help("Mark this file as resolved")
        }
        .buttonStyle(.bordered)
    }

    private var lineStatsView: some View {
        HStack {
            if fileDiff.lineStats.added > 0 {
                CountBadge(
                    count: fileDiff.lineStats.added,
                    prefix: "+",
                    textColor: .green,
                    backgroundColor: Color.green.opacity(0.12)
                )
            }
            if fileDiff.lineStats.removed > 0 {
                CountBadge(
                    count: fileDiff.lineStats.removed,
                    prefix: "-",
                    textColor: .red,
                    backgroundColor: Color.red.opacity(0.12)
                )
            }
        }
    }

    private var mainActionButton: some View {
        Button(action: action) {
            Image(systemName: actionIcon)
                .foregroundStyle(actionColor)
                .font(.system(size: 18))
        }
        .buttonStyle(.plain)
        .opacity(isHovered ? 1 : 0.7)
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(isSelected ? Color.accentColor : Color(.systemGray).opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
    }

    private var helpText: String {
        """
        Status: \(fileDiff.status.rawValue) (\(fileDiff.status.shortDescription))
        From: \(fileDiff.fromFilePath.isEmpty ? "None" : fileDiff.fromFilePath)
        To: \(fileDiff.toFilePath.isEmpty ? "None" : fileDiff.toFilePath)
        Lines Added: \(fileDiff.lineStats.added)
        Lines Removed: \(fileDiff.lineStats.removed)
        Header: \(fileDiff.header)
        """
    }

    private func createContextMenuType() -> ContextMenuItems.MenuType {
        // If this is a conflict file, create a custom menu with conflict resolution options
        if fileDiff.status == .conflict, let onResolveWithMine = onResolveWithMine,
           let onResolveWithTheirs = onResolveWithTheirs,
           let onMarkAsResolved = onMarkAsResolved {

            return .custom(items: [
                // Standard file operations
                ContextMenuItems.MenuItem(label: "Stage File", icon: "plus.circle", action: { onStage?() }),
                ContextMenuItems.MenuItem(label: "Reset File (Discard Changes)", icon: "arrow.counterclockwise", action: { onReset?() }, role: .destructive, dividerAfter: true),

                // Conflict resolution options
                ContextMenuItems.MenuItem(label: "Resolve: Keep My Version", icon: "person.circle", action: onResolveWithMine),
                ContextMenuItems.MenuItem(label: "Resolve: Take Their Version", icon: "person.2.circle", action: onResolveWithTheirs),
                ContextMenuItems.MenuItem(label: "Mark as Resolved", icon: "checkmark.circle", action: onMarkAsResolved, dividerAfter: true),

                // Additional file operations
                ContextMenuItems.MenuItem(label: "Add to .gitignore", icon: "eye.slash", action: { onIgnore?() }),
                ContextMenuItems.MenuItem(label: "Move to Trash", icon: "trash", action: { onTrash?() }, role: .destructive),
                ContextMenuItems.MenuItem(label: "Copy Path", icon: "doc.on.clipboard", action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath, forType: .string)
                })
            ])
        }
        // For staging area files
        else if isStaged, let onUnstage = onUnstage {
            return .unstageFile(
                onUnstage: onUnstage,
                filePath: fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath
            )
        }
        // For working copy files
        else if let onStage = onStage {
            return .file(
                onStage: onStage,
                onIgnore: onIgnore,
                onRemove: onTrash,
                filePath: fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath
            )
        }
        // Fallback - shouldn't happen but providing just in case
        else {
            return .custom(items: [
                ContextMenuItems.MenuItem(label: "Copy Path", icon: "doc.on.clipboard", action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath, forType: .string)
                })
            ])
        }
    }
}
