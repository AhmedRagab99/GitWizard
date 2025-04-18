//
//  CommitDetailView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI

struct CommitDetailView: View {
    let commit: Commit
    let details: GitViewModel.CommitDetails?
    @State private var expandedFile: FileChange?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ModernUI.spacing, pinnedViews: [.sectionHeaders]) {
                        CommitDetailHeader(
                            commit: commit,
                            refs: details?.branchNames ?? []
                        )

                        // Commit message
                        Text(commit.message)
                            .font(.system(.body))
                            .padding(ModernUI.padding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ModernUI.colors.background)
                            .cornerRadius(ModernUI.cornerRadius)
                            .modernShadow(.small)

                        if let details = details {
                            // Changed files section
                            Section {
                                ForEach(details.changedFiles) { file in
                                    FileChangeSection(
                                        fileChange: file,
                                        diffContent: details.diffContent,
                                        expandedFile: $expandedFile
                                    )
                                }
                            } header: {
                                HStack {
                                    Text("Changed Files")
                                        .font(.headline)
                                    Text("(\(details.changedFiles.count))")
                                        .foregroundColor(ModernUI.colors.secondaryText)
                                    Spacer()
                                }
                                .padding(ModernUI.padding)
                                .background(ModernUI.colors.background)
                            }
                        }
                    }
                    .padding(ModernUI.padding)
                }
            }
        }
        .background(ModernUI.colors.background)
        .onAppear {
            withAnimation(ModernUI.animation.delay(0.3)) {
                isLoading = false
            }
        }
    }
}
