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
    @ObservedObject var viewModel: GitViewModel
    @State private var detailHeight: CGFloat = 300 // Default height
    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            DragHandle(height: $detailHeight, isDragging: $isDragging)

            if isLoading {
                VStack(spacing: ModernUI.spacing) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Loading commit details...")
                        .foregroundColor(ModernUI.colors.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ModernUI.colors.background)
            } else {
                VStack(spacing: 0) {
                    // Header Section with Commit Info
                    CommitDetailHeader(
                        commit: commit,
                        refs: commit.branches ?? [],
                        viewModel: viewModel
                    )
                    .padding(ModernUI.padding)
                    .background(ModernUI.colors.background)
                    .modernShadow(.small)

                    // Divider
                    Divider()
                        .background(ModernUI.colors.border)

                    // Changes Section
                    ScrollView {
                        if let details = details {
                            VStack(alignment: .leading, spacing: ModernUI.spacing) {
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
        .frame(height: detailHeight)
        .background(ModernUI.colors.background)
        .animation(isDragging ? nil : .easeOut(duration: 0.2), value: detailHeight)
        .animation(.easeOut(duration: 0.1), value: isDragging)
        .onAppear {
            withAnimation(ModernUI.animation.delay(0.3)) {
                isLoading = false
            }
        }
    }
}

struct DragHandle: View {
    @Binding var height: CGFloat
    @Binding var isDragging: Bool

    var body: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(ModernUI.colors.border)
                .frame(width: 36, height: 4)
                .cornerRadius(2)
        }
        .frame(height: 20)
        .frame(maxWidth: .infinity)
        .background(isDragging ? ModernUI.colors.secondaryBackground : Color.clear)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    let newHeight = height - value.translation.height
                    // Clamp the height between min and max values
                    height = max(150, min(newHeight, NSScreen.main?.frame.height ?? 800 * 0.8))
                }
                .onEnded { _ in
                    isDragging = false
                    // Snap to common heights if close
                    let snapPoints: [CGFloat] = [200, 300, 400, 500]
                    if let snapHeight = snapPoints.min(by: { abs($0 - height) < abs($1 - height) }),
                       abs(snapHeight - height) < 30 {
                        withAnimation(.easeOut(duration: 0.2)) {
                            height = snapHeight
                        }
                    }
                }
        )
    }
}
