//
//  CommitDetailHeader.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import Foundation

struct CommitDetailHeader: View {
    let commit: Commit
    let refs: [String]
    @Bindable var viewModel: GitViewModel
    let onClose: () -> Void
    @StateObject private var toastManager = ToastManager()
    @State private var isDescriptionExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            topBar
            commitTitle
            authorInfo
            if !refs.isEmpty {
                referencesView
            }
            if !commit.body.isEmpty {
                commitBodyView
            }
        }
        .toast(toastManager: toastManager)
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack(spacing: 12) {
            commitTypeBadge
            Spacer()
            actionButtons
        }
    }

    private var commitTypeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: commit.commitType.commitIcon.name)
                .foregroundColor(.white)
            Text(commit.isMergeCommit ? "Merge" : commit.commitType.rawValue.capitalized)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(commit.commitType.commitIcon.color)
        .clipShape(Capsule())
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            HeaderActionButton(title: "Copy", systemImage: "doc.on.clipboard") {
                viewModel.copyCommitHash(commit.hash)
                toastManager.show(message: "Commit hash copied", type: .success)
            }
            HeaderActionButton(title: "Close", systemImage: "xmark.circle.fill", action: onClose)
        }
    }

    private var commitTitle: some View {
        Text(commit.title)
            .font(.title3)
            .fontWeight(.semibold)
            .lineLimit(2)
    }

    private var authorInfo: some View {
        HStack(alignment: .center, spacing: 8) {
            AvatarView(avatarURL: commit.authorAvatar)
            Text(commit.author)
                .font(.subheadline.weight(.medium))
            Text("•")
                .foregroundColor(.secondary)
            Text(commit.authorDateRelative)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            shortHashButton
        }
    }

    private var shortHashButton: some View {
        Button {
            viewModel.copyCommitHash(commit.hash)
            toastManager.show(message: "Hash copied!", type: .success)
        } label: {
            Text(commit.shortHash)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private var referencesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(refs, id: \.self) { ref in
                    ReferenceCapsule(ref: ref)
                }
            }
        }
    }

    private var commitBodyView: some View {
        VStack(alignment: .leading) {
            Divider()
            Text(commit.body)
                .font(.callout)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Helper Components

private struct HeaderActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.bold())
                .foregroundColor(.primary.opacity(0.7))
        }
        .buttonStyle(.plain)
    }
}

private struct AvatarView: View {
    let avatarURL: String

    var body: some View {
        AsyncImage(url: URL(string: avatarURL)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Image(systemName: "person.fill")
                .foregroundColor(.white)
                .padding(4)
                .background(Color.secondary)
        }
        .frame(width: 28, height: 28)
        .clipShape(Circle())
    }
}

private struct ReferenceCapsule: View {
    let ref: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "tag.fill")
                .font(.caption2)
            Text(ref)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.15))
        .foregroundColor(Color.accentColor)
        .clipShape(Capsule())
    }
}

// Ensure that Commit, CommitType, CommitIcon, and ToastManager types are correctly defined and imported.
// For example:
// import struct Namespace.Commit // or ensure Commit is in scope
// Similarly for other custom types.
