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

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(fileDiff.status.color.opacity(0.18))
                    .frame(width: 28, height: 28)
                Image(systemName: fileDiff.status.icon)
                    .foregroundStyle(fileDiff.status.color)
                    .font(.system(size: 15, weight: .medium))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(fileDiff.fromFilePath.components(separatedBy: "/").last ?? "")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                Text(fileDiff.fromFilePath)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            // Line stats
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
            StatusBadge(status: fileDiff.status)
            Button(action: action) {
                Image(systemName: actionIcon)
                    .foregroundStyle(actionColor)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0.7)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : (isHovered ? Color.accentColor.opacity(0.08) : Color(.windowBackgroundColor).opacity(0.7)))
                .shadow(color: isSelected ? Color.accentColor.opacity(0.10) : .clear, radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color(.systemGray).opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .onHover { hovering in isHovered = hovering }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(fileDiff.fromFilePath), status: \(fileDiff.status.rawValue)")
    }
}
