//
//  LineChangeView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//



import SwiftUI
struct LineChangeView: View {
    let change: LineChange
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Line number
            Text("\(change.lineNumber)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
                .padding(.trailing, 8)

            // Change indicator
            Text(change.type == .added ? "+" : change.type == .removed ? "-" : " ")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(change.type == .added ? .green : change.type == .removed ? .red : .secondary)
                .frame(width: 20)

            // Content
            Text(change.content)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(change.type == .added ? .green : change.type == .removed ? .red : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}