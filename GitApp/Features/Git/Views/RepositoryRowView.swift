//
//  RepositoryRowView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 05/06/2025.
//

import SwiftUI
struct RepositoryRowView: View {
    let url: URL
    let isSelected: Bool
    let onOpen: () -> Void
    let onRemove: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 25, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                Text(url.lastPathComponent.replacingOccurrences(of: ".git", with: ""))
                    .font(.headline)
                    .fontWeight(.medium)
                Text(url.deletingLastPathComponent().path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.init(nsColor: .selectedContentBackgroundColor).opacity(0.5) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onOpen()
        }
        .contextMenu {
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
        }
    }
}
