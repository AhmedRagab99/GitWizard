import SwiftUI

struct RepositoryDetailView: View {
    let repository: GitHubRepository
    // Future: Add viewModel for more complex interactions if needed, e.g., fetching branches, commits for this repo.

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
                                                      // Add toast feedback if available
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
                                    // Add toast feedback
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

    // Helper from AccountsListView, could be moved to a shared utility
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

