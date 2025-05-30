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


    var body: some View {
        HStack(spacing: 12) {
            commitIcon
            commitDetails
            Spacer()
            commitHashView
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }

    // MARK: - Subviews

    private var commitIcon: some View {
        Image(systemName: commit.commitType.commitIcon.name)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(commit.commitType.commitIcon.color)
            .font(.title3)
            .frame(width: 24, alignment: .center)
    }

    private var commitDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(commit.title)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
            authorAndDateInfo
        }
    }

    private var authorAndDateInfo: some View {
        HStack(spacing: 6) {
            AuthorAvatarView(avatarURLString: commit.authorAvatar)
            Text(commit.author)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            Text("•")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(commit.authorDateDisplay)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    private var commitHashView: some View {
        Text(commit.hash.prefix(7))
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.vertical, 3)
            .padding(.horizontal, 6)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var rowBackground: Color {
        isSelected ? Color.accentColor.opacity(0.15) : Color.clear
    }
}

// MARK: - Helper Components (can be in a separate file if used elsewhere)

 struct AuthorAvatarView: View {
    let avatarURLString: String

    var body: some View {
        AsyncImage(url: URL(string: avatarURLString)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.secondary)
        }
        .frame(width: 20, height: 20)
        .clipShape(Circle())
    }
}

// Ensure Commit, CommitType, CommitIcon are defined and imported correctly.
// Commit should have properties like `title`, `author`, `authorAvatar`, `authorDateDisplay`, `hash` (or `shortHash`), `commitType`.
// CommitType should have `commitIcon` (which in turn has `name` and `color`).
