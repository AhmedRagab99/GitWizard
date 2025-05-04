//
//  CommitDetailView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import Foundation

struct CommitDetailView: View {
    let commit: Commit
    let details: CommitDetails?
    @State private var expandedFile: FileDiff?
    @State private var isLoading = true
    @Bindable var viewModel: GitViewModel
    @State private var detailHeight: CGFloat = 400 // Default height
    var onClose: () -> Void // Add closure for handling close action

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else {
                contentView
            }
        }
        .frame(height: detailHeight)
        .background(ModernUI.colors.background)
        .animation(.easeOut(duration: 0.2), value: detailHeight)
        .onAppear {
            withAnimation(ModernUI.animation.delay(0.3)) {
                isLoading = false
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: ModernUI.spacing) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Loading commit details...")
                .foregroundColor(ModernUI.colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ModernUI.colors.background)
    }

    private var contentView: some View {
        VStack(spacing: 0) {
            // Header Section with Commit Info and Close Button
            HStack {
                CommitDetailHeader(
                    commit: commit,
                    refs: commit.branches ?? [],
                    viewModel: viewModel
                )

                Spacer()

                // Close Button
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ModernUI.colors.secondaryText)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
                .padding(.trailing, ModernUI.padding)
            }
            .padding(ModernUI.padding)
            .background(ModernUI.colors.background)
            .modernShadow(.small)

            // Divider
            Divider()
                .background(ModernUI.colors.border)

            // Changes Section
            if let details = details {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ModernUI.spacing) {
                        ForEach(details.diff.fileDiffs) { file in
                            FileChangeSection(
                                fileDiff: file,
                                viewModel: viewModel
                            )
                        }
                    }
                    .padding(ModernUI.padding)
                }
            }
        }
    }
}


