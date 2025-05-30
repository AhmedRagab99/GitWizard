//
//  UntrackedFileRow.swift
//  GitApp
//
//  Created by Ahmed Ragab on 10/05/2025.
//

import SwiftUI

// MARK: - Untracked File Row
struct UntrackedFileRow: View {
    let path: String
    let action: () -> Void
    var onIgnore: (() -> Void)? = nil
    var onTrash: (() -> Void)? = nil
    @State private var isHovered = false

    // Computed properties for display
    private var fileName: String {
        path.components(separatedBy: "/").last ?? path
    }

    private var fileStatus: FileStatus { .untracked } // Explicitly define status for clarity

    var body: some View {
        HStack(spacing: 14) {
            statusIconView
            fileInfoView
            Spacer()
            StatusBadge(status: fileStatus)
            actionButtonView
        }
        .padding(10)
        .background(rowBackground)
        .overlay(rowOverlay)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in isHovered = hovering }
        .contextMenu(menuItems: menuItems)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(fileName), Untracked")
        .help("Path: \(path)")
    }

    // MARK: - Subviews & Computed Properties

    private var statusIconView: some View {
        ZStack {
            Circle()
                .fill(fileStatus.color.opacity(0.18))
                .frame(width: 28, height: 28)
            Image(systemName: fileStatus.icon)
                .foregroundStyle(fileStatus.color)
                .font(.system(size: 15, weight: .medium))
        }
    }

    private var fileInfoView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(fileName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(path)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private var actionButtonView: some View {
        Button(action: action) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 18))
        }
        .buttonStyle(.plain)
        .opacity(isHovered ? 1 : 0.7)
        .help("Stage File")
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isHovered ? Color.accentColor.opacity(0.08) : Color(.windowBackgroundColor).opacity(0.7))
    }

    private var rowOverlay: some View {
        RoundedRectangle(cornerRadius: 10)
            .strokeBorder(Color(.systemGray).opacity(0.18), lineWidth: 1)
    }

    // MARK: - Context Menu Items
    @ViewBuilder
    private func menuItems() -> some View {
        ContextMenuButton(label: "Stage File", systemImage: "plus.circle", action: action)

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
            NSPasteboard.general.setString(path, forType: .string)
        }
    }
}

// Assuming ContextMenuButton is defined (e.g., from ModernFileRow refactoring or a shared utility file)
// private struct ContextMenuButton: View { ... }

// Ensure FileStatus and StatusBadge are defined and provide necessary properties (color, icon).
// For FileStatus.untracked specifically.
