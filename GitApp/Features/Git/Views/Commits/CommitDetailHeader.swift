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
                    .buttonStyle(ModernButtonStyle(style: .ghost))
                }

                Spacer()

                HStack(spacing: ModernUI.spacing) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(ModernButtonStyle(style: .ghost))

                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(ModernButtonStyle(style: .ghost))

                    Menu {
                        Button("Changeset", action: {})
                        Button("Tree", action: {})
                    } label: {
                        HStack {
                            Text("Changeset")
                            Image(systemName: "chevron.down")
                        }
                    }
                    .buttonStyle(ModernButtonStyle(style: .secondary))
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
        }
        .padding(ModernUI.padding)
        .background(ModernUI.colors.background)
    }
}
