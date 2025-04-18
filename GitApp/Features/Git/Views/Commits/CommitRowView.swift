//
//  CommitRowView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//


import SwiftUI
struct CommitRowView: View {
    let commit: Commit
    let previousCommit: Commit?
    let nextCommit: Commit?
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            // Graph visualization
            CommitGraphVisualization(
                commit: commit,
                previousCommit: previousCommit,
                nextCommit: nextCommit
            )
            .frame(width: 50)

            // Author image
            AsyncImage(url: URL(string: commit.authorAvatar)) { image in
                image
                    .resizable()
                    .clipShape(Circle())
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.secondary)
            }
            .frame(width: 24, height: 24)

            // Commit info
            VStack(alignment: .leading, spacing: 4) {
                // First line: commit message and tags
                HStack(spacing: 8) {
                    Text(commit.message)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)

                    // Tags and branch indicators
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            if commit.branchNames.contains("HEAD") {
                                BranchTagView(name: "HEAD", type: .head)
                            }
                            if commit.branchNames.contains("production") {
                                BranchTagView(name: "production", type: .production)
                            }
                            ForEach(commit.branchNames.filter { $0 != "HEAD" && $0 != "production" }, id: \.self) { branch in
                                BranchTagView(name: branch, type: .branch)
                            }
                        }
                    }
                }

                // Second line: metadata
                HStack(spacing: 16) {
                    Text(commit.hash.prefix(8))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)

                    Text(commit.authorName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text(commit.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(isHovered ? Color(.windowBackgroundColor).opacity(0.5) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
