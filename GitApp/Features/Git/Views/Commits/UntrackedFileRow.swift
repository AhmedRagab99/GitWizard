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
        ListRow(
            padding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10),
            backgroundColor: isHovered ? Color.accentColor.opacity(0.08) : Color(.windowBackgroundColor).opacity(0.7)
        ) {
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
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray).opacity(0.18), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in isHovered = hovering }
        .withContextMenu(type: .file(
            onStage: action,
            onIgnore: onIgnore,
            onRemove: onTrash,
            filePath: path
        ))
    }
}
