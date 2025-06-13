//
//  CommitRowView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//


import SwiftUI
import Foundation

struct CommitRowView: View {
    let commit: Commit
    let isSelected: Bool
    let onSelect: () -> Void
    var onCopyHash: (() -> Void)?
    var onCheckout: (() -> Void)?
    var onCreateBranch: (() -> Void)?
    var onCreateTag: (() -> Void)?
    var onRevert: (() -> Void)?

    var body: some View {
        ListRow(
            isSelected: isSelected,
            padding: EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12),
            onTap: onSelect,
            cornerRadius: 0,
            shadowRadius: 1
        ) {
            HStack(spacing: 12) {
                // Commit icon based on type
                Image(systemName: commit.commitType.commitIcon.name)
                    .foregroundColor(commit.commitType.commitIcon.color)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    // Commit message
                    Text(commit.title)
                        .font(.headline)
                        .lineLimit(1)

                    // Commit metadata
                    HStack {
                        if let avatarURL = URL(string: commit.authorAvatar) {
                            AsyncImage(url: avatarURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.secondary)
                                .frame(width: 20, height: 20)
                        }

                        Text(commit.author)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(commit.authorDateDisplay)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Commit hash
                Text(commit.hash.prefix(7))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .withContextMenu(type: .commit(
            onCopy: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(commit.hash, forType: .string)
                onCopyHash?()
            },
            onCheckout: {
                onCheckout?()
            },
            onCreateBranch: {
                onCreateBranch?()
            },
            onCreateTag: onCreateTag,
            onRevert: onRevert
        ))
    }
}
