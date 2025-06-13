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
        ListRow(
            isSelected: isSelected,
            padding: EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8),
            onTap: onOpen
        ) {
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
        }
        .withContextMenu(type: .repository(
            onOpen: onOpen,
            onRemove: onRemove
        ))
    }
}
