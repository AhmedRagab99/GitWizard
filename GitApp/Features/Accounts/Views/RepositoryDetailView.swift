import SwiftUI

struct RepositoryDetailView: View {
    let repository: GitHubRepository
    let account: Account // Added to provide context for PRs

    // Instantiate GitProviderService here or receive from environment/initializer if it has complex dependencies
    private let gitProviderService = GitProviderService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(repository.fullName)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if let description = repository.description, !description.isEmpty {
                    Text(description)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                HStack {
                    if let lang = repository.language {
                        Label(lang, systemImage: "circle.fill")
                            .foregroundColor(languageColor(lang))
                    }
                    Label("\(repository.stargazersCount ?? 0)", systemImage: "star.fill")
                    Label("\(repository.forksCount ?? 0)", systemImage: "arrow.triangle.branch")
                    Label("\(repository.openIssuesCount ?? 0) open issues", systemImage: "exclamationmark.circle.fill")
                }
                .font(.headline)
                .foregroundColor(.gray)

                Divider()

                // Section for Pull Requests Link
                Section {
                    NavigationLink {
                        // Lazily create the ViewModel and View for Pull Requests
                        let prViewModel = PullRequestViewModel(
                            gitProviderService: gitProviderService,
                            account: account,
                            repository: repository
                        )
                        PullRequestsListView(viewModel: prViewModel)
                    } label: {
                        Label("View Pull Requests", systemImage: "arrow.triangle.pull")
                    }
                    .font(.headline)
                }

                Divider()

                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Text("Owner:").fontWeight(.semibold)
                        Text(repository.owner?.login ?? "N/A")
                    }
                    GridRow {
                        Text("Visibility:").fontWeight(.semibold)
                        Text(repository.isPrivate ? "Private" : "Public")
                    }
                    if let branch = repository.defaultBranch {
                        GridRow {
                            Text("Default Branch:").fontWeight(.semibold)
                            Text(branch)
                        }
                    }
                    if let SshUrl = repository.sshUrl {
                                          GridRow {
                                              Text("SSH URL:").fontWeight(.semibold)
                                              Text(SshUrl)
                                                  .truncationMode(.middle)
                                                  .lineLimit(1)
                                                  .onTapGesture {
                                                      NSPasteboard.general.clearContents()
                                                      NSPasteboard.general.setString(SshUrl, forType: .string)
                                                  }
                                                  .help("Click to copy SSH URL")
                                          }
                                      }
                    if let cloneURL = repository.cloneUrl {
                        GridRow {
                            Text("HTTPS URL:").fontWeight(.semibold)
                            Text(cloneURL)
                                .truncationMode(.middle)
                                .lineLimit(1)
                                .onTapGesture {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(cloneURL, forType: .string)
                                }
                                .help("Click to copy HTTPS URL")
                        }
                    }
                     if let url = URL(string:  repository.htmlUrl) {
                        GridRow {
                            Text("View on GitHub:").fontWeight(.semibold)
                            Link(destination: url) {
                                Text(url.absoluteString)
                                    .truncationMode(.middle)
                                    .lineLimit(1)
                            }
                        }
                    }
                    if let license = repository.license {
                        GridRow {
                            Text("License:").fontWeight(.semibold)
                            Text(license.name)
                        }
                    }
                }
                .font(.body)

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(repository.name)
    }

    private func languageColor(_ language: String) -> Color {
        switch language.lowercased() {
        case "swift": return .orange
        case "javascript": return .yellow
        case "python": return .blue
        case "java": return .red
        case "html": return .pink
        case "css": return .purple
        default: return .gray
        }
    }
}

// Previews would need to be updated to pass an Account
#if DEBUG
//struct RepositoryDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        // Mock GitHubUser for repository owner
//        let mockOwner = GitHubUser(login: "octocat", id: 1, nodeId: "MDQ6VXNlcjU4MzIzMQ==", avatarUrl: "https://avatars.githubusercontent.com/u/583231?v=4", name: "The Octocat", email: nil, company: "GitHub", location: "San Francisco", bio: nil, publicRepos: 8, followers: 3900, following: 9, createdAt: Date(), updatedAt: Date())
//
//        // Mock GitHubRepository
//        let sampleRepo = GitHubRepository(
//            id: 1296269,
//            nodeId: "MDEwOlJlcG9zaXRvcnkxMjk2MjY5",
//            name: "Hello-World",
//            fullName: "octocat/Hello-World",
//            isPrivate: false,
//            owner: mockOwner,
//            htmlUrl: "https://github.com/octocat/Hello-World",
//            description: "My first repository on GitHub!",
//            fork: false,
//            url: "https://api.github.com/repos/octocat/Hello-World",
//            createdAt: Date(),
//            updatedAt: Date(),
//            pushedAt: Date(),
//            homepage: "https://github.com",
//            language: "Swift",
//            forksCount: 2000,
//            stargazersCount: 10000,
//            watchersCount: 10000,
//            openIssuesCount: 100,
//            defaultBranch: "main",
//            license: GitHubRepository.License(key: "mit", name: "MIT License", spdxId: "MIT", url: "https://api.github.com/licenses/mit", nodeId: "MDc6TGljZW5zZTEz"),
//            sshUrl: "git@github.com:octocat/Hello-World.git",
//            cloneUrl: "https://github.com/octocat/Hello-World.git"
//        )
//
//        // Mock PullRequestAuthor for Account
//        let mockAccountUser = PullRequestAuthor(id: 1, login: "currentUser", avatarUrl: nil, htmlUrl: nil)
//        // Mock Account
//        let sampleAccount = Account(id: UUID(), provider: "GitHub", username: "currentUser", token: "faketoken", avatarUrl: nil, user: mockAccountUser, organizations: [])
//
//        NavigationView {
//            RepositoryDetailView(repository: sampleRepo, account: sampleAccount)
//        }
//    }
//}
#endif

