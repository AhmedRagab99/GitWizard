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

    private var commitIcon: String {
        switch commit.commitType {
        case .merge: return "arrow.triangle.branch"
        case .rebase: return "arrow.triangle.2.circlepath"
        case .cherryPick: return "arrow.up.forward.circle"
        case .revert: return "arrow.uturn.backward.circle"
        case .normal: return "checkmark.circle.fill"
        }
    }

    private var commitColor: Color {
        switch commit.commitType {
        case .merge: return .purple
        case .rebase: return .orange
        case .cherryPick: return .blue
        case .revert: return .red
        case .normal: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Commit hash and type
            HStack {
                Image(systemName: commitIcon)
                    .foregroundColor(commitColor)
                    .font(.title2)

                Text(commit.hash.prefix(7))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)

                Spacer()

                // Action buttons
                HStack(spacing: 8) {
                    Button(action: {
                        viewModel.copyCommitHash(commit.hash)
                    }) {
                        Label("Copy Hash", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        viewModel.checkoutCommit(commit)
                    }) {
                        Label("Checkout", systemImage: "arrow.triangle.branch")
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Commit message
            VStack(alignment: .leading, spacing: 8) {
                Text(commit.title)
                    .font(.title2)
                    .fontWeight(.bold)

                if !commit.body.isEmpty {
                    Text(commit.body)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }

            // Author info
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
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(commit.author)
                        .font(.headline)
                    Text(commit.authorEmail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(commit.authorDateDisplay)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Refs (branches and tags)
            if !refs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(refs, id: \.self) { ref in
                            Text(ref)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundColor(.accentColor)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
    }
}
