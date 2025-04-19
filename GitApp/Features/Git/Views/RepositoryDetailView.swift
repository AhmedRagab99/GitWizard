import SwiftUI

struct RepositoryDetailView: View {
    @ObservedObject var viewModel: GitViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    let repositoryURL: URL

    private var recentCommits: [Commit] {
        Array(viewModel.branchCommits.prefix(5))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Text(repositoryURL.lastPathComponent)
                    .font(.title)
                    .fontWeight(.bold)
                    .themedText()

                Text(repositoryURL.path)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .themedText()
            }
            .padding()
            .themedCard()

            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // Branches
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Branches")
                            .font(.headline)
                            .themedText()

                        ForEach(viewModel.branches) { branch in
                            HStack {
                                Image(systemName: "arrow.branch")
                                    .foregroundStyle(themeManager.currentTheme.primaryColor)
                                Text(branch.name)
                                    .themedText()
                                if branch.isCurrent {
                                    Text("(current)")
                                        .font(.caption)
                                        .foregroundStyle(themeManager.currentTheme.accentColor)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .themedCard()

                    // Recent Commits
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Commits")
                            .font(.headline)
                            .themedText()

                        ForEach(recentCommits,id: \.self) { commit in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(commit.message)
                                    .font(.subheadline)
                                    .themedText()
                                Text(commit.authorName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .themedText()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .themedCard()
                }
                .padding()
            }
        }
        .themedBackground()
        .onAppear {
            Task {
                await viewModel.loadRepositoryData(from: repositoryURL)
            }
        }
    }
}

#Preview {
    RepositoryDetailView(
        viewModel: GitViewModel(),
        repositoryURL: URL(fileURLWithPath: "/path/to/repo")
    )
    .environmentObject(ThemeManager.shared)
}
