//
//  CommitDetailHeader.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI

struct CommitDetailHeader: View {
    let commit: Commit
    let refs: [String]
    @State private var isExpanded = false
    @State private var showingCheckoutAlert = false
    @ObservedObject var viewModel: GitViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: ModernUI.spacing) {
            // Top bar with hash and actions
            HStack(spacing: ModernUI.spacing) {
                HStack(spacing: 4) {
                    Text(commit.hash.prefix(7))
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(ModernUI.colors.secondaryText)

                    Button {
                        // Copy hash action
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.modern(.primary, size: .small))
                }

                Spacer()

                HStack(spacing: ModernUI.spacing) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.modern(.primary, size: .small))

                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.modern(.primary, size: .small))

                    Menu {
                        Button("Changeset", action: {})
                        Button("Tree", action: {})
                    } label: {
                        HStack {
                            Text("Changeset")
                            Image(systemName: "chevron.down")
                        }
                    }
                    .buttonStyle(.modern(.secondary, size: .small))
                }
            }

            Divider()
                .background(ModernUI.colors.border)

            // Author info with animation
            VStack(alignment: .leading, spacing: ModernUI.spacing) {
                HStack(spacing: ModernUI.spacing) {
                    AsyncImage(url: URL(string: commit.authorAvatar)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(ModernUI.colors.secondaryText)
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .modernShadow(.small)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(commit.authorName)
                            .font(.headline)
                        Text(commit.authorEmail)
                            .font(.subheadline)
                            .foregroundColor(ModernUI.colors.secondaryText)
                    }
                }

                // Date with icon
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(ModernUI.colors.secondaryText)
                    Text(commit.date.formatted(.dateTime
                        .day().month(.wide).year()
                        .hour().minute()
                        .timeZone()))
                        .foregroundColor(ModernUI.colors.secondaryText)
                }

                // Refs with modern badges
                if !refs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(refs, id: \.self) { ref in
                                RefBadge(name: ref)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(ModernUI.padding)
            .background(ModernUI.colors.secondaryBackground)
            .cornerRadius(ModernUI.cornerRadius)

            HStack {
                Text(commit.message)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)

                Spacer()

                Button(action: { showingCheckoutAlert = true }) {
                    Label("Checkout", systemImage: "arrow.triangle.branch")
                }
                .buttonStyle(.modern(.secondary, size: .small))
            }

            HStack {
                Text(commit.authorName)
                    .foregroundStyle(.secondary)
                Text("•")
                    .foregroundStyle(.secondary)
                Text(commit.date.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .padding(ModernUI.padding)
        .background(ModernUI.colors.background)
        .alert("Checkout Commit", isPresented: $showingCheckoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Checkout") {
                Task {
                    await viewModel.checkoutCommit(commit.hash)
                }
            }
        } message: {
            Text("This will detach your HEAD. Are you sure you want to checkout this commit?")
        }
    }
}
