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

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(FileStatus.untracked.color.opacity(0.18))
                    .frame(width: 28, height: 28)
                Image(systemName: FileStatus.untracked.icon)
                    .foregroundStyle(FileStatus.untracked.color)
                    .font(.system(size: 15, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(path.components(separatedBy: "/").last ?? "")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(path)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            StatusBadge(status: .untracked)

            Button(action: action) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0.7)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.accentColor.opacity(0.08) : Color(.windowBackgroundColor).opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray).opacity(0.18), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in isHovered = hovering }
        .contextMenu {
            Button {
                action()
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

            if let onTrash = onTrash {
                Button(role: .destructive) {
                    onTrash()
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
            }

            Divider()

            Button {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(path, forType: .string)
            } label: {
                Label("Copy Path", systemImage: "doc.on.clipboard")
            }
        }
    }
}
