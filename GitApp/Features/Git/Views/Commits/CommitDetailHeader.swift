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
        Card(
            backgroundColor: Color(.windowBackgroundColor),
            cornerRadius: 0,
            shadowRadius: 1,
            padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Top bar with commit type and actions
                HStack(spacing: 12) {
                    // Commit type badge
                    TagView(
                        text: commit.isMergeCommit ? "Merge" : commit.commitType.rawValue.capitalized,
                        color: commit.commitType.commitIcon.color,
                        systemImage: commit.commitType.commitIcon.name
                    )

                    Spacer()

                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            viewModel.copyCommitHash(commit.hash)
                            toastManager.show(message: "Commit hash copied", type: .success)
                        }) {
                            Label("Copy", systemImage: "doc.on.clipboard")
                                .font(.caption.bold())
                                .foregroundColor(.primary.opacity(0.7))
                        }
                        .buttonStyle(.plain)

                        Button(action: onClose) {
                            Label("Close", systemImage: "xmark.circle.fill")
                                .font(.caption.bold())
                                .foregroundColor(.primary.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Commit title
                Text(commit.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                // Author info and date
                HStack(alignment: .center, spacing: 8) {
                    if let avatarURL = URL(string: commit.authorAvatar) {
                        AsyncImage(url: avatarURL) { image in
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

                    Text(commit.author)
                        .font(.subheadline.weight(.medium))

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(commit.authorDateRelative)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Shortened hash with copy button
                    Button {
                        viewModel.copyCommitHash(commit.hash)
                        toastManager.show(message: "Hash copied!", type: .success)
                    } label: {
                        Text(commit.shortHash)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                // References (branches, tags) - horizontal scrolling
                if !refs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(refs, id: \.self) { ref in
                                RefBadge(name: ref)
                            }
                        }
                    }
                }

                // Extended commit message/description if available
                if !commit.body.isEmpty {
                    FormSection(title: "Description") {
                        Text(commit.body)
                            .font(.callout)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .toast(toastManager: toastManager)
    }
}
