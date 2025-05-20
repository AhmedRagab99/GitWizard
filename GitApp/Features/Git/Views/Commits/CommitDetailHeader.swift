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
            // Top bar with commit type and actions
            HStack(spacing: 12) {
                // Commit type badge
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
                }
            }

            // Extended commit message/description if available
            if !commit.body.isEmpty {

                
                    VStack(alignment: .leading) {
                        Divider()
                        Text(commit.body)
                            .font(.callout)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                    }                    
            }
        }
        .toast(toastManager: toastManager)
        
    }
}
