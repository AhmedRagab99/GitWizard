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
    var isStaged: Bool = false

    // Computed property for better file name display logic
    private var fileName: String {
        fileDiff.fromFilePath.isEmpty ? (fileDiff.toFilePath.components(separatedBy: "/").last ?? fileDiff.toFilePath) : (fileDiff.fromFilePath.components(separatedBy: "/").last ?? fileDiff.fromFilePath)
    }

    private var filePath: String {
        fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath
    }

    var body: some View {
        HStack(spacing: 14) {
            statusIconView
            fileInfoView
            Spacer()
            lineStatsView
            StatusBadge(status: fileDiff.status)
            actionButtonView
        }
        .padding(10)
        .background(rowBackground)
        .overlay(rowOverlay)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in isHovered = hovering }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(filePath), status: \(fileDiff.status.rawValue)")
        .help(accessibilityHelpText)
        .contextMenu(menuItems: menuItems)
    }

    // MARK: - Subviews & Computed Properties for Readability

    private var statusIconView: some View {
        ZStack {
            Circle()
                .fill(fileDiff.status.color.opacity(0.18))
                .frame(width: 28, height: 28)
            Image(systemName: fileDiff.status.icon)
                .foregroundStyle(fileDiff.status.color)
                .font(.system(size: 15, weight: .medium))
        }
    }

    private var fileInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(fileName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(filePath)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    @ViewBuilder
    private var lineStatsView: some View {
        if fileDiff.lineStats.added > 0 {
            Text("+\(fileDiff.lineStats.added)")
                .font(.caption2.bold())
                .foregroundStyle(.green)
                .padding(.horizontal, 4)
        }
        if fileDiff.lineStats.removed > 0 {
            Text("-\(fileDiff.lineStats.removed)")
                .font(.caption2.bold())
                .foregroundStyle(.red)
                .padding(.horizontal, 4)
        }
    }

    private var actionButtonView: some View {
        Button(action: action) {
            Image(systemName: actionIcon)
                .foregroundStyle(actionColor)
                .font(.system(size: 18))
        }
        .buttonStyle(.plain)
        .opacity(isHovered || isSelected ? 1 : 0.7)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isSelected ? Color.accentColor.opacity(0.18) : (isHovered ? Color.accentColor.opacity(0.08) : Color(.windowBackgroundColor).opacity(0.7)))
            .shadow(color: isSelected ? Color.accentColor.opacity(0.10) : .clear, radius: 2, x: 0, y: 1)
    }

    private var rowOverlay: some View {
        RoundedRectangle(cornerRadius: 10)
            .strokeBorder(isSelected ? Color.accentColor : Color(.systemGray).opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
    }

    private var accessibilityHelpText: String {
        """
        Status: \(fileDiff.status.rawValue) (\(fileDiff.status.shortDescription))
        Path: \(filePath)
        Lines Added: \(fileDiff.lineStats.added)
        Lines Removed: \(fileDiff.lineStats.removed)
        """
    }

    // MARK: - Context Menu Items
    @ViewBuilder
    private func menuItems() -> some View {
        if let onStage = onStage {
            ContextMenuButton(label: "Stage File", systemImage: "plus.circle", action: onStage)
        }
        if let onUnstage = onUnstage {
            ContextMenuButton(label: "Unstage File", systemImage: "minus.circle", action: onUnstage)
        }
        if let onReset = onReset {
            ContextMenuButton(label: "Reset File (Discard Changes)", systemImage: "arrow.counterclockwise", role: .destructive, action: onReset)
        }
        Divider()
        if let onIgnore = onIgnore {
            ContextMenuButton(label: "Add to .gitignore", systemImage: "eye.slash", action: onIgnore)
        }
        if let onTrash = onTrash {
            ContextMenuButton(label: "Move to Trash", systemImage: "trash", role: .destructive, action: onTrash)
        }
        Divider()
        ContextMenuButton(label: "Copy Path", systemImage: "doc.on.clipboard") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(filePath, forType: .string)
        }
    }
}

// Helper for context menu buttons to reduce repetition
 struct ContextMenuButton: View {
    let label: String
    let systemImage: String
    var role: ButtonRole? = nil
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            Label(label, systemImage: systemImage)
        }
    }
}

// Ensure FileDiff, FileStatus, LineStats, and StatusBadge types are correctly defined and imported.
// It's assumed FileDiff has `id`, `displayName`, `fullPath`, `status`, `lineStats`, `header`.
// FileStatus has `color`, `icon`, `rawValue`, `shortDescription`.
// LineStats has `added`, `removed`.
